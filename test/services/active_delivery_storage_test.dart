import 'package:delivery_profit_v2/models/delivery_session.dart';
import 'package:delivery_profit_v2/services/active_delivery_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('saves, restores, and clears an active delivery', () async {
    const storage = SharedPreferencesActiveDeliveryStorage();
    final startedAt = DateTime.now().toUtc().millisecondsSinceEpoch - 1000;
    final session = DeliverySession(
      sessionId: 'session-active',
      targetCount: 20,
      weather: '晴れ',
      startDistanceKm: 123.4,
      startedAtUtcMs: startedAt,
    );

    await storage.save(session);
    final restored = await storage.load();
    expect(restored?.sessionId, 'session-active');
    expect(restored?.startedAtUtcMs, startedAt);
    expect(restored?.startDistanceKm, 123.4);
    expect(restored?.targetCount, 20);
    expect(restored?.weather, '晴れ');

    await storage.clear();
    expect(await storage.load(), isNull);
  });

  test('incomplete active delivery data is rejected and cleared', () async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesActiveDeliveryStorage.activeKey: true,
      SharedPreferencesActiveDeliveryStorage.targetCountKey: 20,
    });
    const storage = SharedPreferencesActiveDeliveryStorage();

    expect(await storage.load(), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getBool(SharedPreferencesActiveDeliveryStorage.activeKey),
      isFalse,
    );
  });

  test('legacy active delivery receives a stable session ID', () async {
    final startedAt = DateTime.now().toUtc().millisecondsSinceEpoch - 1000;
    SharedPreferences.setMockInitialValues({
      SharedPreferencesActiveDeliveryStorage.activeKey: true,
      SharedPreferencesActiveDeliveryStorage.startedAtUtcMsKey: startedAt,
      SharedPreferencesActiveDeliveryStorage.startDistanceKmKey: 123.4,
      SharedPreferencesActiveDeliveryStorage.targetCountKey: 20,
      SharedPreferencesActiveDeliveryStorage.weatherKey: '晴れ',
    });
    const storage = SharedPreferencesActiveDeliveryStorage();

    final first = await storage.load();
    final second = await storage.load();

    expect(first?.sessionId, 'legacy-$startedAt');
    expect(second?.sessionId, first?.sessionId);
  });
}
