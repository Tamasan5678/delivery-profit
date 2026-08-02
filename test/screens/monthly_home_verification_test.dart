import 'dart:async';

import 'package:delivery_profit_v2/core/theme/app_theme.dart';
import 'package:delivery_profit_v2/models/delivery_record.dart';
import 'package:delivery_profit_v2/models/delivery_session.dart';
import 'package:delivery_profit_v2/repositories/delivery_repository.dart';
import 'package:delivery_profit_v2/screens/home/home_screen.dart';
import 'package:delivery_profit_v2/services/active_delivery_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Home month and week show aggregate values with formatting', (
    tester,
  ) async {
    final repository = _HomeRepository(
      month: List.generate(31, (index) => _record('month-$index')),
      week: List.generate(7, (index) => _record('week-$index')),
    );
    await tester.binding.setSurfaceSize(const Size(1080, 2424));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('月'));
    await tester.tap(find.text('月'));
    await tester.pumpAndSettle();

    expect(find.text('248,000'), findsOneWidget);
    expect(find.text('1,600'), findsOneWidget);
    expect(find.text('400'), findsOneWidget);
    expect(find.text('5.0'), findsOneWidget);
    expect(find.text('15分／件'), findsOneWidget);
    expect(find.text('0.50'), findsOneWidget);
    expect(find.text('円／時間'), findsOneWidget);
    expect(find.text('km／件'), findsOneWidget);
    expect(find.text('L／件'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('週'));
    await tester.pumpAndSettle();
    expect(find.text('56,000'), findsOneWidget);
    expect(find.text('248,000'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('late month response cannot mix into final week display', (
    tester,
  ) async {
    final delayedMonth = Completer<List<DeliveryRecord>>();
    final repository = _HomeRepository(
      monthFuture: delayedMonth.future,
      week: List.generate(7, (index) => _record('week-$index')),
    );
    await tester.binding.setSurfaceSize(const Size(1080, 2424));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('月'));
    await tester.tap(find.text('月'));
    await tester.pump();
    await tester.tap(find.text('週'));
    await tester.pumpAndSettle();
    expect(find.text('56,000'), findsOneWidget);

    delayedMonth.complete(
      List.generate(31, (index) => _record('month-$index')),
    );
    await tester.pumpAndSettle();
    expect(find.text('56,000'), findsOneWidget);
    expect(find.text('248,000'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(_HomeRepository repository) => MaterialApp(
  theme: AppTheme.lightTheme,
  home: HomeScreen(
    repository: repository,
    activeDeliveryStorage: _EmptyActiveDeliveryStorage(),
  ),
);

DeliveryRecord _record(String sessionId) {
  final started = DateTime(2026, 8, 15, 9).toUtc().millisecondsSinceEpoch;
  final finished = DateTime(2026, 8, 15, 14).toUtc().millisecondsSinceEpoch;
  return DeliveryRecord(
    sessionId: sessionId,
    startedAtUtcMs: started,
    finishedAtUtcMs: finished,
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
    createdAtUtcMs: finished,
  );
}

class _HomeRepository extends DeliveryRepository {
  _HomeRepository({
    this.month = const [],
    this.week = const [],
    this.monthFuture,
  });

  final List<DeliveryRecord> month;
  final List<DeliveryRecord> week;
  final Future<List<DeliveryRecord>>? monthFuture;

  @override
  Future<DeliveryRecord?> getDeliveryRecordBySessionId(String _) async => null;

  @override
  Future<List<DeliveryRecord>> getDeliveryRecordsForDay(DateTime _) async =>
      const [];

  @override
  Future<List<DeliveryRecord>> getDeliveryRecordsForWeek(DateTime _) async =>
      week;

  @override
  Future<List<DeliveryRecord>> getDeliveryRecordsForMonth(DateTime _) =>
      monthFuture ?? Future.value(month);
}

class _EmptyActiveDeliveryStorage implements ActiveDeliveryStorage {
  @override
  Future<void> clear() async {}

  @override
  Future<DeliverySession?> load() async => null;

  @override
  Future<void> save(DeliverySession value) async {}
}
