import 'dart:io';

import 'package:delivery_profit_v2/database/app_database.dart';
import 'package:delivery_profit_v2/models/delivery_record.dart';
import 'package:delivery_profit_v2/repositories/delivery_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test('SQLite 100 and 500 row read performance', () async {
  sqfliteFfiInit();
  final path = '${Directory.systemTemp.path}/delivery_profit_release_audit_${DateTime.now().microsecondsSinceEpoch}.db';
  final database = await databaseFactoryFfi.openDatabase(
    path,
    options: AppDatabase.openOptions,
  );
  final repository = DeliveryRepository(databaseProvider: () async => database);

  Future<void> insertRange(int start, int end) async {
    final batch = database.batch();
    for (var index = start; index < end; index++) {
      final fuelCost = 170 + index % 20;
      final record = DeliveryRecord(
        sessionId: 'release-audit-$index',
        startedAtUtcMs: 1767225600000 + index * 3600000,
        finishedAtUtcMs: 1767227400000 + index * 3600000,
        startDistanceKm: 100000 + index * 10,
        targetCount: 20,
        weather: const ['晴れ', '曇り', '雨'][index % 3],
        onlineMinutes: 300,
        salesYen: 10000 + index,
        deliveryCount: 20,
        travelDistanceKm: 10,
        fuelEfficiencyKmPerLiter: 10,
        fuelPriceYenPerLiter: 170,
        fuelUsedLiters: 1,
        fuelCostYen: fuelCost,
        profitYen: 10000 + index - fuelCost,
        createdAtUtcMs: 1767227400000 + index * 3600000,
      );
      batch.insert(AppDatabase.deliveryRecordsTable, record.toMap()..remove('id'));
    }
    await batch.commit(noResult: true);
  }

  Future<int> measureAll() async {
    final stopwatch = Stopwatch()..start();
    final records = await repository.getAllDeliveryRecords();
    stopwatch.stop();
    if (records.isEmpty) throw StateError('records were not loaded');
    return stopwatch.elapsedMicroseconds;
  }

  await insertRange(0, 100);
  final load100 = await measureAll();
  await insertRange(100, 500);
  final load500 = await measureAll();
  final periodWatch = Stopwatch()..start();
  final period = await repository.getDeliveryRecordsBetween(
    startUtcMs: 1767225600000,
    endUtcMs: 1767225600000 + 501 * 3600000,
  );
  periodWatch.stop();

  final indexes = await database.rawQuery(
    "SELECT name, sql FROM sqlite_master WHERE type = 'index' ORDER BY name",
  );
  await database.close();
  final bytes = File(path).lengthSync();

  stdout.writeln('temporary_db=$path');
  stdout.writeln('rows_100_load_us=$load100');
  stdout.writeln('rows_500_load_us=$load500');
  stdout.writeln('period_500_rows=${period.length}');
  stdout.writeln('period_500_load_us=${periodWatch.elapsedMicroseconds}');
  stdout.writeln('db_size_bytes=$bytes');
  stdout.writeln('indexes=$indexes');
  });
}
