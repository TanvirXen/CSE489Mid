import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/landmark.dart';

class LandmarkCache {
  LandmarkCache();

  static const _table = 'landmarks';
  Database? _database;
  bool _disabled = kIsWeb;

  Future<Database?> _getDb() async {
    if (_disabled) return null;
    if (_database != null) return _database;
    try {
      final basePath = await getDatabasesPath();
      final path = p.join(basePath, 'landmarks_cache.db');
      _database = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $_table(
              id INTEGER PRIMARY KEY,
              title TEXT NOT NULL,
              lat REAL NOT NULL,
              lon REAL NOT NULL,
              image_url TEXT NOT NULL
            )
          ''');
        },
      );
      return _database;
    } on MissingPluginException catch (error) {
      debugPrint('LandmarkCache disabled: $error');
      _disabled = true;
      return null;
    } catch (error) {
      debugPrint('LandmarkCache init failed: $error');
      _disabled = true;
      return null;
    }
  }

  Future<List<Landmark>> readAll() async {
    final db = await _getDb();
    if (db == null) return const [];
    final rows = await db.query(_table, orderBy: 'id DESC');
    return rows.map(_fromRow).toList();
  }

  Future<void> replaceAll(List<Landmark> entries) async {
    final db = await _getDb();
    if (db == null) return;
    await db.transaction((txn) async {
      await txn.delete(_table);
      for (final entry in entries) {
        await txn.insert(
          _table,
          _toRow(entry),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> upsert(Landmark entry) async {
    final db = await _getDb();
    if (db == null) return;
    await db.insert(
      _table,
      _toRow(entry),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> remove(int id) async {
    final db = await _getDb();
    if (db == null) return;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clear() async {
    final db = await _getDb();
    if (db == null) return;
    await db.delete(_table);
  }

  Future<void> dispose() async {
    if (_disabled) return;
    await _database?.close();
    _database = null;
  }

  Map<String, Object?> _toRow(Landmark entry) {
    return {
      'id': entry.id,
      'title': entry.title,
      'lat': entry.lat,
      'lon': entry.lon,
      'image_url': entry.imageUrl,
    };
  }

  Landmark _fromRow(Map<String, Object?> row) {
    final lat = row['lat'];
    final lon = row['lon'];
    return Landmark(
      id: row['id'] as int,
      title: (row['title'] ?? '').toString(),
      lat: lat is num ? lat.toDouble() : double.tryParse('$lat') ?? 0,
      lon: lon is num ? lon.toDouble() : double.tryParse('$lon') ?? 0,
      imageUrl: (row['image_url'] ?? '').toString(),
    );
  }
}
