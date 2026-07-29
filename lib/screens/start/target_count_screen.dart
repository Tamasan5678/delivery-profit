import 'package:flutter/material.dart';

import 'weather_screen.dart';
import '../../widgets/greeting_header.dart';
import '../../widgets/info_card.dart';
import '../../widgets/option_button.dart';
import '../../widgets/primary_button.dart';

class TargetCountScreen extends StatelessWidget {
  const TargetCountScreen({
    super.key,
    this.targetCount = 20,
  });

  final int targetCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('目標件数'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const GreetingHeader(),
              const SizedBox(height: 24),
              InfoCard(
                title: '今日の目標件数',
                value: targetCount.toString(),
                unit: '件',
                icon: Icons.flag,
              ),
              const SizedBox(height: 12),
              const Text(
                'ⓘ 前回の目標件数を表示しています。\n違う場合のみ変更してください。',
              ),
              const SizedBox(height: 24),
              OptionButton(
                text: '変更する',
                icon: Icons.edit,
                onPressed: () {
                  // TODO: 件数入力ダイアログを表示
                },
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: '次へ',
                onPressed: () async {
                  final deliveryStart = await Navigator.of(context).push<
                      ({int targetCount, String weather})>(
                    MaterialPageRoute(
                      builder: (_) => WeatherScreen(targetCount: targetCount),
                    ),
                  );

                  if (context.mounted && deliveryStart != null) {
                    Navigator.of(context).pop(deliveryStart);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
