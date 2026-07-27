import 'package:flutter/material.dart';

/// ===============================================
/// Delivery Profit 共通文字スタイル
/// ===============================================
///
/// アプリ全体で使用する文字サイズ・太さを管理します。
///
/// ===============================================

class AppTextStyles {
  AppTextStyles._();

  /// 大タイトル
  static const TextStyle headline = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.bold,
    color: Color(0xFF222222),
  );

  /// タイトル
  static const TextStyle title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Color(0xFF222222),
  );

  /// サブタイトル
  static const TextStyle subtitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Color(0xFF222222),
  );

  /// 通常文字
  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: Color(0xFF222222),
  );

  /// 説明文
  static const TextStyle caption = TextStyle(
    fontSize: 13,
    color: Color(0xFF777777),
  );

  /// カードの大きな数字
  static const TextStyle value = TextStyle(
    fontSize: 42,
    fontWeight: FontWeight.bold,
    color: Color(0xFF1F2A44),
  );

  /// 単位（円・件・kmなど）
  static const TextStyle unit = TextStyle(
    fontSize: 22,
    color: Color(0xFF777777),
  );

  /// メインボタン
  static const TextStyle primaryButton = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  /// サブボタン
  static const TextStyle secondaryButton = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Color(0xFF222222),
  );
}