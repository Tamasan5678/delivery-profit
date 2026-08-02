import 'dart:io';

import 'package:delivery_profit_v2/database/app_database.dart';
import 'package:delivery_profit_v2/models/delivery_record.dart';
import 'package:delivery_profit_v2/repositories/delivery_repository.dart';
import 'package:delivery_profit_v2/services/delivery_calculator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(sqfliteFfiInit);

  test(
    'August monthly and Monday-based weekly totals use all saved rows',
    () async {
      final fixture = await _DatabaseFixture.open('monthly_aggregation_');
      addTearDown(fixture.dispose);

      for (var day = 1; day <= 31; day++) {
        await fixture.repository.insertDeliveryRecord(
          _dailyRecord(
            DateTime(2026, 8, day),
            'aug-${day.toString().padLeft(2, '0')}',
          ),
        );
      }

      final august = await fixture.repository.getDeliveryRecordsForMonth(
        DateTime(2026, 8, 15),
      );
      _expectTotals(_totals(august), days: 31);

      final expectedWeekDays = <DateTime, int>{
        DateTime(2026, 8, 1): 2,
        DateTime(2026, 8, 3): 7,
        DateTime(2026, 8, 10): 7,
        DateTime(2026, 8, 17): 7,
        DateTime(2026, 8, 24): 7,
        DateTime(2026, 8, 31): 1,
      };
      for (final entry in expectedWeekDays.entries) {
        final records = await fixture.repository.getDeliveryRecordsForWeek(
          entry.key,
        );
        _expectTotals(_totals(records), days: entry.value);
      }
    },
  );

  test(
    'same-day sessions, adjacent months, and reopen retain every row',
    () async {
      final fixture = await _DatabaseFixture.open('monthly_retention_');
      addTearDown(fixture.dispose);

      await fixture.repository.insertDeliveryRecord(
        _dailyRecord(DateTime(2026, 7, 31), 'jul-31'),
      );
      for (var day = 1; day <= 31; day++) {
        await fixture.repository.insertDeliveryRecord(
          _dailyRecord(
            DateTime(2026, 8, day),
            'aug-${day.toString().padLeft(2, '0')}',
          ),
        );
      }
      await fixture.repository.insertDeliveryRecord(
        _dailyRecord(DateTime(2026, 9, 1), 'sep-01'),
      );

      var august = await fixture.repository.getDeliveryRecordsForMonth(
        DateTime(2026, 8, 1),
      );
      expect(august, hasLength(31));
      expect(
        august.every((record) => record.sessionId.startsWith('aug-')),
        isTrue,
      );
      expect(await fixture.repository.getAllDeliveryRecords(), hasLength(33));
      expect(
        await fixture.repository.getDeliveryRecordsForDay(
          DateTime(2026, 7, 31),
        ),
        hasLength(1),
      );
      expect(
        await fixture.repository.getDeliveryRecordsForDay(DateTime(2026, 9, 1)),
        hasLength(1),
      );
      _expectTotals(
        _totals(
          await fixture.repository.getDeliveryRecordsForWeek(
            DateTime(2026, 8, 1),
          ),
        ),
        days: 3,
      );
      _expectTotals(
        _totals(
          await fixture.repository.getDeliveryRecordsForWeek(
            DateTime(2026, 8, 31),
          ),
        ),
        days: 2,
      );

      await fixture.repository.insertDeliveryRecord(
        _dailyRecord(DateTime(2026, 8, 15, 12), 'aug-15-extra-1'),
      );
      await fixture.repository.insertDeliveryRecord(
        _dailyRecord(DateTime(2026, 8, 15, 18), 'aug-15-extra-2'),
      );

      final day = await fixture.repository.getDeliveryRecordsForDay(
        DateTime(2026, 8, 15),
      );
      _expectTotals(_totals(day), days: 3);
      final week = await fixture.repository.getDeliveryRecordsForWeek(
        DateTime(2026, 8, 15),
      );
      _expectTotals(_totals(week), days: 9);
      august = await fixture.repository.getDeliveryRecordsForMonth(
        DateTime(2026, 8, 15),
      );
      _expectTotals(_totals(august), days: 33);
      expect(await fixture.repository.getAllDeliveryRecords(), hasLength(35));

      await fixture.reopen();
      expect(await fixture.repository.getAllDeliveryRecords(), hasLength(35));
      expect(
        await fixture.repository.getDeliveryRecordsForDay(
          DateTime(2026, 7, 31),
        ),
        hasLength(1),
      );
      expect(
        await fixture.repository.getDeliveryRecordsForDay(DateTime(2026, 9, 1)),
        hasLength(1),
      );
    },
  );

  test('saved-period totals calculate weighted metrics, not daily means', () {
    const totals = DeliveryTotals(
      sales: 30000,
      deliveryCount: 30,
      onlineMinutes: 450,
      distanceKm: 120,
      fuelUsedLiters: 12,
      fuelCostYen: 2400,
      profitYen: 27600,
      sessionCount: 2,
    );

    final metrics = DeliveryCalculator.calculateSavedTotals(totals);
    expect(metrics.profit, 27600);
    expect(metrics.gasolineCost, 2400);
    expect(metrics.averageProfitPerDelivery, 920);
    expect(metrics.distancePerDelivery, 4);
    expect(metrics.minutesPerDelivery, 15);
    expect(metrics.gasolinePerDelivery, 0.4);
    expect(metrics.hourlyProfit, 3680);
  });

  test('twelve months remain queryable without automatic deletion', () async {
    final fixture = await _DatabaseFixture.open('year_retention_');
    addTearDown(fixture.dispose);

    var sequence = 0;
    for (
      var day = DateTime(2025, 9, 1);
      day.isBefore(DateTime(2026, 9, 1));
      day = DateTime(day.year, day.month, day.day + 1)
    ) {
      await fixture.repository.insertDeliveryRecord(
        _dailyRecord(day, 'year-${sequence++}'),
      );
    }

    final allWatch = Stopwatch()..start();
    final all = await fixture.repository.getAllDeliveryRecords();
    allWatch.stop();
    final monthWatch = Stopwatch()..start();
    final august = await fixture.repository.getDeliveryRecordsForMonth(
      DateTime(2026, 8, 15),
    );
    monthWatch.stop();

    expect(all, hasLength(365));
    expect(august, hasLength(31));
    expect(
      await fixture.repository.getDeliveryRecordsForDay(DateTime(2025, 9, 1)),
      hasLength(1),
    );

    await fixture.close();
    final databaseBytes = await File(fixture.path).length();
    // Kept in test output as an audit measurement, without asserting a
    // machine-dependent performance threshold.
    // ignore: avoid_print
    print(
      'MONTHLY_AUDIT rows=${all.length} db_bytes=$databaseBytes '
      'all_us=${allWatch.elapsedMicroseconds} '
      'month_us=${monthWatch.elapsedMicroseconds}',
    );
    await fixture.reopen();
    expect(await fixture.repository.getAllDeliveryRecords(), hasLength(365));
  });
}

DeliveryRecord _dailyRecord(DateTime localDay, String sessionId) {
  final started = DateTime(
    localDay.year,
    localDay.month,
    localDay.day,
    localDay.hour == 0 ? 9 : localDay.hour,
  );
  final finished = started.add(const Duration(hours: 5));
  return DeliveryRecord(
    sessionId: sessionId,
    startedAtUtcMs: started.toUtc().millisecondsSinceEpoch,
    finishedAtUtcMs: finished.toUtc().millisecondsSinceEpoch,
    startDistanceKm: 100000,
    targetCount: 20,
    weather: '晴れ',
    onlineMinutes: 300,
    salesYen: 10000,
    deliveryCount: 20,
    travelDistanceKm: 100,
    fuelEfficiencyKmPerLiter: 10,
    fuelPriceYenPerLiter: 200,
    fuelUsedLiters: 10,
    fuelCostYen: 2000,
    profitYen: 8000,
    createdAtUtcMs: finished.toUtc().millisecondsSinceEpoch,
  );
}

DeliveryTotals _totals(List<DeliveryRecord> records) => DeliveryTotals(
  sales: records.fold(0, (sum, record) => sum + record.salesYen),
  deliveryCount: records.fold(0, (sum, record) => sum + record.deliveryCount),
  onlineMinutes: records.fold(0, (sum, record) => sum + record.onlineMinutes),
  distanceKm: records.fold(0, (sum, record) => sum + record.travelDistanceKm),
  fuelUsedLiters: records.fold(0, (sum, record) => sum + record.fuelUsedLiters),
  fuelCostYen: records.fold(0, (sum, record) => sum + record.fuelCostYen),
  profitYen: records.fold(0, (sum, record) => sum + record.profitYen),
  sessionCount: records.length,
);

void _expectTotals(DeliveryTotals totals, {required int days}) {
  expect(totals.sessionCount, days);
  expect(totals.sales, 10000 * days);
  expect(totals.profitYen, 8000 * days);
  expect(totals.deliveryCount, 20 * days);
  expect(totals.distanceKm, 100 * days);
  expect(totals.onlineMinutes, 300 * days);
  expect(totals.fuelUsedLiters, 10 * days);
  expect(totals.fuelCostYen, 2000 * days);
  expect(totals.profitYen, totals.sales - totals.fuelCostYen);

  final metrics = DeliveryCalculator.calculateSavedTotals(totals);
  expect(metrics.hourlyProfit, 1600);
  expect(metrics.averageProfitPerDelivery, 400);
  expect(metrics.distancePerDelivery, 5);
  expect(metrics.minutesPerDelivery, 15);
  expect(metrics.gasolinePerDelivery, 0.5);
}

class _DatabaseFixture {
  _DatabaseFixture._(this.directory, this.path, this.database)
    : repository = DeliveryRepository(databaseProvider: () async => database);

  final Directory directory;
  final String path;
  Database database;
  late DeliveryRepository repository;

  static Future<_DatabaseFixture> open(String prefix) async {
    final directory = await Directory.systemTemp.createTemp(prefix);
    final path = p.join(directory.path, 'audit.db');
    final database = await databaseFactoryFfi.openDatabase(
      path,
      options: AppDatabase.openOptions,
    );
    return _DatabaseFixture._(directory, path, database);
  }

  Future<void> close() async {
    if (database.isOpen) await database.close();
  }

  Future<void> reopen() async {
    await close();
    database = await databaseFactoryFfi.openDatabase(
      path,
      options: AppDatabase.openOptions,
    );
    repository = DeliveryRepository(databaseProvider: () async => database);
  }

  Future<void> dispose() async {
    await close();
    await databaseFactoryFfi.deleteDatabase(path);
    if (await directory.exists()) await directory.delete(recursive: true);
  }
}
