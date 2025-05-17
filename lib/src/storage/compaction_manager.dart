import 'dart:async';
import 'dart:isolate';

import 'package:quanta_db/src/storage/sstable.dart';
import 'package:quanta_db/src/storage/memtable.dart';

/// Manages background compaction of SSTables
class CompactionManager {
  CompactionManager(this._dataDir) {
    _startCompactionWorker();
  }

  final String _dataDir;
  Isolate? _worker;
  SendPort? _sendPort;
  ReceivePort? _handshakePort;
  ReceivePort? _messagePort;
  final _compactionQueue = <CompactionTask>[];
  bool _isCompacting = false;

  /// Schedule a compaction task
  void scheduleCompaction(List<SSTable> tables, int targetLevel) {
    _compactionQueue.add(CompactionTask(tables, targetLevel));
    _triggerCompaction();
  }

  /// Start the compaction worker isolate
  Future<void> _startCompactionWorker() async {
    _handshakePort = ReceivePort();
    _messagePort = ReceivePort();

    _worker = await Isolate.spawn(
      _compactionWorker,
      [_handshakePort!.sendPort, _messagePort!.sendPort, _dataDir],
    );

    _sendPort = await _handshakePort!.first as SendPort;
    _handshakePort!.close();
    _handshakePort = null;

    _messagePort!.listen(_handleCompactionResult);
  }

  /// Trigger compaction if not already running
  void _triggerCompaction() {
    if (_isCompacting || _compactionQueue.isEmpty) return;
    _isCompacting = true;

    final task = _compactionQueue.removeAt(0);
    _sendPort?.send(task);
  }

  /// Handle compaction results from the worker
  void _handleCompactionResult(dynamic message) {
    if (message is CompactionResult) {
      // Delete old tables and add new one
      for (final table in message.deletedTables) {
        table.delete();
      }
      _isCompacting = false;
      _triggerCompaction();
    }
  }

  /// Clean up resources
  Future<void> dispose() async {
    _worker?.kill();
    _handshakePort?.close();
    _messagePort?.close();
    _handshakePort = null;
    _messagePort = null;
    _sendPort = null;
  }
}

/// A task to compact a set of SSTables into a new level
class CompactionTask {
  CompactionTask(this.tables, this.targetLevel);
  final List<SSTable> tables;
  final int targetLevel;
}

/// Result of a compaction operation
class CompactionResult {
  CompactionResult(this.newTable, this.deletedTables);
  final SSTable newTable;
  final List<SSTable> deletedTables;
}

/// Worker function that runs in a separate isolate
void _compactionWorker(List<dynamic> args) {
  final handshakePort = args[0] as SendPort;
  final messagePort = args[1] as SendPort;
  final dataDir = args[2] as String;
  final receivePort = ReceivePort();

  handshakePort.send(receivePort.sendPort);

  receivePort.listen((message) async {
    if (message is CompactionTask) {
      try {
        final result = await _performCompaction(message, dataDir);
        messagePort.send(result);
      } catch (e) {
        messagePort.send(CompactionError(e.toString()));
      }
    }
  });
}

/// Perform the actual compaction of SSTables
Future<CompactionResult> _performCompaction(
    CompactionTask task, String dataDir) async {
  // Merge all entries from source tables
  final entries = <String, dynamic>{};
  for (final table in task.tables) {
    final tableEntries = await table.getAll();
    entries.addAll(tableEntries);
  }

  // Create new SSTable
  final memTable = MemTable();
  for (final entry in entries.entries) {
    memTable.put(entry.key, entry.value);
  }
  final newTable = await SSTable.create(
    memTable,
    task.targetLevel,
    DateTime.now().millisecondsSinceEpoch,
  );

  return CompactionResult(newTable, task.tables);
}

/// Error that occurred during compaction
class CompactionError {
  CompactionError(this.message);
  final String message;
}
