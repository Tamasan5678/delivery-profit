import 'dart:convert';

import 'package:delivery_profit_v2/services/preferences_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('calculation defaults are valid without stored values', () async {
    SharedPreferences.setMockInitialValues({});

    final settings = await PreferencesService.getCalculationSettings();
    expect(settings.fuelEfficiency, 10.0);
    expect(settings.fuelPrice, 170);
    expect(await PreferencesService.hasValidCalculationSettings(), isTrue);
  });

  test('calculation settings are saved as one JSON value', () async {
    final store = _MemoryStore();

    expect(
      await PreferencesService.saveCalculationSettingsToStore(
        store: store,
        averageFuelEfficiency: 12.5,
        gasolinePrice: 200,
      ),
      isTrue,
    );
    expect(store.setStringCalls, 1);
    expect(store.values, hasLength(1));
    expect(
      jsonDecode(
        store.values[PreferencesService.calculationSettingsKey]! as String,
      ),
      {'fuelEfficiency': 12.5, 'fuelPrice': 200},
    );
  });

  test('calculation settings are read from one JSON value', () async {
    final store = _MemoryStore({
      PreferencesService.calculationSettingsKey: jsonEncode({
        'fuelEfficiency': 12.5,
        'fuelPrice': 200,
      }),
    });

    final settings = await PreferencesService.loadCalculationSettingsFromStore(
      store,
    );

    expect(settings.fuelEfficiency, 12.5);
    expect(settings.fuelPrice, 200);
    expect(store.setStringCalls, 0);
  });

  test('legacy keys migrate once to JSON and are removed', () async {
    final store = _MemoryStore({
      PreferencesService.legacyAverageFuelEfficiencyKey: 11.5,
      PreferencesService.legacyGasolinePriceKey: 190,
    });

    final first = await PreferencesService.loadCalculationSettingsFromStore(
      store,
    );
    final second = await PreferencesService.loadCalculationSettingsFromStore(
      store,
    );

    expect(first.fuelEfficiency, 11.5);
    expect(first.fuelPrice, 190);
    expect(second.fuelEfficiency, 11.5);
    expect(second.fuelPrice, 190);
    expect(store.setStringCalls, 1);
    expect(
      store.values,
      isNot(contains(PreferencesService.legacyAverageFuelEfficiencyKey)),
    );
    expect(
      store.values,
      isNot(contains(PreferencesService.legacyGasolinePriceKey)),
    );
  });

  test('failed JSON save leaves legacy settings intact', () async {
    final store = _MemoryStore({
      PreferencesService.legacyAverageFuelEfficiencyKey: 11.5,
      PreferencesService.legacyGasolinePriceKey: 190,
    }, true);

    final settings = await PreferencesService.loadCalculationSettingsFromStore(
      store,
    );

    expect(settings.fuelEfficiency, 11.5);
    expect(settings.fuelPrice, 190);
    expect(
      store.values[PreferencesService.legacyAverageFuelEfficiencyKey],
      11.5,
    );
    expect(store.values[PreferencesService.legacyGasolinePriceKey], 190);
    expect(
      store.values,
      isNot(contains(PreferencesService.calculationSettingsKey)),
    );
  });

  test('failed settings save performs one write and changes nothing', () async {
    final original = jsonEncode({'fuelEfficiency': 10.0, 'fuelPrice': 170});
    final store = _MemoryStore({
      PreferencesService.calculationSettingsKey: original,
    }, true);

    expect(
      await PreferencesService.saveCalculationSettingsToStore(
        store: store,
        averageFuelEfficiency: 12.5,
        gasolinePrice: 200,
      ),
      isFalse,
    );
    expect(store.setStringCalls, 1);
    expect(store.values[PreferencesService.calculationSettingsKey], original);
  });

  test('corrupt JSON falls back to defaults', () async {
    final store = _MemoryStore({
      PreferencesService.calculationSettingsKey: '{broken',
    });

    final settings = await PreferencesService.loadCalculationSettingsFromStore(
      store,
    );

    expect(settings.fuelEfficiency, 10.0);
    expect(settings.fuelPrice, 170);
  });

  test('JSON with missing fields falls back to defaults', () async {
    final store = _MemoryStore({
      PreferencesService.calculationSettingsKey: jsonEncode({
        'fuelEfficiency': 12.5,
      }),
    });

    final settings = await PreferencesService.loadCalculationSettingsFromStore(
      store,
    );

    expect(settings.fuelEfficiency, 10.0);
    expect(settings.fuelPrice, 170);
  });
}

class _MemoryStore implements CalculationSettingsStore {
  _MemoryStore([
    Map<String, Object?> initial = const {},
    this.failWrites = false,
  ]) : values = Map.of(initial);

  final Map<String, Object?> values;
  final bool failWrites;
  int setStringCalls = 0;

  @override
  Object? get(String key) => values[key];

  @override
  Future<bool> remove(String key) async {
    values.remove(key);
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    setStringCalls++;
    if (failWrites) return false;
    values[key] = value;
    return true;
  }
}
