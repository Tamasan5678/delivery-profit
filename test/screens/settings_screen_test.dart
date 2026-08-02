import 'package:delivery_profit_v2/core/theme/app_theme.dart';
import 'package:delivery_profit_v2/screens/settings/settings_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('failed settings save keeps the displayed value', (tester) async {
    SharedPreferences.setMockInitialValues({
      'average_fuel_efficiency': 10.0,
      'gasoline_price': 170,
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: SettingsScreen(
          saveCalculationSettings:
              ({
                required double averageFuelEfficiency,
                required int gasolinePrice,
              }) async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('平均燃費'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CupertinoPicker), const Offset(0, -100));
    await tester.pumpAndSettle();
    await tester.tap(find.text('決定'));
    await tester.pumpAndSettle();

    expect(find.text('10.0'), findsOneWidget);
    expect(find.text('設定を保存できませんでした'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.get('average_fuel_efficiency'), isNull);
    expect(preferences.get('gasoline_price'), isNull);
    expect(jsonDecode(preferences.getString('calculation_settings')!), {
      'fuelEfficiency': 10.0,
      'fuelPrice': 170,
    });
  });

  testWidgets('rapid confirm saves settings only once', (tester) async {
    SharedPreferences.setMockInitialValues({});
    var saveCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: SettingsScreen(
          saveCalculationSettings:
              ({
                required double averageFuelEfficiency,
                required int gasolinePrice,
              }) async {
                saveCalls++;
                return true;
              },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('平均燃費'));
    await tester.pumpAndSettle();
    final callback = tester
        .widget<TextButton>(find.widgetWithText(TextButton, '決定'))
        .onPressed!;
    callback();
    callback();
    await tester.pumpAndSettle();

    expect(saveCalls, 1);
    expect(tester.takeException(), isNull);
  });
}
