import 'package:delivery_profit_v2/core/theme/app_theme.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Home renders in portrait without overflow', (tester) async {
    await _pumpPortrait(
      tester,
      HomeScreen(
        repository: _PortraitRepository(),
        activeDeliveryStorage: _EmptyActiveDeliveryStorage(),
      ),
    );
  });

  testWidgets('start distance renders in portrait without overflow', (
    tester,
  ) async {
    await _pumpPortrait(
      tester,
      StartDistanceScreen(loadEndDistance: () async => 106620),
    );
  });

  testWidgets('target count renders in portrait without overflow', (
    tester,
  ) async {
    await _pumpPortrait(
      tester,
      const TargetCountScreen(startDistanceKm: 106620),
    );
  });

  testWidgets('weather renders in portrait without overflow', (tester) async {
    await _pumpPortrait(
      tester,
      const WeatherScreen(targetCount: 20, startDistanceKm: 106620),
    );
  });

  testWidgets('finish input renders in portrait without overflow', (
    tester,
  ) async {
    await _pumpPortrait(
      tester,
      FinishInputScreen(
        session: _session(),
        repository: _PortraitRepository(),
        activeDeliveryStorage: _EmptyActiveDeliveryStorage(),
      ),
    );
  });

  testWidgets('daily result renders in portrait without overflow', (
    tester,
  ) async {
    await _pumpPortrait(
      tester,
      DailyResultScreen(
        result: const FinishInputResult(
          onlineTime: '5:00',
          sales: 10000,
          deliveryCount: 20,
          distance: 100,
        ),
        record: _record(),
      ),
    );
  });

  testWidgets('history renders in portrait without overflow', (tester) async {
    await _pumpPortrait(
      tester,
      HistoryScreen(repository: _PortraitRepository([_record()])),
    );
  });

  testWidgets('history detail renders in portrait without overflow', (
    tester,
  ) async {
    await _pumpPortrait(
      tester,
      HistoryDetailScreen(
        record: _record(),
        repository: _PortraitRepository([_record()]),
      ),
    );
  });

  testWidgets('settings renders in portrait without overflow', (tester) async {
    await _pumpPortrait(tester, const SettingsScreen());
  });
}

Future<void> _pumpPortrait(WidgetTester tester, Widget home) async {
  await tester.binding.setSurfaceSize(const Size(1080, 2424));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(theme: AppTheme.lightTheme, home: home));
  await tester.pumpAndSettle();
  expect(find.byType(ErrorWidget), findsNothing);
  expect(tester.takeException(), isNull);
}

DeliverySession _session() => DeliverySession(
  sessionId: 'portrait-session',
  targetCount: 20,
  weather: '晴れ',
  startDistanceKm: 106620,
  startedAtUtcMs: DateTime(2026, 8, 2, 9).toUtc().millisecondsSinceEpoch,
);

DeliveryRecord _record() {
  final started = DateTime(2026, 8, 2, 9).toUtc().millisecondsSinceEpoch;
  final finished = DateTime(2026, 8, 2, 14).toUtc().millisecondsSinceEpoch;
  return DeliveryRecord(
    id: 1,
    sessionId: 'portrait-record',
    startedAtUtcMs: started,
    finishedAtUtcMs: finished,
    startDistanceKm: 106620,
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
    createdAtUtcMs: finished,
  );
}

class _PortraitRepository extends DeliveryRepository {
  _PortraitRepository([this.records = const []]);

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

class _EmptyActiveDeliveryStorage implements ActiveDeliveryStorage {
  @override
  Future<void> clear() async {}

  @override
  Future<DeliverySession?> load() async => null;

  @override
  Future<void> save(DeliverySession value) async {}
}
