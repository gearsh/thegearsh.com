// Gearsh Local Database Service
// SQLite database for offline-first data storage

import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Local database service for offline storage
class LocalDatabase {
  static LocalDatabase? _instance;
  static Database? _database;

  LocalDatabase._();

  static LocalDatabase get instance {
    _instance ??= LocalDatabase._();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'gearsh_cache.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Artists cache table
    await db.execute('''
      CREATE TABLE artists (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        updated_at INTEGER NOT NULL,
        is_synced INTEGER DEFAULT 1
      )
    ''');

    // Artist search results cache
    await db.execute('''
      CREATE TABLE artist_search_cache (
        cache_key TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        total_count INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        expires_at INTEGER NOT NULL
      )
    ''');

    // Bookings cache table
    await db.execute('''
      CREATE TABLE bookings (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        updated_at INTEGER NOT NULL,
        is_synced INTEGER DEFAULT 1,
        pending_action TEXT
      )
    ''');

    // User favorites cache
    await db.execute('''
      CREATE TABLE favorites (
        artist_id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        added_at INTEGER NOT NULL,
        is_synced INTEGER DEFAULT 1
      )
    ''');

    // Recent searches
    await db.execute('''
      CREATE TABLE recent_searches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        query TEXT NOT NULL,
        filters TEXT,
        searched_at INTEGER NOT NULL
      )
    ''');

    // Sync queue for pending operations
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        action TEXT NOT NULL,
        data TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        retry_count INTEGER DEFAULT 0,
        last_error TEXT
      )
    ''');

    // Cache metadata
    await db.execute('''
      CREATE TABLE cache_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Create indexes for faster queries
    await db.execute('CREATE INDEX idx_artists_updated ON artists(updated_at)');
    await db.execute('CREATE INDEX idx_bookings_synced ON bookings(is_synced)');
    await db.execute('CREATE INDEX idx_sync_queue_type ON sync_queue(entity_type)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add any migration logic here
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cache_metadata (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
    }
  }

  /// Clear all cached data
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('artists');
    await db.delete('artist_search_cache');
    await db.delete('bookings');
    await db.delete('favorites');
    await db.delete('recent_searches');
    await db.delete('cache_metadata');
    // Don't clear sync_queue - those are pending operations
  }

  /// Clear expired cache entries
  Future<void> clearExpiredCache() async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.delete(
      'artist_search_cache',
      where: 'expires_at < ?',
      whereArgs: [now],
    );
  }

  /// Get database size info
  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;
    final stats = <String, int>{};

    final tables = ['artists', 'artist_search_cache', 'bookings', 'favorites', 'sync_queue'];
    for (final table in tables) {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
      stats[table] = Sqflite.firstIntValue(result) ?? 0;
    }

    return stats;
  }

  /// Close the database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}

/// Cache entry wrapper with metadata
class CacheEntry<T> {
  final T data;
  final DateTime updatedAt;
  final DateTime? expiresAt;
  final bool isSynced;

  CacheEntry({
    required this.data,
    required this.updatedAt,
    this.expiresAt,
    this.isSynced = true,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get isStale {
    // Consider data stale after 5 minutes
    return DateTime.now().difference(updatedAt).inMinutes > 5;
  }
}

/// Sync queue item for pending operations
class SyncQueueItem {
  final int id;
  final String entityType;
  final String entityId;
  final String action; // 'create', 'update', 'delete'
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int retryCount;
  final String? lastError;

  SyncQueueItem({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
    this.lastError,
  });

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'] as int,
      entityType: map['entity_type'] as String,
      entityId: map['entity_id'] as String,
      action: map['action'] as String,
      data: jsonDecode(map['data'] as String) as Map<String, dynamic>,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      retryCount: map['retry_count'] as int? ?? 0,
      lastError: map['last_error'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'entity_type': entityType,
      'entity_id': entityId,
      'action': action,
      'data': jsonEncode(data),
      'created_at': createdAt.millisecondsSinceEpoch,
      'retry_count': retryCount,
      'last_error': lastError,
    };
  }
}


