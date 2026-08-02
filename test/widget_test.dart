import 'package:delivery_profit_v2/core/theme/app_theme.dart';
import 'package:delivery_profit_v2/models/delivery_record.dart';
import 'package:delivery_profit_v2/models/delivery_session.dart';
import 'package:delivery_profit_v2/repositories/delivery_repository.dart';
import 'package:delivery_profit_v2/screens/finish/finish_input_screen.dart';
import 'package:delivery_profit_v2/screens/history/history_screen.dart';
import 'package:delivery_profit_v2/screens/home/home_screen.dart';
import 'package:delivery_profit_v2/services/active_delivery_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  testWidgets('HomeScreen starts in normal mode', (tester) async {
    await tester.pumpWidget(
      _app(
        HomeScreen(
          repository: _FakeDeliveryRepository(),
          activeDeliveryStorage: _FakeActiveDeliveryStorage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).title,
      'Delivery Profit',
    );
    expect(find.text('🚗 配達開始'), findsOneWidget);
    expect(find.text('配達中です'), findsNothing);
    expect(find.byType(ErrorWidget), findsNothing);
  });

  testWidgets('HomeScreen restores an active delivery', (tester) async {
    const session = DeliverySession(
      sessionId: 'active-session',
      targetCount: 20,
      weather: '晴れ',
      startDistanceKm: 100.0,
      startedAtUtcMs: 1000,
    );
    await tester.pumpWidget(
      _app(
        HomeScreen(
          repository: _FakeDeliveryRepository(),
          activeDeliveryStorage: _FakeActiveDeliveryStorage(session),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('配達中です'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
    expect(find.text('晴れ'), findsOneWidget);
    expect(find.text('配達終了'), findsOneWidget);
    expect(find.text('🚗 配達開始'), findsNothing);
  });

  testWidgets('HomeScreen ignores an active delivery already saved', (
    tester,
  ) async {
    const session = DeliverySession(
      sessionId: 'saved-session',
      targetCount: 20,
      weather: '晴れ',
      startDistanceKm: 100.0,
      startedAtUtcMs: 1000,
    );
    await tester.pumpWidget(
      _app(
        HomeScreen(
          repository: _FakeDeliveryRepository([_record()]),
          activeDeliveryStorage: _FakeActiveDeliveryStorage(session, true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('配達中です'), findsNothing);
    expect(find.text('🚗 配達開始'), findsOneWidget);
  });

  testWidgets('clear failure after save cannot restore or duplicate session', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    const session = DeliverySession(
      sessionId: 'clear-failure-session',
      targetCount: 20,
      weather: '晴れ',
      startDistanceKm: 100.0,
      startedAtUtcMs: 1000,
    );
    final repository = _FakeDeliveryRepository();
    final storage = _FakeActiveDeliveryStorage(session, true);
    await tester.pumpWidget(
      _app(
        FinishInputScreen(
          session: session,
          repository: repository,
          activeDeliveryStorage: storage,
        ),
      ),
    );

    await tester.tap(find.text('保存する'));
    await tester.pumpAndSettle();
    expect(find.text('本日の配達結果'), findsOneWidget);
    expect(repository.records, hasLength(1));
    expect(repository.records.single.fuelEfficiencyKmPerLiter, 10.0);
    expect(repository.records.single.fuelPriceYenPerLiter, 170);

    await tester.pumpWidget(
      _app(HomeScreen(repository: repository, activeDeliveryStorage: storage)),
    );
    await tester.pumpAndSettle();
    expect(find.text('配達中です'), findsNothing);
    expect(repository.records, hasLength(1));
  });

  testWidgets('database exception shows only a safe save error', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final session = DeliverySession(
      sessionId: 'database-error-session',
      targetCount: 20,
      weather: '晴れ',
      startDistanceKm: 100,
      startedAtUtcMs: DateTime.now().millisecondsSinceEpoch - 1000,
    );
    await tester.pumpWidget(
      _app(
        FinishInputScreen(
          session: session,
          repository: _ThrowingDeliveryRepository(),
          activeDeliveryStorage: _FakeActiveDeliveryStorage(session),
        ),
      ),
    );

    await tester.tap(find.text('保存する'));
    await tester.pumpAndSettle();

    expect(find.text('保存に失敗しました。もう一度お試しください'), findsOneWidget);
    expect(find.textContaining('CHECK constraint failed'), findsNothing);
    expect(find.text('配達終了'), findsOneWidget);
  });

  testWidgets('HistoryScreen shows an empty message', (tester) async {
    await tester.pumpWidget(
      _app(HistoryScreen(repository: _FakeDeliveryRepository())),
    );
    await tester.pumpAndSettle();

    expect(find.text('配達履歴はまだありません'), findsOneWidget);
  });

  testWidgets('history card opens its detail screen', (tester) async {
    final record = _record();
    await tester.pumpWidget(
      _app(HistoryScreen(repository: _FakeDeliveryRepository([record]))),
    );
    await tester.pumpAndSettle();

    expect(find.text('売上 12,345円'), findsOneWidget);
    await tester.tap(find.text('売上 12,345円'));
    await tester.pumpAndSettle();

    expect(find.text('履歴詳細'), findsOneWidget);
    expect(find.text('この記録を削除'), findsOneWidget);
  });

  testWidgets('deleting a detail reloads the history list', (tester) async {
    final repository = _FakeDeliveryRepository([_record()]);
    await tester.pumpWidget(_app(HistoryScreen(repository: repository)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('売上 12,345円'));
    await tester.pumpAndSettle();
    final deleteButton = find.text('この記録を削除');
    await tester.ensureVisible(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('削除する'));
    await tester.pumpAndSettle();

    expect(repository.deletedIds, [1]);
    expect(find.text('配達履歴はまだありません'), findsOneWidget);
    expect(find.text('配達記録を削除しました'), findsOneWidget);
  });
}

Widget _app(Widget home) => MaterialApp(
  title: 'Delivery Profit',
  theme: AppTheme.lightTheme,
  home: home,
);

DeliveryRecord _record() => DeliveryRecord(
  id: 1,
  sessionId: 'saved-session',
  startedAtUtcMs: 1785632400000,
  finishedAtUtcMs: 1785655800000,
  startDistanceKm: 100.0,
  targetCount: 20,
  weather: '晴れ',
  onlineMinutes: 390,
  salesYen: 12345,
  deliveryCount: 20,
  travelDistanceKm: 100.0,
  fuelEfficiencyKmPerLiter: 12.5,
  fuelPriceYenPerLiter: 170,
  fuelUsedLiters: 8.0,
  fuelCostYen: 1360,
  profitYen: 10985,
  createdAtUtcMs: 1785655800000,
);

class _FakeDeliveryRepository extends DeliveryRepository {
  _FakeDeliveryRepository([List<DeliveryRecord> records = const []])
    : records = List.of(records);

  final List<DeliveryRecord> records;
  final List<int> deletedIds = [];

  @override
  Future<int> insertDeliveryRecord(DeliveryRecord record) async {
    final existing = await getDeliveryRecordBySessionId(record.sessionId);
    if (existing?.id != null) return existing!.id!;
    final id = records.length + 1;
    records.add(record.copyWith(id: id));
    return id;
  }

  @override
  Future<DeliveryRecord?> getDeliveryRecordBySessionId(String sessionId) async {
    for (final record in records) {
      if (record.sessionId == sessionId) return record;
    }
    return null;
  }

  @override
  Future<List<DeliveryRecord>> getAllDeliveryRecords() async => records;

  @override
  Future<List<DeliveryRecord>> getDeliveryRecordsForDay(
    DateTime localDay,
  ) async => records;

  @override
  Future<List<DeliveryRecord>> getDeliveryRecordsForWeek(
    DateTime localDay,
  ) async => records;

  @override
  Future<List<DeliveryRecord>> getDeliveryRecordsForMonth(
    DateTime localDay,
  ) async => records;

  @override
  Future<int> deleteDeliveryRecord(int id) async {
    deletedIds.add(id);
    final before = records.length;
    records.removeWhere((record) => record.id == id);
    return before - records.length;
  }
}

class _FakeActiveDeliveryStorage implements ActiveDeliveryStorage {
  _FakeActiveDeliveryStorage([this.session, this.throwOnClear = false]);

  final bool throwOnClear;

  DeliverySession? session;

  @override
  Future<void> clear() async {
    if (throwOnClear) throw StateError('clear failed');
    session = null;
  }

  @override
  Future<DeliverySession?> load() async => session;

  @override
  Future<void> save(DeliverySession value) async => session = value;
}

class _ThrowingDeliveryRepository extends DeliveryRepository {
  @override
  Future<int> insertDeliveryRecord(DeliveryRecord record) {
    throw _TestDatabaseException('CHECK constraint failed: delivery_records');
  }
}

class _TestDatabaseException extends DatabaseException {
  _TestDatabaseException(super.message);

  @override
  int? getResultCode() => 19;

  @override
  Object? get result => null;
}
