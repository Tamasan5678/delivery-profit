import 'package:flutter/material.dart';

import '../core/theme/app_text_styles.dart';

class GreetingHeader extends StatelessWidget {
  const GreetingHeader({
    super.key,
    this.logoAssetPath = 'assets/images/logo.png',
    this.logoWidth = 90,
    this.logoBottomSpacing = 24,
    this.greeting,
    this.subtitle,
  });

  final String logoAssetPath;
  final double logoWidth;
  final double logoBottomSpacing;
  final String? greeting;
  final String? subtitle;

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 11) {
      return 'おはようございます！';
    } else if (hour < 18) {
      return 'こんにちは！';
    } else {
      return 'こんばんは！';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        // ロゴ
        Center(
          child: Image.asset(
            logoAssetPath,
            width: logoWidth,
          ),
        ),

        SizedBox(height: logoBottomSpacing),

        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            greeting ?? _getGreeting(),
            style: AppTextStyles.title,
          ),
        ),

        const SizedBox(height: 4),

        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            subtitle ??
                '今日も安全運転でいきましょう😊',
            style: AppTextStyles.caption,
          ),
        ),
      ],
    );
  }
}
