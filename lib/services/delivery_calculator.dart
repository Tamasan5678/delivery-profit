class DeliveryTotals {
  const DeliveryTotals({
    this.sales = 0,
    this.deliveryCount = 0,
    this.onlineMinutes = 0,
    this.distanceKm = 0,
    this.fuelUsedLiters = 0,
    this.fuelCostYen = 0,
    this.profitYen = 0,
    this.sessionCount = 0,
  });

  final int sales;
  final int deliveryCount;
  final int onlineMinutes;
  final double distanceKm;
  final double fuelUsedLiters;
  final int fuelCostYen;
  final int profitYen;
  final int sessionCount;
}

class DeliveryMetrics {
  const DeliveryMetrics({
    required this.gasolineLiters,
    required this.gasolineCost,
    required this.profit,
    required this.averageProfitPerDelivery,
    required this.distancePerDelivery,
    required this.minutesPerDelivery,
    required this.gasolinePerDelivery,
    required this.hourlyProfit,
  });

  final double gasolineLiters;
  final int gasolineCost;
  final int profit;
  final double averageProfitPerDelivery;
  final double distancePerDelivery;
  final double minutesPerDelivery;
  final double gasolinePerDelivery;
  final double hourlyProfit;
}

class DeliveryCalculator {
  const DeliveryCalculator._();

  static DeliveryMetrics calculate({
    required DeliveryTotals totals,
    required double averageFuelEfficiencyKmPerLiter,
    required double gasolinePricePerLiter,
  }) {
    final gasolineLiters = averageFuelEfficiencyKmPerLiter > 0
        ? totals.distanceKm / averageFuelEfficiencyKmPerLiter
        : 0.0;
    final gasolineCost = (gasolineLiters * gasolinePricePerLiter).round();
    final profit = totals.sales - gasolineCost;
    final count = totals.deliveryCount;

    return DeliveryMetrics(
      gasolineLiters: gasolineLiters,
      gasolineCost: gasolineCost,
      profit: profit,
      averageProfitPerDelivery: count > 0 ? profit / count : 0,
      distancePerDelivery: count > 0 ? totals.distanceKm / count : 0,
      minutesPerDelivery: count > 0 ? totals.onlineMinutes / count : 0,
      gasolinePerDelivery: count > 0 ? gasolineLiters / count : 0,
      hourlyProfit: totals.onlineMinutes > 0
          ? profit / (totals.onlineMinutes / 60)
          : 0,
    );
  }

  static DeliveryMetrics calculateSavedTotals(DeliveryTotals totals) {
    final count = totals.deliveryCount;
    return DeliveryMetrics(
      gasolineLiters: totals.fuelUsedLiters,
      gasolineCost: totals.fuelCostYen,
      profit: totals.profitYen,
      averageProfitPerDelivery: count > 0 ? totals.profitYen / count : 0,
      distancePerDelivery: count > 0 ? totals.distanceKm / count : 0,
      minutesPerDelivery: count > 0 ? totals.onlineMinutes / count : 0,
      gasolinePerDelivery: count > 0 ? totals.fuelUsedLiters / count : 0,
      hourlyProfit: totals.onlineMinutes > 0
          ? totals.profitYen / (totals.onlineMinutes / 60)
          : 0,
    );
  }
}
