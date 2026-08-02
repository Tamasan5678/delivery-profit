import 'dart:io';

import 'package:delivery_profit_v2/database/app_database.dart';
import 'package:delivery_profit_v2/models/delivery_record.dart';
import 'package:delivery_profit_v2/repositories/delivery_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common/utils/utils.dart' show firstIntValue;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(sqfliteFfiInit);

  test(
    'version 1 database migrates to version 3 and supports repository CRUD',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'delivery_profit_migration_',
      );
      final path = p.join(directory.path, 'migration.db');
      addTearDown(() async {
        await databaseFactoryFfi.deleteDatabase(path);
        if (await directory.exists()) await directory.delete(recursive: true);
      });

      var db = await _openVersion1Database(path);
      await _insertVersion1Rows(db);
      final before = await db.query(
        AppDatabase.deliveryRecordsTable,
        orderBy: 'id ASC',
      );
      await db.close();

      db = await databaseFactoryFfi.openDatabase(
        path,
        options: AppDatabase.openOptions,
      );
      addTearDown(() async {
        if (db.isOpen) await db.close();
      });

      expect(await db.getVersion(), AppDatabase.databaseVersion);
      final migrated = await db.query(
        AppDatabase.deliveryRecordsTable,
        orderBy: 'id ASC',
      );
      expect(migrated, hasLength(before.length));
      for (var i = 0; i < before.length; i++) {
        for (final entry in before[i].entries) {
          expect(migrated[i][entry.key], entry.value);
        }
      }

      final sessionIds = migrated
          .map((row) => row['session_id'] as String)
          .toList();
      expect(sessionIds.every((value) => value.isNotEmpty), isTrue);
      expect(sessionIds.toSet(), hasLength(sessionIds.length));
      expect(
        sessionIds.where((id) => id.startsWith('legacy-1000')),
        hasLength(2),
      );

      final indexes = await db.rawQuery(
        'PRAGMA index_list(${AppDatabase.deliveryRecordsTable})',
      );
      final sessionIndex = indexes.singleWhere(
        (row) => row['name'] == 'idx_delivery_records_session_id',
      );
      expect(sessionIndex['unique'], 1);

      final missingSessionId = _record('missing').toMap()
        ..remove('id')
        ..remove('session_id');
      await expectLater(
        db.insert(AppDatabase.deliveryRecordsTable, missingSessionId),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        db.insert(
          AppDatabase.deliveryRecordsTable,
          (_record('valid').toMap()..remove('id'))..['session_id'] = '',
        ),
        throwsA(isA<DatabaseException>()),
      );

      for (final invalidValues in [
        (_record('negative-sales').toMap()..remove('id'))..['sales_yen'] = -1,
        (_record('negative-count').toMap()..remove('id'))
          ..['delivery_count'] = -1,
        (_record('negative-minutes').toMap()..remove('id'))
          ..['online_minutes'] = -1,
        (_record('negative-distance').toMap()..remove('id'))
          ..['travel_distance_km'] = -1.0,
        (_record('invalid-efficiency').toMap()..remove('id'))
          ..['fuel_efficiency_km_per_liter'] = 0.0,
        (_record('invalid-price').toMap()..remove('id'))
          ..['fuel_price_yen_per_liter'] = 99,
        (_record('negative-fuel').toMap()..remove('id'))
          ..['fuel_used_liters'] = -1.0,
        (_record('infinite-fuel').toMap()..remove('id'))
          ..['fuel_used_liters'] = double.infinity,
        (_record('nan-distance').toMap()..remove('id'))
          ..['travel_distance_km'] = double.nan,
        (_record('negative-cost').toMap()..remove('id'))
          ..['fuel_cost_yen'] = -1,
        (_record('bad-profit').toMap()..remove('id'))..['profit_yen'] = 1,
        (_record('bad-time').toMap()..remove('id'))
          ..['finished_at_utc_ms'] = 4000,
      ]) {
        await expectLater(
          db.insert(AppDatabase.deliveryRecordsTable, invalidValues),
          throwsA(isA<DatabaseException>()),
        );
      }

      final repository = DeliveryRepository(databaseProvider: () async => db);
      final newRecord = _record('new-session');
      final newId = await repository.insertDeliveryRecord(newRecord);
      expect(
        (await repository.getDeliveryRecordById(newId))?.sessionId,
        'new-session',
      );
      expect(
        (await repository.getDeliveryRecordBySessionId('new-session'))?.id,
        newId,
      );
      expect((await repository.getAllDeliveryRecords()).first.id, newId);
      expect(
        (await repository.getDeliveryRecordsBetween(
          startUtcMs: 4500,
          endUtcMs: 5500,
        )).map((record) => record.id),
        contains(newId),
      );

      final countAfterFirstInsert = firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM ${AppDatabase.deliveryRecordsTable}',
        ),
      );
      final duplicateId = await repository.insertDeliveryRecord(
        _record('new-session', salesYen: 999999),
      );
      expect(duplicateId, newId);
      expect(
        firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM ${AppDatabase.deliveryRecordsTable}',
          ),
        ),
        countAfterFirstInsert,
      );
      expect(
        (await repository.getDeliveryRecordById(newId))?.salesYen,
        newRecord.salesYen,
      );

      await repository.insertDeliveryRecord(_record('another-session'));
      expect(
        firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM ${AppDatabase.deliveryRecordsTable}',
          ),
        ),
        countAfterFirstInsert! + 1,
      );

      final countBeforeReopen = firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM ${AppDatabase.deliveryRecordsTable}',
        ),
      );
      await db.close();
      db = await databaseFactoryFfi.openDatabase(
        path,
        options: AppDatabase.openOptions,
      );
      expect(await db.getVersion(), 3);
      expect(
        firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM ${AppDatabase.deliveryRecordsTable}',
          ),
        ),
        countBeforeReopen,
      );
    },
  );

  test(
    'failed migration rolls back schema, version, and existing rows',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'delivery_profit_migration_failure_',
      );
      final path = p.join(directory.path, 'migration_failure.db');
      addTearDown(() async {
        await databaseFactoryFfi.deleteDatabase(path);
        if (await directory.exists()) await directory.delete(recursive: true);
      });

      var db = await _openVersion1Database(path);
      await _insertVersion1Rows(db);
      await db.execute('''
      CREATE INDEX idx_delivery_records_session_id
      ON ${AppDatabase.deliveryRecordsTable} (started_at_utc_ms)
    ''');
      await db.close();

      await expectLater(
        databaseFactoryFfi.openDatabase(path, options: AppDatabase.openOptions),
        throwsA(isA<DatabaseException>()),
      );

      db = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(version: 1),
      );
      addTearDown(() async {
        if (db.isOpen) await db.close();
      });
      expect(await db.getVersion(), 1);
      expect(await db.query(AppDatabase.deliveryRecordsTable), hasLength(3));
      final columns = await db.rawQuery(
        'PRAGMA table_info(${AppDatabase.deliveryRecordsTable})',
      );
      expect(columns.map((row) => row['name']), isNot(contains('session_id')));
    },
  );
}

Future<Database> _openVersion1Database(String path) {
  return databaseFactoryFfi.openDatabase(
    path,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE ${AppDatabase.deliveryRecordsTable} (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            started_at_utc_ms INTEGER NOT NULL,
            finished_at_utc_ms INTEGER NOT NULL,
            start_distance_km REAL NOT NULL,
            target_count INTEGER NOT NULL,
            weather TEXT NOT NULL,
            online_minutes INTEGER NOT NULL,
            sales_yen INTEGER NOT NULL,
            delivery_count INTEGER NOT NULL,
            travel_distance_km REAL NOT NULL,
            fuel_efficiency_km_per_liter REAL NOT NULL,
            fuel_price_yen_per_liter INTEGER NOT NULL,
            fuel_used_liters REAL NOT NULL,
            fuel_cost_yen INTEGER NOT NULL,
            profit_yen INTEGER NOT NULL,
            created_at_utc_ms INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE INDEX idx_delivery_records_finished_at
          ON ${AppDatabase.deliveryRecordsTable} (finished_at_utc_ms)
        ''');
      },
    ),
  );
}

Future<void> _insertVersion1Rows(Database db) async {
  for (final values in [
    _version1Map(startedAt: 1000, finishedAt: 2000, sales: 1000),
    _version1Map(startedAt: 1000, finishedAt: 3000, sales: 2000),
    _version1Map(startedAt: 2000, finishedAt: 4000, sales: 3000),
  ]) {
    await db.insert(AppDatabase.deliveryRecordsTable, values);
  }
}

Map<String, Object?> _version1Map({
  required int startedAt,
  required int finishedAt,
  required int sales,
}) => {
  'started_at_utc_ms': startedAt,
  'finished_at_utc_ms': finishedAt,
  'start_distance_km': 100.0,
  'target_count': 20,
  'weather': '晴れ',
  'online_minutes': 60,
  'sales_yen': sales,
  'delivery_count': 1,
  'travel_distance_km': 10.0,
  'fuel_efficiency_km_per_liter': 10.0,
  'fuel_price_yen_per_liter': 170,
  'fuel_used_liters': 1.0,
  'fuel_cost_yen': 170,
  'profit_yen': sales - 170,
  'created_at_utc_ms': finishedAt,
};

DeliveryRecord _record(String sessionId, {int salesYen = 5000}) =>
    DeliveryRecord(
      sessionId: sessionId,
      startedAtUtcMs: 4500,
      finishedAtUtcMs: 5000,
      startDistanceKm: 200,
      targetCount: 20,
      weather: '晴れ',
      onlineMinutes: 60,
      salesYen: salesYen,
      deliveryCount: 1,
      travelDistanceKm: 10,
      fuelEfficiencyKmPerLiter: 10,
      fuelPriceYenPerLiter: 170,
      fuelUsedLiters: 1,
      fuelCostYen: 170,
      profitYen: salesYen - 170,
      createdAtUtcMs: 5000,
    );
