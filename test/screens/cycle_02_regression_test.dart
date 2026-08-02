import 'dart:async';

import 'package:delivery_profit_v2/core/theme/app_theme.dart';
import 'package:delivery_profit_v2/models/delivery_record.dart';
import 'package:delivery_profit_v2/models/delivery_session.dart';
import 'package:delivery_profit_v2/repositories/delivery_repository.dart';
import 'package:delivery_profit_v2/screens/finish/finish_input_screen.dart';
import 'package:delivery_profit_v2/screens/history/history_screen.dart';
import 'package:delivery_profit_v2/screens/home/home_screen.dart';
import 'package:delivery_profit_v2/screens/start/start_distance_screen.dart';
import 'package:delivery_profit_v2/services/active_delivery_storage.dart';
import 'package:delivery_profit_v2/services/preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('previous end distance', () {
    test('persists and restores across SharedPreferences instances', () async {
      SharedPreferences.setMockInitialValues({});

      expect(await PreferencesService.getStoredEndDistance(), isNull);
      expect(await PreferencesService.saveEndDistance(106720), isTrue);
      expect(await PreferencesService.getStoredEndDistance(), 106720);
    });

    testWidgets('successful delivery saves start plus travel distance', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final repository = _MemoryRepository();
      int? savedDistance;
      await tester.pumpWidget(
        _app(
          FinishInputScreen(
            session: _session(startDistanceKm: 106620),
            repository: repository,
            activeDeliveryStorage: _MemoryActiveDeliveryStorage(),
            saveEndDistance: (value) async {
              savedDistance = value;
              return true;
            },
          ),
        ),
      );

      final openDistancePicker = tester
          .widget<InkWell>(
            find.ancestor(
              of: find.text('走行距離（km）'),
              matching: find.byType(InkWell),
            ),
          )
          .onTap!;
      openDistancePicker();
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(ListWheelScrollView).last,
        const Offset(0, -80),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('決定'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('保存する'));
      await tester.pumpAndSettle();

      expect(repository.records, hasLength(1));
      expect(
        savedDistance,
        106620 + repository.records.single.travelDistanceKm.round(),
      );
      expect(find.text('本日の配達結果'), findsOneWidget);
    });

    testWidgets('distance cache failure does not retry SQLite insert', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final repository = _MemoryRepository();
      await tester.pumpWidget(
        _app(
          FinishInputScreen(
            session: _session(),
            repository: repository,
            activeDeliveryStorage: _MemoryActiveDeliveryStorage(),
            saveEndDistance: (_) => throw StateError('write failed'),
          ),
        ),
      );

      await tester.tap(find.text('保存する'));
      await tester.tap(find.text('保存する'));
      await tester.pumpAndSettle();

      expect(repository.insertCalls, 1);
      expect(find.text('本日の配達結果'), findsOneWidget);
    });

    testWidgets('start screen prefers stored distance and remains editable', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(StartDistanceScreen(loadEndDistance: () async => 106720)),
      );
      await tester.pumpAndSettle();

      expect(find.text('106720'), findsOneWidget);
      await tester.tap(find.text('変更する'));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byType(ListWheelScrollView).first,
        const Offset(0, -80),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('決定'));
      await tester.pumpAndSettle();

      expect(find.text('106720'), findsNothing);
    });

    testWidgets('missing cache recovers from latest record only', (
      tester,
    ) async {
      final repository = _MemoryRepository([_record(start: 100, travel: 25)]);
      int? recovered;
      await tester.pumpWidget(
        _app(
          StartDistanceScreen(
            repository: repository,
            loadEndDistance: () async => null,
            saveEndDistance: (value) async {
              recovered = value;
              return true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('125'), findsOneWidget);
      expect(recovered, 125);
    });

    testWidgets('stored odometer wins and history deletion cannot rewind it', (
      tester,
    ) async {
      final repository = _MemoryRepository([_record(start: 100, travel: 25)]);
      await repository.deleteDeliveryRecord(1);
      await tester.pumpWidget(
        _app(
          StartDistanceScreen(
            repository: repository,
            loadEndDistance: () async => 200,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('200'), findsOneWidget);
    });

    testWidgets('first launch keeps the current safe default', (tester) async {
      await tester.pumpWidget(
        _app(StartDistanceScreen(loadEndDistance: () async => null)),
      );
      await tester.pumpAndSettle();

      expect(find.text('106620'), findsOneWidget);
    });
  });

  group('summary request race', () {
    testWidgets('late day response cannot overwrite the selected week', (
      tester,
    ) async {
      final repository = _ControlledSummaryRepository();
      await tester.pumpWidget(
        _app(
          HomeScreen(
            repository: repository,
            activeDeliveryStorage: _MemoryActiveDeliveryStorage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('月'));
      await tester.tap(find.text('月'));
      await tester.pumpAndSettle();
      final delayedDay = repository.delayNextDay();
      await tester.tap(find.text('日'));
      await tester.pump();
      await tester.tap(find.text('週'));
      await tester.pumpAndSettle();
      expect(find.text('今週のデータはありません'), findsOneWidget);

      delayedDay.complete(const []);
      await tester.pumpAndSettle();
      expect(find.text('今週のデータはありません'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('reverse month day week responses keep the final week', (
      tester,
    ) async {
      final repository = _ControlledSummaryRepository();
      await tester.pumpWidget(
        _app(
          HomeScreen(
            repository: repository,
            activeDeliveryStorage: _MemoryActiveDeliveryStorage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final month = repository.delayNextMonth();
      final day = repository.delayNextDay();
      await tester.ensureVisible(find.text('月'));
      await tester.tap(find.text('月'));
      await tester.pump();
      await tester.tap(find.text('日'));
      await tester.pump();
      await tester.tap(find.text('週'));
      await tester.pumpAndSettle();
      month.complete(const []);
      await tester.pump();
      day.complete(const []);
      await tester.pumpAndSettle();

      expect(find.text('今週のデータはありません'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('completion after dispose does not call setState', (
      tester,
    ) async {
      final repository = _ControlledSummaryRepository();
      final delayed = repository.delayNextDay();
      await tester.pumpWidget(
        _app(
          HomeScreen(
            repository: repository,
            activeDeliveryStorage: _MemoryActiveDeliveryStorage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      delayed.complete(const []);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('navigation guards', () {
    testWidgets('home start button double tap pushes once', (tester) async {
      final observer = _CountingNavigatorObserver();
      await tester.pumpWidget(
        _app(
          HomeScreen(
            repository: _MemoryRepository(),
            activeDeliveryStorage: _MemoryActiveDeliveryStorage(),
          ),
          observer: observer,
        ),
      );
      await tester.pumpAndSettle();
      final before = observer.pushCount;

      final callback = tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, '🚗 配達開始'),
          )
          .onPressed!;
      callback();
      callback();
      await tester.pumpAndSettle();

      expect(observer.pushCount - before, 1);
      expect(find.byType(StartDistanceScreen), findsOneWidget);
    });

    testWidgets('start next double tap pushes one target screen', (
      tester,
    ) async {
      final observer = _CountingNavigatorObserver();
      await tester.pumpWidget(
        _app(
          StartDistanceScreen(loadEndDistance: () async => null),
          observer: observer,
        ),
      );
      await tester.pumpAndSettle();
      final before = observer.pushCount;

      final callback = tester
          .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, '次へ'))
          .onPressed!;
      callback();
      callback();
      await tester.pumpAndSettle();

      expect(observer.pushCount - before, 1);
      expect(find.text('目標件数'), findsOneWidget);
    });

    testWidgets('history card double tap pushes one detail screen', (
      tester,
    ) async {
      final observer = _CountingNavigatorObserver();
      await tester.pumpWidget(
        _app(
          HistoryScreen(repository: _MemoryRepository([_record()])),
          observer: observer,
        ),
      );
      await tester.pumpAndSettle();
      final before = observer.pushCount;

      final callback = tester
          .widget<InkWell>(
            find.ancestor(
              of: find.text('売上 1,000円'),
              matching: find.byType(InkWell),
            ),
          )
          .onTap!;
      callback();
      callback();
      await tester.pumpAndSettle();

      expect(observer.pushCount - before, 1);
      expect(find.text('履歴詳細'), findsOneWidget);
    });

    testWidgets('delete flow double actions delete only once', (tester) async {
      final repository = _MemoryRepository([_record()]);
      await tester.pumpWidget(_app(HistoryScreen(repository: repository)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('売上 1,000円'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('この記録を削除'));
      final delete = tester
          .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'この記録を削除'),
          )
          .onPressed!;
      delete();
      delete();
      await tester.pumpAndSettle();
      expect(find.text('この配達記録を削除しますか？'), findsOneWidget);

      final confirm = tester
          .widget<TextButton>(find.widgetWithText(TextButton, '削除する'))
          .onPressed!;
      confirm();
      confirm();
      await tester.pumpAndSettle();

      expect(repository.deleteCalls, 1);
    });
  });
}

Widget _app(Widget home, {_CountingNavigatorObserver? observer}) => MaterialApp(
  theme: AppTheme.lightTheme,
  home: home,
  navigatorObservers: [if (observer != null) observer],
);

DeliverySession _session({double startDistanceKm = 100}) => DeliverySession(
  sessionId: 'cycle-02-session',
  targetCount: 20,
  weather: '晴れ',
  startDistanceKm: startDistanceKm,
  startedAtUtcMs: DateTime.now().millisecondsSinceEpoch - 1000,
);

DeliveryRecord _record({double start = 100, double travel = 10}) =>
    DeliveryRecord(
      id: 1,
      sessionId: 'record-session',
      startedAtUtcMs: 1000,
      finishedAtUtcMs: 2000,
      startDistanceKm: start,
      targetCount: 20,
      weather: '晴れ',
      onlineMinutes: 60,
      salesYen: 1000,
      deliveryCount: 10,
      travelDistanceKm: travel,
      fuelEfficiencyKmPerLiter: 10,
      fuelPriceYenPerLiter: 170,
      fuelUsedLiters: travel / 10,
      fuelCostYen: (travel / 10 * 170).round(),
      profitYen: 1000 - (travel / 10 * 170).round(),
      createdAtUtcMs: 2000,
    );

class _MemoryRepository extends DeliveryRepository {
  _MemoryRepository([List<DeliveryRecord> initial = const []])
    : records = List.of(initial);

  final List<DeliveryRecord> records;
  int insertCalls = 0;
  int deleteCalls = 0;

  @override
  Future<int> insertDeliveryRecord(DeliveryRecord record) async {
    insertCalls++;
    final existing = await getDeliveryRecordBySessionId(record.sessionId);
    if (existing != null) return existing.id!;
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
  Future<List<DeliveryRecord>> getAllDeliveryRecords() async =>
      List.of(records);

  @override
  Future<List<DeliveryRecord>> getDeliveryRecordsForDay(DateTime _) async =>
      List.of(records);

  @override
  Future<List<DeliveryRecord>> getDeliveryRecordsForWeek(DateTime _) async =>
      List.of(records);

  @override
  Future<List<DeliveryRecord>> getDeliveryRecordsForMonth(DateTime _) async =>
      List.of(records);

  @override
  Future<int> deleteDeliveryRecord(int id) async {
    deleteCalls++;
    final before = records.length;
    records.removeWhere((record) => record.id == id);
    return before - records.length;
  }
}

class _ControlledSummaryRepository extends _MemoryRepository {
  final List<Completer<List<DeliveryRecord>>> _day = [];
  final List<Completer<List<DeliveryRecord>>> _month = [];

  Completer<List<DeliveryRecord>> delayNextDay() {
    final completer = Completer<List<DeliveryRecord>>();
    _day.add(completer);
    return completer;
  }

  Completer<List<DeliveryRecord>> delayNextMonth() {
    final completer = Completer<List<DeliveryRecord>>();
    _month.add(completer);
    return completer;
  }

  @override
  Future<List<DeliveryRecord>> getDeliveryRecordsForDay(DateTime _) =>
      _day.isEmpty ? Future.value(const []) : _day.removeAt(0).future;

  @override
  Future<List<DeliveryRecord>> getDeliveryRecordsForWeek(DateTime _) async =>
      const [];

  @override
  Future<List<DeliveryRecord>> getDeliveryRecordsForMonth(DateTime _) =>
      _month.isEmpty ? Future.value(const []) : _month.removeAt(0).future;
}

class _MemoryActiveDeliveryStorage implements ActiveDeliveryStorage {
  DeliverySession? session;

  @override
  Future<void> clear() async => session = null;

  @override
  Future<DeliverySession?> load() async => session;

  @override
  Future<void> save(DeliverySession value) async => session = value;
}

class _CountingNavigatorObserver extends NavigatorObserver {
  int pushCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushCount++;
    super.didPush(route, previousRoute);
  }
}
