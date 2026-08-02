import 'package:delivery_profit_v2/core/theme/app_theme.dart';
import 'package:delivery_profit_v2/screens/start/weather_screen.dart';
import 'package:delivery_profit_v2/widgets/info_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('diagnose two Home cards at 360dp', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: InfoCard(
                    title: '今日の利益',
                    value: '-999,999',
                    unit: '円',
                    icon: Icons.account_balance_wallet,
                    fitValue: true,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: InfoCard(
                    title: '今日の売上',
                    value: '1,000,000',
                    unit: '円',
                    icon: Icons.payments,
                    fitValue: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('diagnose Weather at 360x640 and 2x text', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const WeatherScreen(targetCount: 20, startDistanceKm: 106620),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
