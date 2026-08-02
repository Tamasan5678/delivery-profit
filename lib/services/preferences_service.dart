import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/calculation_settings.dart';

abstract class CalculationSettingsStore {
  Object? get(String key);
  Future<bool> setString(String key, String value);
  Future<bool> remove(String key);
}

class SharedPreferencesCalculationSettingsStore
    implements CalculationSettingsStore {
  const SharedPreferencesCalculationSettingsStore(this.preferences);

  final SharedPreferences preferences;

  @override
  Object? get(String key) => preferences.get(key);

  @override
  Future<bool> remove(String key) => preferences.remove(key);

  @override
  Future<bool> setString(String key, String value) =>
      preferences.setString(key, value);
}

class PreferencesService {
  static const String _startDistanceKey = 'start_distance';
  static const String _endDistanceKey = 'end_distance';
  static const String _targetCountKey = 'target_count';
  static const String _targetSalesKey = 'target_sales';

  static const String calculationSettingsKey = 'calculation_settings';
  static const String legacyAverageFuelEfficiencyKey =
      'average_fuel_efficiency';
  static const String legacyGasolinePriceKey = 'gasoline_price';

  static const double defaultAverageFuelEfficiency = 10.0;
  static const int defaultGasolinePrice = 170;

  static CalculationSettings get defaultCalculationSettings =>
      CalculationSettings(
        fuelEfficiency: defaultAverageFuelEfficiency,
        fuelPrice: defaultGasolinePrice,
      );

  static Future<void> saveStartDistance(int distance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_startDistanceKey, distance);
  }

  static Future<int> getStartDistance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_startDistanceKey) ?? 0;
  }

  static Future<bool> saveEndDistance(int distance) async {
    if (distance < 0) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.setInt(_endDistanceKey, distance);
  }

  static Future<int> getEndDistance() async {
    return await getStoredEndDistance() ?? 0;
  }

  static Future<int?> getStoredEndDistance() async {
    final prefs = await SharedPreferences.getInstance();
    final distance = prefs.getInt(_endDistanceKey);
    return distance != null && distance >= 0 ? distance : null;
  }

  static Future<void> saveTargetCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_targetCountKey, count);
  }

  static Future<int> getTargetCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_targetCountKey) ?? 20;
  }

  static Future<void> saveTargetSales(int sales) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_targetSalesKey, sales);
  }

  static Future<int> getTargetSales() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_targetSalesKey) ?? 10000;
  }

  static Future<CalculationSettings> getCalculationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return loadCalculationSettingsFromStore(
      SharedPreferencesCalculationSettingsStore(prefs),
    );
  }

  static Future<CalculationSettings> loadCalculationSettingsFromStore(
    CalculationSettingsStore store,
  ) async {
    final storedJson = store.get(calculationSettingsKey);
    if (storedJson != null) {
      if (storedJson is! String) return defaultCalculationSettings;
      return _decodeSettings(storedJson) ?? defaultCalculationSettings;
    }

    final legacyFuelEfficiency = store.get(legacyAverageFuelEfficiencyKey);
    final legacyGasolinePrice = store.get(legacyGasolinePriceKey);
    if (legacyFuelEfficiency is! num || legacyGasolinePrice is! int) {
      return defaultCalculationSettings;
    }

    CalculationSettings legacySettings;
    try {
      legacySettings = CalculationSettings(
        fuelEfficiency: legacyFuelEfficiency.toDouble(),
        fuelPrice: legacyGasolinePrice,
      );
    } on ArgumentError {
      return defaultCalculationSettings;
    }

    bool migrated;
    try {
      migrated = await store.setString(
        calculationSettingsKey,
        jsonEncode(legacySettings.toJson()),
      );
    } catch (_) {
      migrated = false;
    }
    if (migrated) {
      try {
        await Future.wait([
          store.remove(legacyAverageFuelEfficiencyKey),
          store.remove(legacyGasolinePriceKey),
        ]);
      } catch (_) {
        // Do not fail loading after the authoritative JSON write succeeded.
      }
    }
    return legacySettings;
  }

  static CalculationSettings? _decodeSettings(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map<String, dynamic>) return null;
      return CalculationSettings.fromJson(decoded);
    } on FormatException {
      return null;
    } on ArgumentError {
      return null;
    }
  }

  static Future<bool> saveCalculationSettings({
    required double averageFuelEfficiency,
    required int gasolinePrice,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return saveCalculationSettingsToStore(
      store: SharedPreferencesCalculationSettingsStore(prefs),
      averageFuelEfficiency: averageFuelEfficiency,
      gasolinePrice: gasolinePrice,
    );
  }

  static Future<bool> saveCalculationSettingsToStore({
    required CalculationSettingsStore store,
    required double averageFuelEfficiency,
    required int gasolinePrice,
  }) async {
    final settings = CalculationSettings(
      fuelEfficiency: averageFuelEfficiency,
      fuelPrice: gasolinePrice,
    );
    return store.setString(
      calculationSettingsKey,
      jsonEncode(settings.toJson()),
    );
  }

  static Future<double> getAverageFuelEfficiency() async =>
      (await getCalculationSettings()).fuelEfficiency;

  static Future<int> getGasolinePrice() async =>
      (await getCalculationSettings()).fuelPrice;

  static Future<bool> hasValidCalculationSettings() async {
    final settings = await getCalculationSettings();
    try {
      settings.validate();
      return true;
    } on ArgumentError {
      return false;
    }
  }
}
