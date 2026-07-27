import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  // ===========================
  // キー定義
  // ===========================

  static const String _startDistanceKey = 'start_distance';
  static const String _endDistanceKey = 'end_distance';
  static const String _targetCountKey = 'target_count';
  static const String _targetSalesKey = 'target_sales';

  // ===========================
  // 開始走行距離
  // ===========================

  static Future<void> saveStartDistance(int distance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_startDistanceKey, distance);
  }

  static Future<int> getStartDistance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_startDistanceKey) ?? 0;
  }

  // ===========================
  // 終了走行距離
  // ===========================

  static Future<void> saveEndDistance(int distance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_endDistanceKey, distance);
  }

  static Future<int> getEndDistance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_endDistanceKey) ?? 0;
  }

  // ===========================
  // 目標件数
  // ===========================

  static Future<void> saveTargetCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_targetCountKey, count);
  }

  static Future<int> getTargetCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_targetCountKey) ?? 20;
  }

  // ===========================
  // 目標売上
  // ===========================

  static Future<void> saveTargetSales(int sales) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_targetSalesKey, sales);
  }

  static Future<int> getTargetSales() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_targetSalesKey) ?? 10000;
  }
}