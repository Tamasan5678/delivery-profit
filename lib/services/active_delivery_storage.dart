import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/delivery_session.dart';

abstract class ActiveDeliveryStorage {
  Future<void> save(DeliverySession session);
  Future<DeliverySession?> load();
  Future<void> clear();
}

class SharedPreferencesActiveDeliveryStorage implements ActiveDeliveryStorage {
  const SharedPreferencesActiveDeliveryStorage();

  static const activeKey = 'active_delivery_is_active';
  static const sessionIdKey = 'active_delivery_session_id';
  static const startedAtUtcMsKey = 'active_delivery_started_at_utc_ms';
  static const startDistanceKmKey = 'active_delivery_start_distance_km';
  static const targetCountKey = 'active_delivery_target_count';
  static const weatherKey = 'active_delivery_weather';

  @override
  Future<void> save(DeliverySession session) async {
    final prefs = await SharedPreferences.getInstance();
    final valuesSaved = await Future.wait([
      prefs.setString(sessionIdKey, session.sessionId),
      prefs.setInt(startedAtUtcMsKey, session.startedAtUtcMs),
      prefs.setDouble(startDistanceKmKey, session.startDistanceKm),
      prefs.setInt(targetCountKey, session.targetCount),
      prefs.setString(weatherKey, session.weather),
    ]);
    if (valuesSaved.any((saved) => !saved) ||
        !await prefs.setBool(activeKey, true)) {
      throw StateError('Active delivery could not be saved');
    }
  }

  @override
  Future<DeliverySession?> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(activeKey) != true) return null;

    final storedSessionId = prefs.get(sessionIdKey);
    final startedAtUtcMs = prefs.get(startedAtUtcMsKey);
    final startDistanceKm = prefs.get(startDistanceKmKey);
    final targetCount = prefs.get(targetCountKey);
    final weather = prefs.get(weatherKey);
    final nowUtcMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    final sessionId =
        storedSessionId is String && storedSessionId.trim().isNotEmpty
        ? storedSessionId.trim()
        : startedAtUtcMs is int && startedAtUtcMs > 0
        ? 'legacy-$startedAtUtcMs'
        : null;
    final isValid =
        sessionId != null &&
        startedAtUtcMs is int &&
        startedAtUtcMs > 0 &&
        startedAtUtcMs <= nowUtcMs &&
        startDistanceKm is num &&
        startDistanceKm.toDouble().isFinite &&
        startDistanceKm >= 0 &&
        targetCount is int &&
        targetCount >= 0 &&
        weather is String &&
        weather.trim().isNotEmpty;
    if (!isValid) {
      try {
        await clear();
      } catch (error, stackTrace) {
        debugPrint(
          'Failed to clear invalid active delivery: $error\n$stackTrace',
        );
      }
      return null;
    }
    final validSessionId = sessionId;

    if (storedSessionId is! String || storedSessionId.trim().isEmpty) {
      final saved = await prefs.setString(sessionIdKey, validSessionId);
      if (!saved) {
        debugPrint('Failed to persist a legacy active delivery session ID');
      }
    }

    return DeliverySession(
      sessionId: validSessionId,
      targetCount: targetCount,
      weather: weather.trim(),
      startDistanceKm: startDistanceKm.toDouble(),
      startedAtUtcMs: startedAtUtcMs,
    );
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    // Mark inactive first so partially removed data is never restored.
    final inactiveSaved = await prefs.setBool(activeKey, false);
    final valuesRemoved = await Future.wait([
      prefs.remove(sessionIdKey),
      prefs.remove(startedAtUtcMsKey),
      prefs.remove(startDistanceKmKey),
      prefs.remove(targetCountKey),
      prefs.remove(weatherKey),
    ]);
    if (!inactiveSaved || valuesRemoved.any((removed) => !removed)) {
      throw StateError('Active delivery could not be cleared');
    }
  }
}
