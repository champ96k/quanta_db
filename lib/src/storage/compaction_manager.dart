import 'dart:async';

import 'package:quanta_db/src/storage/sstable.dart';
import 'package:quanta_db/src/storage/memtable.dart';

/// Manages background compaction of SSTables
class CompactionManager {
  CompactionManager(this._dataDir) {
    _startCompactionWorker();
  }

  final String _dataDir;
  final _compactionQueue = <CompactionTask>[];
  bool _isCompacting = false;
  Timer? _compactionTimer;

  /// Schedule a compaction task
  void scheduleCompaction(List<SSTable> tables, int targetLevel) {
    _compactionQueue.add(CompactionTask(tables, targetLevel));
    _triggerCompaction();
  }

  /// Start the compaction worker
  void _startCompactionWorker() {
    // No-op for web platform
  }

  /// Trigger compaction if not already running
  void _triggerCompaction() {
    if (_isCompacting || _compactionQueue.isEmpty) return;
    _isCompacting = true;

    final task = _compactionQueue.removeAt(0);
    _performCompaction(task, _dataDir).then((result) {
      // Delete old tables and add new one
      for (final table in result.deletedTables) {
        table.delete();
      }
      _isCompacting = false;
      _triggerCompaction();
    }).catchError((error) {
      _isCompacting = false;
      _triggerCompaction();
    });
  }

  /// Clean up resources
  Future<void> dispose() async {
    _compactionTimer?.cancel();
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
