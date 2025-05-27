// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:isolate';

import 'package:quanta_db/src/common/change_types.dart';
import 'package:quanta_db/src/storage/lsm_storage.dart' as lsm;
import 'package:quanta_db/src/utils/xxhash.dart';

class Query<T> {
  Query({
    this.predicates = const [],
    this.sorts = const [],
    this.limit,
    this.offset,
    this.aggregations = const [],
  }) {
    _validateQuery();
  }
  final List<QueryPredicate<T>> predicates;
  final List<QuerySort<T>> sorts;
  final int? limit;
  final int? offset;
  final List<QueryAggregation<T>> aggregations;

  void _validateQuery() {
    if (limit != null && limit! < 0) {
      throw ArgumentError('Limit must be non-negative');
    }
    if (offset != null && offset! < 0) {
      throw ArgumentError('Offset must be non-negative');
    }
    if (limit != null && offset != null && limit! + offset! < 0) {
      throw ArgumentError('Limit + offset must be non-negative');
    }
  }

  Query<T> where(QueryPredicate<T> predicate) {
    return Query(
      predicates: [...predicates, predicate],
      sorts: sorts,
      limit: limit,
      offset: offset,
      aggregations: aggregations,
    );
  }

  Query<T> sortBy(QuerySort<T> sort) {
    return Query(
      predicates: predicates,
      sorts: [...sorts, sort],
      limit: limit,
      offset: offset,
      aggregations: aggregations,
    );
  }

  Query<T> take(int count) {
    return Query(
      predicates: predicates,
      sorts: sorts,
      limit: count,
      offset: offset,
      aggregations: aggregations,
    );
  }

  Query<T> skip(int count) {
    return Query(
      predicates: predicates,
      sorts: sorts,
      limit: limit,
      offset: count,
      aggregations: aggregations,
    );
  }

  Query<T> aggregate(QueryAggregation<T> aggregation) {
    return Query(
      predicates: predicates,
      sorts: sorts,
      limit: limit,
      offset: offset,
      aggregations: [...aggregations, aggregation],
    );
  }
}

typedef QueryPredicate<T> = bool Function(T item);
typedef QuerySort<T> = Comparable Function(T item);
typedef QueryAggregation<T> = dynamic Function(Iterable<T> items);

class QueryEngine {
  QueryEngine(this._storage) {
    _storage.onChange.listen((event) => _handleStorageChange(event));
    _startChangePropagationWorker();
  }
  final lsm.LSMStorage _storage;
  final _changeController = StreamController<ChangeEvent>.broadcast();
  final _objectHashes = <String, int>{};
  final _batchUpdates = <ChangeEvent>[];
  Timer? _batchTimer;
  Isolate? _worker;
  SendPort? _sendPort;
  ReceivePort? _handshakePort;
  ReceivePort? _messagePort;
  StreamSubscription? _storageSubscription;

  /// Get the storage instance
  lsm.LSMStorage get storage => _storage;

  /// Execute a query and return the results
  Future<List<T>> query<T>(Query<T> query) async {
    query._validateQuery();
    final results = <T>[];

    // Get all items of type T from storage
    final items = await _storage.getAll<T>();

    // Apply predicates
    for (final item in items) {
      if (_applyPredicates(item, query.predicates)) {
        results.add(item);
      }
    }

    // Apply sorting
    if (query.sorts.isNotEmpty) {
      results.sort((a, b) {
        for (final sort in query.sorts) {
          final aValue = sort(a);
          final bValue = sort(b);
          final comparison = aValue.compareTo(bValue);
          if (comparison != 0) return comparison;
        }
        return 0;
      });
    }

    // Apply pagination
    if (query.offset != null) {
      results.removeRange(0, query.offset!);
    }
    if (query.limit != null) {
      results.removeRange(query.limit!, results.length);
    }

    return results;
  }

  /// Watch for changes matching a query
  Stream<R> watch<T, R>(Query<T> query) {
    query._validateQuery();
    final stream = _changeController.stream
        .where((event) => event.type == T)
        .map((event) => event.value as T)
        .where((item) => _applyPredicates(item, query.predicates))
        .transform(_createSortTransformer(query.sorts))
        .transform(_createPaginationTransformer(query.limit, query.offset));

    if (query.aggregations.isNotEmpty) {
      // For aggregations, collect items into a list
      return stream
          .transform(StreamTransformer<T, List<T>>.fromHandlers(
            handleData: (data, sink) {
              sink.add([data]);
            },
          ))
          .transform(_createAggregationTransformer<T>(query.aggregations))
          .cast<R>();
    }

    // For non-aggregation queries, return a stream of single items
    return stream.cast<R>();
  }

  bool _applyPredicates<T>(T item, List<QueryPredicate<T>> predicates) {
    return predicates.every((predicate) => predicate(item));
  }

  StreamTransformer<T, T> _createSortTransformer<T>(List<QuerySort<T>> sorts) {
    return StreamTransformer.fromHandlers(
      handleData: (data, sink) {
        if (sorts.isEmpty) {
          sink.add(data);
          return;
        }

        final sorted = List<T>.from([data]);
        sorted.sort((a, b) {
          for (final sort in sorts) {
            final aValue = sort(a);
            final bValue = sort(b);
            final comparison = aValue.compareTo(bValue);
            if (comparison != 0) return comparison;
          }
          return 0;
        });
        sink.add(sorted.first);
      },
    );
  }

  StreamTransformer<T, T> _createPaginationTransformer<T>(
      int? limit, int? offset) {
    int currentOffset = offset ?? 0;
    int? currentLimit = limit;
    final buffer = <T>[];

    return StreamTransformer.fromHandlers(
      handleData: (data, sink) {
        buffer.add(data);

        // Process buffered items
        while (buffer.isNotEmpty) {
          if (currentOffset > 0) {
            buffer.removeAt(0);
            currentOffset--;
            continue;
          }

          if (currentLimit != null && currentLimit! <= 0) {
            buffer.clear();
            return;
          }

          final item = buffer.removeAt(0);
          sink.add(item);

          if (currentLimit != null) {
            currentLimit = currentLimit! - 1;
          }
        }
      },
    );
  }

  StreamTransformer<List<T>, dynamic> _createAggregationTransformer<T>(
      List<QueryAggregation<T>> aggregations) {
    if (aggregations.isEmpty) {
      return StreamTransformer.fromHandlers(
        handleData: (data, sink) => sink.add(data),
      );
    }

    final buffer = <T>[];
    return StreamTransformer<List<T>, dynamic>.fromHandlers(
      handleData: (data, sink) {
        buffer.addAll(data);
        final result = aggregations.first(buffer);
        sink.add(result);
      },
    );
  }

  /// Start the change propagation worker isolate
  Future<void> _startChangePropagationWorker() async {
    _handshakePort = ReceivePort();
    _messagePort = ReceivePort();

    _worker = await Isolate.spawn(
      _changePropagationWorker,
      [_handshakePort!.sendPort, _messagePort!.sendPort],
    );

    _sendPort = await _handshakePort!.first as SendPort;
    _handshakePort!.close();
    _handshakePort = null;

    _messagePort!.listen(_handleWorkerMessage);
  }

  /// Handle messages from the worker isolate
  void _handleWorkerMessage(dynamic message) {
    if (message is ChangeEvent) {
      _changeController.add(message);
    } else if (message is List<ChangeEvent>) {
      for (final event in message) {
        _changeController.add(event);
      }
    }
  }

  void _handleStorageChange(ChangeEvent event) {
    if (event.type == dynamic) {
      _changeController.add(event);
      return;
    }

    final key = event.key;
    final value = event.value;

    // Calculate hash of the new value
    final newHash =
        value != null ? XXHash.hash64(value.toString().codeUnits) : 0;

    // Check if the value has actually changed
    if (_objectHashes[key] == newHash) {
      return;
    }

    _objectHashes[key] = newHash;
    _batchUpdates.add(event);

    // Schedule batch update
    _batchTimer?.cancel();
    _batchTimer = Timer(const Duration(milliseconds: 16), () {
      if (_batchUpdates.isNotEmpty) {
        final batchEvent = ChangeEvent(
          key: 'batch',
          value: _batchUpdates,
          type: List<ChangeEvent>,
          changeType: ChangeType.batch,
        );
        _changeController.add(batchEvent);
        _sendPort?.send(_batchUpdates);
        _batchUpdates.clear();
      }
    });
  }

  Future<void> dispose() async {
    _batchTimer?.cancel();
    _worker?.kill();
    _handshakePort?.close();
    _messagePort?.close();
    await _storageSubscription?.cancel();
    await _changeController.close();
    _sendPort = null;
    _handshakePort = null;
    _messagePort = null;
    _storageSubscription = null;
  }
}

/// Worker function that runs in a separate isolate for change propagation
void _changePropagationWorker(List<dynamic> args) {
  final handshakePort = args[0] as SendPort;
  final messagePort = args[1] as SendPort;
  final receivePort = ReceivePort();

  handshakePort.send(receivePort.sendPort);

  receivePort.listen((message) {
    if (message is List<ChangeEvent>) {
      // Process batch of changes
      for (final event in message) {
        messagePort.send(event);
      }
    }
  });
}
