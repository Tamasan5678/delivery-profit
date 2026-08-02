import 'package:delivery_profit_v2/services/delivery_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rounds fuel cost first and derives profit from the saved cost', () {
    final metrics = DeliveryCalculator.calculate(
      totals: const DeliveryTotals(sales: 100, distanceKm: 1),
      averageFuelEfficiencyKmPerLiter: 2,
      gasolinePricePerLiter: 101,
    );

    expect(metrics.gasolineLiters, 0.5);
    expect(metrics.gasolineCost, 51);
    expect(metrics.profit, 49);
    expect(metrics.profit, 100 - metrics.gasolineCost);
  });

  test('saved totals use saved fuel cost and profit without recalculation', () {
    final metrics = DeliveryCalculator.calculateSavedTotals(
      const DeliveryTotals(sales: 1000, fuelCostYen: 171, profitYen: 829),
    );

    expect(metrics.gasolineCost, 171);
    expect(metrics.profit, 829);
  });

  test('saved totals return zero hourly profit when online time is zero', () {
    final metrics = DeliveryCalculator.calculateSavedTotals(
      const DeliveryTotals(profitYen: 1000),
    );
    expect(metrics.hourlyProfit, 0);
  });

  test('saved totals return zero averages when delivery count is zero', () {
    final metrics = DeliveryCalculator.calculateSavedTotals(
      const DeliveryTotals(
        profitYen: 1000,
        distanceKm: 10,
        onlineMinutes: 60,
        fuelUsedLiters: 1,
      ),
    );
    expect(metrics.averageProfitPerDelivery, 0);
    expect(metrics.distancePerDelivery, 0);
    expect(metrics.minutesPerDelivery, 0);
    expect(metrics.gasolinePerDelivery, 0);
  });
}
