import 'dart:math';

class DeliverySession {
  const DeliverySession({
    required this.sessionId,
    required this.targetCount,
    required this.weather,
    required this.startDistanceKm,
    required this.startedAtUtcMs,
  });

  final String sessionId;
  final int targetCount;
  final String weather;
  final double startDistanceKm;
  final int startedAtUtcMs;

  static String generateSessionId() {
    final random = Random.secure();
    final randomHex = List.generate(
      4,
      (_) => random.nextInt(0x100000000).toRadixString(16).padLeft(8, '0'),
    ).join();
    final timestamp = DateTime.now()
        .toUtc()
        .microsecondsSinceEpoch
        .toRadixString(16);
    return '$timestamp-$randomHex';
  }
}
