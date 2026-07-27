import 'package:flutter/material.dart';

/// ===============================================
/// Delivery Profit 共通カラー
/// ===============================================
///
/// アプリ全体で使用する色を管理します。
/// 色を変更する場合は、このファイルだけ修正すれば
/// アプリ全体に反映されます。
///
/// ===============================================

class AppColors {
  AppColors._();

  //==============================
  // メインカラー
  //==============================

  /// メインカラー（Delivery Profit オレンジ）
  static const Color primary = Color(0xFFFF6B00);

  /// サブカラー（濃紺）
  static const Color secondary = Color(0xFF1F2A44);

  //==============================
  // 背景
  //==============================

  /// 画面背景
  static const Color background = Color(0xFFF8F7F5);

  /// カード背景
  static const Color card = Colors.white;

  //==============================
  // テキスト
  //==============================

  /// メイン文字
  static const Color textPrimary = Color(0xFF222222);

  /// サブ文字
  static const Color textSecondary = Color(0xFF777777);

  /// 白文字
  static const Color textWhite = Colors.white;

  //==============================
  // ボタン
  //==============================

  /// メインボタン
  static const Color buttonPrimary = primary;

  /// メインボタン文字
  static const Color buttonPrimaryText = Colors.white;

  /// サブボタン背景
  static const Color buttonSecondary = Colors.white;

  /// サブボタン文字
  static const Color buttonSecondaryText = Color(0xFF222222);

  /// サブボタン枠線
  static const Color buttonBorder = Color(0xFFD0D0D0);

  //==============================
  // カード
  //==============================

  /// カード枠線
  static const Color cardBorder = Color(0xFFE5E5E5);

  /// カード影
  static const Color shadow = Color(0x22000000);

  //==============================
  // ステータス
  //==============================

  /// 成功
  static const Color success = Color(0xFF4CAF50);

  /// 注意
  static const Color warning = Color(0xFFFFB300);

  /// エラー
  static const Color error = Color(0xFFE53935);

  /// 情報
  static const Color info = Color(0xFF2196F3);

  //==============================
  // 天気
  //==============================

  /// 晴れ
  static const Color weatherSunny = Color(0xFFFFC107);

  /// 曇り
  static const Color weatherCloudy = Color(0xFF90A4AE);

  /// 雨
  static const Color weatherRainy = Color(0xFF42A5F5);
}