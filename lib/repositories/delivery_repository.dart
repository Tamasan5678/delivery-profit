import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/delivery_record.dart';

class DeliveryRepository {
  DeliveryRepository({
    AppDatabase? database,
    Future<Database> Function()? databaseProvider,
  }) : _database = database ?? AppDatabase.instance,
       _databaseProvider = databaseProvider;

  final AppDatabase _database;
  final Future<Database> Function()? _databaseProvider;

  Future<Database> get _db async =>
      _databaseProvider == null ? _database.database : _databaseProvider();

  Future<int> insertDeliveryRecord(DeliveryRecord record) async {
    record.validate();
    final db = await _db;
    try {
      return await db.insert(
        AppDatabase.deliveryRecordsTable,
        record.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } on DatabaseException {
      final existing = await getDeliveryRecordBySessionId(record.sessionId);
      if (existing?.id != null) return existing!.id!;
      rethrow;
    }
  }

  Future<DeliveryRecord?> getDeliveryRecordBySessionId(String sessionId) async {
    final db = await _db;
    final rows = await db.query(
      AppDatabase.deliveryRecordsTable,
      where: 'session_id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    return rows.isEmpty ? null : DeliveryRecord.fromMap(rows.first);
  }

  Future<DeliveryRecord?> getDeliveryRecordById(int id) async {
    final db = await _db;
    final rows = await db.query(
      AppDatabase.deliveryRecordsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : DeliveryRecord.fromMap(rows.first);
  }

  Future<List<DeliveryRecord>> getAllDeliveryRecords() async {
    final db = await _db;
    final rows = await db.query(
      AppDatabase.deliveryRecordsTable,
      orderBy: 'finished_at_utc_ms DESC',
    );
    return rows.map(DeliveryRecord.fromMap).toList();
  }

  Future<List<DeliveryRecord>> getDeliveryRecordsBetween({
    required int startUtcMs,
    required int endUtcMs,
  }) async {
    if (endUtcMs <= startUtcMs) return const [];
    final db = await _db;
    final rows = await db.query(
      AppDatabase.deliveryRecordsTable,
      where: 'finished_at_utc_ms >= ? AND finished_at_utc_ms < ?',
      whereArgs: [startUtcMs, endUtcMs],
      orderBy: 'finished_at_utc_ms DESC',
    );
    return rows.map(DeliveryRecord.fromMap).toList();
  }

  Future<List<DeliveryRecord>> getDeliveryRecordsForDay(DateTime localDay) {
    final start = DateTime(localDay.year, localDay.month, localDay.day);
    return getDeliveryRecordsBetween(
      startUtcMs: start.toUtc().millisecondsSinceEpoch,
      endUtcMs: DateTime(
        start.year,
        start.month,
        start.day + 1,
      ).toUtc().millisecondsSinceEpoch,
    );
  }

  Future<List<DeliveryRecord>> getDeliveryRecordsForWeek(DateTime localDay) {
    final day = DateTime(localDay.year, localDay.month, localDay.day);
    final start = DateTime(
      day.year,
      day.month,
      day.day - (day.weekday - DateTime.monday),
    );
    return getDeliveryRecordsBetween(
      startUtcMs: start.toUtc().millisecondsSinceEpoch,
      endUtcMs: DateTime(
        start.year,
        start.month,
        start.day + 7,
      ).toUtc().millisecondsSinceEpoch,
    );
  }

  Future<List<DeliveryRecord>> getDeliveryRecordsForMonth(DateTime localDay) {
    final start = DateTime(localDay.year, localDay.month);
    final end = DateTime(localDay.year, localDay.month + 1);
    return getDeliveryRecordsBetween(
      startUtcMs: start.toUtc().millisecondsSinceEpoch,
      endUtcMs: end.toUtc().millisecondsSinceEpoch,
    );
  }

  Future<int> deleteDeliveryRecord(int id) async {
    final db = await _db;
    return db.delete(
      AppDatabase.deliveryRecordsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
