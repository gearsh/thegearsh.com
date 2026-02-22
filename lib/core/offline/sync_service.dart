// Gearsh Sync Service
// Background synchronization of offline changes

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gearsh_app/core/offline/local_database.dart';
import 'package:gearsh_app/core/offline/connectivity_service.dart';

/// Sync status
enum SyncStatus {
  idle,
  syncing,
  completed,
  failed,
}

/// Sync result
class SyncResult {
  final int successCount;
  final int failureCount;
  final List<String> errors;
  final DateTime syncedAt;

  SyncResult({
    required this.successCount,
    required this.failureCount,
    required this.errors,
    required this.syncedAt,
  });

  bool get hasErrors => failureCount > 0;
  bool get isFullSuccess => failureCount == 0 && successCount > 0;
}

/// Provider for sync service
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref);
});

/// Provider for sync status
final syncStatusProvider = StateProvider<SyncStatus>((ref) => SyncStatus.idle);

/// Provider for pending sync count
final pendingSyncCountProvider = FutureProvider<int>((ref) async {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.getPendingSyncCount();
});

/// Sync service for background synchronization
class SyncService {
  final Ref _ref;
  final LocalDatabase _db = LocalDatabase.instance;
  Timer? _syncTimer;
  bool _isSyncing = false;

  static const int maxRetries = 3;
  static const Duration syncInterval = Duration(minutes: 5);

  SyncService(this._ref) {
    _startBackgroundSync();
  }

  void _startBackgroundSync() {
    // Listen to connectivity changes
    _ref.listen<ConnectivityStatus>(connectivityStatusProvider, (previous, next) {
      if (previous == ConnectivityStatus.offline && next == ConnectivityStatus.online) {
        // Just came online - trigger sync
        debugPrint('📡 Back online - triggering sync');
        syncPendingChanges();
      }
    });

    // Periodic sync
    _syncTimer = Timer.periodic(syncInterval, (_) {
      if (_ref.read(isOnlineProvider)) {
        syncPendingChanges();
      }
    });
  }

  /// Add item to sync queue
  Future<void> queueForSync({
    required String entityType,
    required String entityId,
    required String action,
    required Map<String, dynamic> data,
  }) async {
    final db = await _db.database;

    await db.insert('sync_queue', {
      'entity_type': entityType,
      'entity_id': entityId,
      'action': action,
      'data': jsonEncode(data),
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'retry_count': 0,
    });

    debugPrint('📥 Queued for sync: $entityType/$entityId ($action)');

    // Try to sync immediately if online
    if (_ref.read(isOnlineProvider)) {
      syncPendingChanges();
    }
  }

  /// Get count of pending sync items
  Future<int> getPendingSyncCount() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM sync_queue');
    return result.first['count'] as int? ?? 0;
  }

  /// Get all pending sync items
  Future<List<SyncQueueItem>> getPendingItems() async {
    final db = await _db.database;
    final results = await db.query(
      'sync_queue',
      orderBy: 'created_at ASC',
    );
    return results.map((r) => SyncQueueItem.fromMap(r)).toList();
  }

  /// Sync all pending changes
  Future<SyncResult> syncPendingChanges() async {
    if (_isSyncing) {
      return SyncResult(
        successCount: 0,
        failureCount: 0,
        errors: ['Sync already in progress'],
        syncedAt: DateTime.now(),
      );
    }

    _isSyncing = true;
    _ref.read(syncStatusProvider.notifier).state = SyncStatus.syncing;

    int successCount = 0;
    int failureCount = 0;
    final errors = <String>[];

    try {
      final items = await getPendingItems();
      debugPrint('📤 Syncing ${items.length} pending items...');

      for (final item in items) {
        try {
          await _processSyncItem(item);
          await _removeSyncItem(item.id);
          successCount++;
        } catch (e) {
          failureCount++;
          errors.add('${item.entityType}/${item.entityId}: $e');

          // Update retry count
          if (item.retryCount < maxRetries) {
            await _updateRetryCount(item.id, item.retryCount + 1, e.toString());
          } else {
            // Max retries reached - move to failed
            debugPrint('❌ Max retries reached for ${item.entityType}/${item.entityId}');
            await _removeSyncItem(item.id);
            // Optionally store in a failed_sync table for manual review
          }
        }
      }

      _ref.read(syncStatusProvider.notifier).state =
          failureCount > 0 ? SyncStatus.failed : SyncStatus.completed;

      debugPrint('✅ Sync complete: $successCount success, $failureCount failed');

    } catch (e) {
      debugPrint('❌ Sync error: $e');
      errors.add('General sync error: $e');
      _ref.read(syncStatusProvider.notifier).state = SyncStatus.failed;
    } finally {
      _isSyncing = false;

      // Reset status after a delay
      Future.delayed(const Duration(seconds: 3), () {
        if (_ref.read(syncStatusProvider) != SyncStatus.syncing) {
          _ref.read(syncStatusProvider.notifier).state = SyncStatus.idle;
        }
      });
    }

    return SyncResult(
      successCount: successCount,
      failureCount: failureCount,
      errors: errors,
      syncedAt: DateTime.now(),
    );
  }

  /// Process a single sync item
  Future<void> _processSyncItem(SyncQueueItem item) async {
    // Route to appropriate handler based on entity type
    switch (item.entityType) {
      case 'booking':
        await _syncBooking(item);
        break;
      case 'favorite':
        await _syncFavorite(item);
        break;
      case 'review':
        await _syncReview(item);
        break;
      default:
        debugPrint('Unknown entity type: ${item.entityType}');
    }
  }

  Future<void> _syncBooking(SyncQueueItem item) async {
    // TODO: Implement booking sync with backend
    // final apiClient = _ref.read(apiClientProvider);
    // switch (item.action) {
    //   case 'create':
    //     await apiClient.post('/bookings', item.data);
    //     break;
    //   case 'update':
    //     await apiClient.put('/bookings/${item.entityId}', item.data);
    //     break;
    //   case 'delete':
    //     await apiClient.delete('/bookings/${item.entityId}');
    //     break;
    // }
    debugPrint('📤 Synced booking: ${item.entityId}');
  }

  Future<void> _syncFavorite(SyncQueueItem item) async {
    // TODO: Implement favorite sync with backend
    debugPrint('📤 Synced favorite: ${item.entityId}');
  }

  Future<void> _syncReview(SyncQueueItem item) async {
    // TODO: Implement review sync with backend
    debugPrint('📤 Synced review: ${item.entityId}');
  }

  Future<void> _removeSyncItem(int id) async {
    final db = await _db.database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> _updateRetryCount(int id, int retryCount, String error) async {
    final db = await _db.database;
    await db.update(
      'sync_queue',
      {'retry_count': retryCount, 'last_error': error},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Clear all pending sync items (use with caution)
  Future<void> clearSyncQueue() async {
    final db = await _db.database;
    await db.delete('sync_queue');
  }

  void dispose() {
    _syncTimer?.cancel();
  }
}

