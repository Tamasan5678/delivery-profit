import 'package:flutter/material.dart';

import '../../models/delivery_session.dart';
import '../../widgets/greeting_header.dart';
import '../../widgets/info_card.dart';
import '../../widgets/option_button.dart';
import '../../widgets/primary_button.dart';
import 'target_count_screen.dart';

class StartDistanceScreen extends StatelessWidget {
  const StartDistanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('配達開始'),
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
              const InfoCard(
                title: '開始走行距離',
                value: '106,620',
                unit: 'km',
                icon: Icons.speed,
              ),
              const SizedBox(height: 12),
              const Text(
                'ⓘ 前回終了走行距離を表示しています。\n違う場合のみ変更してください。',
              ),
              const SizedBox(height: 24),
              OptionButton(
                text: '変更する',
                icon: Icons.edit,
                onPressed: () {
                  // TODO: 入力ダイアログ表示
                },
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                text: '次へ',
                onPressed: () async {
                  final deliveryStart = await Navigator.of(context)
                      .push<DeliverySession>(
                    MaterialPageRoute(
                      builder: (_) => const TargetCountScreen(),
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
