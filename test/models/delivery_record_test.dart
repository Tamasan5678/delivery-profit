import 'package:delivery_profit_v2/models/delivery_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toMap and fromMap preserve a delivery record', () {
    final record = DeliveryRecord(
      id: 7,
      sessionId: 'session-7',
      startedAtUtcMs: 1000,
      finishedAtUtcMs: 2000,
      startDistanceKm: 106620.5,
      targetCount: 20,
      weather: '晴れ',
      onlineMinutes: 390,
      salesYen: 10000,
      deliveryCount: 15,
      travelDistanceKm: 48.7,
      fuelEfficiencyKmPerLiter: 12.5,
      fuelPriceYenPerLiter: 170,
      fuelUsedLiters: 3.896,
      fuelCostYen: 662,
      profitYen: 9338,
      createdAtUtcMs: 2000,
    );

    final restored = DeliveryRecord.fromMap(record.toMap());

    expect(restored.id, record.id);
    expect(restored.sessionId, record.sessionId);
    expect(restored.startedAtUtcMs, record.startedAtUtcMs);
    expect(restored.finishedAtUtcMs, record.finishedAtUtcMs);
    expect(restored.startDistanceKm, record.startDistanceKm);
    expect(restored.targetCount, record.targetCount);
    expect(restored.weather, record.weather);
    expect(restored.onlineMinutes, record.onlineMinutes);
    expect(restored.salesYen, record.salesYen);
    expect(restored.deliveryCount, record.deliveryCount);
    expect(restored.travelDistanceKm, record.travelDistanceKm);
    expect(restored.fuelEfficiencyKmPerLiter, record.fuelEfficiencyKmPerLiter);
    expect(restored.fuelPriceYenPerLiter, record.fuelPriceYenPerLiter);
    expect(restored.fuelUsedLiters, record.fuelUsedLiters);
    expect(restored.fuelCostYen, record.fuelCostYen);
    expect(restored.profitYen, record.profitYen);
    expect(restored.createdAtUtcMs, record.createdAtUtcMs);
  });

  test('copyWith can attach an inserted id', () {
    final record = DeliveryRecord(
      sessionId: 'session-1',
      startedAtUtcMs: 1000,
      finishedAtUtcMs: 2000,
      startDistanceKm: 1.5,
      targetCount: 1,
      weather: '雨',
      onlineMinutes: 30,
      salesYen: 1000,
      deliveryCount: 1,
      travelDistanceKm: 2.5,
      fuelEfficiencyKmPerLiter: 10.0,
      fuelPriceYenPerLiter: 170,
      fuelUsedLiters: 0.25,
      fuelCostYen: 43,
      profitYen: 957,
      createdAtUtcMs: 2000,
    );

    expect(record.copyWith(id: 1).id, 1);
  });

  test('rejects an empty session ID', () {
    expect(() => _record(sessionId: '  '), throwsArgumentError);
  });

  test('rejects negative values', () {
    expect(() => _record(salesYen: -1, profitYen: -171), throwsArgumentError);
    expect(() => _record(deliveryCount: -1), throwsArgumentError);
    expect(() => _record(onlineMinutes: -1), throwsArgumentError);
    expect(() => _record(travelDistanceKm: -1), throwsArgumentError);
    expect(
      () => _record(fuelCostYen: -1, profitYen: 1001),
      throwsArgumentError,
    );
  });

  test('rejects NaN and infinity', () {
    expect(() => _record(travelDistanceKm: double.nan), throwsArgumentError);
    expect(() => _record(fuelUsedLiters: double.infinity), throwsArgumentError);
  });

  test('rejects a finish time before the start time', () {
    expect(
      () => _record(startedAtUtcMs: 2001, finishedAtUtcMs: 2000),
      throwsArgumentError,
    );
  });

  test('rejects profit that does not equal sales minus fuel cost', () {
    expect(() => _record(profitYen: 999), throwsArgumentError);
  });
}

DeliveryRecord _record({
  String sessionId = 'session',
  int startedAtUtcMs = 1000,
  int finishedAtUtcMs = 2000,
  int onlineMinutes = 60,
  int salesYen = 1000,
  int deliveryCount = 1,
  double travelDistanceKm = 10,
  double fuelUsedLiters = 1,
  int fuelCostYen = 170,
  int profitYen = 830,
}) => DeliveryRecord(
  sessionId: sessionId,
  startedAtUtcMs: startedAtUtcMs,
  finishedAtUtcMs: finishedAtUtcMs,
  startDistanceKm: 100,
  targetCount: 20,
  weather: '晴れ',
  onlineMinutes: onlineMinutes,
  salesYen: salesYen,
  deliveryCount: deliveryCount,
  travelDistanceKm: travelDistanceKm,
  fuelEfficiencyKmPerLiter: 10,
  fuelPriceYenPerLiter: 170,
  fuelUsedLiters: fuelUsedLiters,
  fuelCostYen: fuelCostYen,
  profitYen: profitYen,
  createdAtUtcMs: finishedAtUtcMs,
);
