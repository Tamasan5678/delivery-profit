import 'package:delivery_profit_v2/models/delivery_record.dart';
import 'package:delivery_profit_v2/models/delivery_session.dart';
import 'package:delivery_profit_v2/models/finish_input_result.dart';
import 'package:delivery_profit_v2/repositories/delivery_repository.dart';
import 'package:delivery_profit_v2/screens/finish/daily_result_screen.dart';
import 'package:delivery_profit_v2/screens/finish/finish_input_screen.dart';
import 'package:delivery_profit_v2/screens/history/history_detail_screen.dart';
import 'package:delivery_profit_v2/screens/history/history_screen.dart';
import 'package:delivery_profit_v2/screens/home/home_screen.dart';
import 'package:delivery_profit_v2/screens/settings/settings_screen.dart';
import 'package:delivery_profit_v2/screens/start/start_distance_screen.dart';
import 'package:delivery_profit_v2/screens/start/target_count_screen.dart';
import 'package:delivery_profit_v2/screens/start/weather_screen.dart';
import 'package:delivery_profit_v2/services/active_delivery_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/screen_size_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final screen in portraitTestSizes) {
    testWidgets('${screen.name} renders all primary screens', (tester) async {
      await _verifyPrimaryScreens(tester, screen: screen);
    });

    testWidgets('${screen.name} keeps picker and delete dialog usable', (
      tester,
    ) async {
      await pumpAtSize(
        tester,
        screen: screen,
        home: StartDistanceScreen(loadEndDistance: () async => 999999),
      );
      await tester.tap(find.text('変更する'));
      await tester.pumpAndSettle();
      expect(find.text('キャンセル'), findsOneWidget);
      expect(find.text('決定'), findsOneWidget);
      expect(find.byType(ListWheelScrollView), findsWidgets);
      expectNoLayoutErrors(tester, '${screen.name} distance picker');
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      await pumpAtSize(
        tester,
        screen: screen,
        home: HistoryDetailScreen(
          record: _largeRecord(),
          repository: _ResponsiveRepository([_largeRecord()]),
        ),
      );
      await ensureReachable(
        tester,
        find.text('この記録を削除'),
        '${screen.name} history delete button',
      );
      await tester.tap(find.text('この記録を削除').first);
      await tester.pumpAndSettle();
      expect(find.text('キャンセル'), findsOneWidget);
      expect(find.text('削除する'), findsOneWidget);
      expectNoLayoutErrors(tester, '${screen.name} delete dialog');
    });
  }

  testWidgets('360dp remains operable at maximum-equivalent text scale', (
    tester,
  ) async {
    await _verifyPrimaryScreens(
      tester,
      screen: portraitTestSizes.first,
      textScale: 2,
    );
  });

  testWidgets('360dp Home supports active delivery and extreme values', (
    tester,
  ) async {
    await pumpAtSize(
      tester,
      screen: portraitTestSizes.first,
      home: HomeScreen(
        repository: _ResponsiveRepository([_largeRecord()]),
        activeDeliveryStorage: _ResponsiveActiveDeliveryStorage(_session()),
      ),
    );
    expect(find.text('-999,999'), findsWidgets);
    expect(find.text('1,000,000'), findsWidgets);
    expect(find.text('99'), findsWidgets);
    await ensureReachable(
      tester,
      find.text('配達終了'),
      '360dp active delivery button',
    );
  });
}

Future<void> _verifyPrimaryScreens(
  WidgetTester tester, {
  required ScreenTestSize screen,
  double textScale = 1,
}) async {
  final repository = _ResponsiveRepository([_largeRecord()]);
  final cases = <({Widget screen, String button})>[
    (
      screen: HomeScreen(
        repository: repository,
        activeDeliveryStorage: _ResponsiveActiveDeliveryStorage(),
      ),
      button: '🚗 配達開始',
    ),
    (
      screen: StartDistanceScreen(loadEndDistance: () async => 999999),
      button: '次へ',
    ),
    (
      screen: const TargetCountScreen(startDistanceKm: 999999, targetCount: 99),
      button: '次へ',
    ),
    (
      screen: const WeatherScreen(targetCount: 99, startDistanceKm: 999999),
      button: '配達を開始する',
    ),
    (
      screen: FinishInputScreen(
        session: _session(),
        repository: repository,
        activeDeliveryStorage: _ResponsiveActiveDeliveryStorage(),
      ),
      button: '保存する',
    ),
    (
      screen: DailyResultScreen(
        result: const FinishInputResult(
          onlineTime: '23:55',
          sales: 1000000,
          deliveryCount: 99,
          distance: 999999,
        ),
        record: _largeRecord(),
      ),
      button: 'ホームへ戻る',
    ),
    (
      screen: HistoryScreen(repository: _ResponsiveRepository()),
      button: '配達履歴はまだありません',
    ),
    (
      screen: HistoryScreen(
        repository: _ResponsiveRepository([
          _largeRecord(),
          _largeRecord(id: 2, sessionId: 'responsive-record-2'),
        ]),
      ),
      button: '売上 1,000,000円',
    ),
    (
      screen: HistoryDetailScreen(
        record: _largeRecord(),
        repository: repository,
      ),
      button: 'この記録を削除',
    ),
    (screen: const SettingsScreen(), button: 'ガソリン単価'),
  ];

  for (final testCase in cases) {
    await pumpAtSize(
      tester,
      screen: screen,
      textScale: textScale,
      home: testCase.screen,
    );
    await ensureReachable(
      tester,
      find.text(testCase.button),
      '${screen.name} ${testCase.screen.runtimeType} ${testCase.button}',
    );
  }
}

DeliverySession _session() => DeliverySession(
  sessionId: 'responsive-session',
  targetCount: 99,
  weather: '雨',
  startDistanceKm: 999999,
  startedAtUtcMs: DateTime(2026, 8, 2, 9).toUtc().millisecondsSinceEpoch,
);

DeliveryRecord _largeRecord({
  int id = 1,
  String sessionId = 'responsive-record',
}) {
  final started = DateTime(2026, 8, 2, 0).toUtc().millisecondsSinceEpoch;
  final finished = DateTime(2026, 8, 2, 23, 55).toUtc().millisecondsSinceEpoch;
  return DeliveryRecord(
    id: id,
    sessionId: sessionId,
    startedAtUtcMs: started,
    finishedAtUtcMs: finished,
    startDistanceKm: 999999,
    targetCount: 99,
    weather: '雨',
    onlineMinutes: 1435,
    salesYen: 1000000,
    deliveryCount: 99,
    travelDistanceKm: 999999,
    fuelEfficiencyKmPerLiter: 50,
    fuelPriceYenPerLiter: 300,
    fuelUsedLiters: 0.5,
    fuelCostYen: 1999999,
    profitYen: -999999,
    createdAtUtcMs: finished,
  );
}

class _ResponsiveRepository extends DeliveryRepository {
  _ResponsiveRepository([this.records = const []]);

  final List<DeliveryRecord> records;

  @override
  Future<DeliveryRecord?> getDeliveryRecordBySessionId(String _) async => null;

  @override
  Future<List<DeliveryRecord>> getAllDeliveryRecords() async => records;

  @override
  Future<List<DeliveryRecord>> getDeliveryRecordsForDay(DateTime _) async =>
      records;

  @override
  Future<List<DeliveryRecord>> getDeliveryRecordsForWeek(DateTime _) async =>
      records;

  @override
  Future<List<DeliveryRecord>> getDeliveryRecordsForMonth(DateTime _) async =>
      records;
}

class _ResponsiveActiveDeliveryStorage implements ActiveDeliveryStorage {
  _ResponsiveActiveDeliveryStorage([this.session]);

  DeliverySession? session;

  @override
  Future<void> clear() async => session = null;

  @override
  Future<DeliverySession?> load() async => session;

  @override
  Future<void> save(DeliverySession value) async => session = value;
}
