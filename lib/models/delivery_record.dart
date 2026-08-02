class DeliveryRecord {
  DeliveryRecord({
    this.id,
    required this.sessionId,
    required this.startedAtUtcMs,
    required this.finishedAtUtcMs,
    required this.startDistanceKm,
    required this.targetCount,
    required this.weather,
    required this.onlineMinutes,
    required this.salesYen,
    required this.deliveryCount,
    required this.travelDistanceKm,
    required this.fuelEfficiencyKmPerLiter,
    required this.fuelPriceYenPerLiter,
    required this.fuelUsedLiters,
    required this.fuelCostYen,
    required this.profitYen,
    required this.createdAtUtcMs,
  }) {
    validate();
  }

  final int? id;
  final String sessionId;
  final int startedAtUtcMs;
  final int finishedAtUtcMs;
  final double startDistanceKm;
  final int targetCount;
  final String weather;
  final int onlineMinutes;
  final int salesYen;
  final int deliveryCount;
  final double travelDistanceKm;
  final double fuelEfficiencyKmPerLiter;
  final int fuelPriceYenPerLiter;
  final double fuelUsedLiters;
  final int fuelCostYen;
  final int profitYen;
  final int createdAtUtcMs;

  void validate() {
    if (id != null && id! <= 0) {
      throw ArgumentError.value(id, 'id', 'must be positive');
    }
    if (sessionId.trim().isEmpty) {
      throw ArgumentError.value(sessionId, 'sessionId', 'must not be empty');
    }
    if (startedAtUtcMs < 0) {
      throw ArgumentError.value(
        startedAtUtcMs,
        'startedAtUtcMs',
        'must not be negative',
      );
    }
    if (finishedAtUtcMs < startedAtUtcMs) {
      throw ArgumentError.value(
        finishedAtUtcMs,
        'finishedAtUtcMs',
        'must not be earlier than startedAtUtcMs',
      );
    }
    _requireFiniteNonNegative(startDistanceKm, 'startDistanceKm');
    if (targetCount < 0 || targetCount > 99) {
      throw ArgumentError.value(
        targetCount,
        'targetCount',
        'must be between 0 and 99',
      );
    }
    if (weather.trim().isEmpty) {
      throw ArgumentError.value(weather, 'weather', 'must not be empty');
    }
    _requireNonNegative(onlineMinutes, 'onlineMinutes');
    _requireNonNegative(salesYen, 'salesYen');
    _requireNonNegative(deliveryCount, 'deliveryCount');
    _requireFiniteNonNegative(travelDistanceKm, 'travelDistanceKm');
    if (!fuelEfficiencyKmPerLiter.isFinite ||
        fuelEfficiencyKmPerLiter <= 0 ||
        fuelEfficiencyKmPerLiter > 50.0) {
      throw ArgumentError.value(
        fuelEfficiencyKmPerLiter,
        'fuelEfficiencyKmPerLiter',
        'must be finite, greater than 0, and at most 50.0',
      );
    }
    if (fuelPriceYenPerLiter < 100 || fuelPriceYenPerLiter > 300) {
      throw ArgumentError.value(
        fuelPriceYenPerLiter,
        'fuelPriceYenPerLiter',
        'must be between 100 and 300',
      );
    }
    _requireFiniteNonNegative(fuelUsedLiters, 'fuelUsedLiters');
    _requireNonNegative(fuelCostYen, 'fuelCostYen');
    if (profitYen != salesYen - fuelCostYen) {
      throw ArgumentError.value(
        profitYen,
        'profitYen',
        'must equal salesYen - fuelCostYen',
      );
    }
    _requireNonNegative(createdAtUtcMs, 'createdAtUtcMs');
  }

  static void _requireNonNegative(int value, String name) {
    if (value < 0) {
      throw ArgumentError.value(value, name, 'must not be negative');
    }
  }

  static void _requireFiniteNonNegative(double value, String name) {
    if (!value.isFinite || value < 0) {
      throw ArgumentError.value(value, name, 'must be finite and non-negative');
    }
  }

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'session_id': sessionId,
    'started_at_utc_ms': startedAtUtcMs,
    'finished_at_utc_ms': finishedAtUtcMs,
    'start_distance_km': startDistanceKm,
    'target_count': targetCount,
    'weather': weather,
    'online_minutes': onlineMinutes,
    'sales_yen': salesYen,
    'delivery_count': deliveryCount,
    'travel_distance_km': travelDistanceKm,
    'fuel_efficiency_km_per_liter': fuelEfficiencyKmPerLiter,
    'fuel_price_yen_per_liter': fuelPriceYenPerLiter,
    'fuel_used_liters': fuelUsedLiters,
    'fuel_cost_yen': fuelCostYen,
    'profit_yen': profitYen,
    'created_at_utc_ms': createdAtUtcMs,
  };

  factory DeliveryRecord.fromMap(Map<String, Object?> map) {
    return DeliveryRecord(
      id: map['id'] as int?,
      sessionId: map['session_id'] as String,
      startedAtUtcMs: map['started_at_utc_ms'] as int,
      finishedAtUtcMs: map['finished_at_utc_ms'] as int,
      startDistanceKm: (map['start_distance_km'] as num).toDouble(),
      targetCount: map['target_count'] as int,
      weather: map['weather'] as String,
      onlineMinutes: map['online_minutes'] as int,
      salesYen: map['sales_yen'] as int,
      deliveryCount: map['delivery_count'] as int,
      travelDistanceKm: (map['travel_distance_km'] as num).toDouble(),
      fuelEfficiencyKmPerLiter: (map['fuel_efficiency_km_per_liter'] as num)
          .toDouble(),
      fuelPriceYenPerLiter: map['fuel_price_yen_per_liter'] as int,
      fuelUsedLiters: (map['fuel_used_liters'] as num).toDouble(),
      fuelCostYen: map['fuel_cost_yen'] as int,
      profitYen: map['profit_yen'] as int,
      createdAtUtcMs: map['created_at_utc_ms'] as int,
    );
  }

  DeliveryRecord copyWith({int? id}) => DeliveryRecord(
    id: id ?? this.id,
    sessionId: sessionId,
    startedAtUtcMs: startedAtUtcMs,
    finishedAtUtcMs: finishedAtUtcMs,
    startDistanceKm: startDistanceKm,
    targetCount: targetCount,
    weather: weather,
    onlineMinutes: onlineMinutes,
    salesYen: salesYen,
    deliveryCount: deliveryCount,
    travelDistanceKm: travelDistanceKm,
    fuelEfficiencyKmPerLiter: fuelEfficiencyKmPerLiter,
    fuelPriceYenPerLiter: fuelPriceYenPerLiter,
    fuelUsedLiters: fuelUsedLiters,
    fuelCostYen: fuelCostYen,
    profitYen: profitYen,
    createdAtUtcMs: createdAtUtcMs,
  );
}
