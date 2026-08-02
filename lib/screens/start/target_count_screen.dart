import 'package:flutter/material.dart';

import '../../models/delivery_session.dart';
import '../../widgets/greeting_header.dart';
import '../../widgets/info_card.dart';
import '../../widgets/option_button.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/scroll_picker_bottom_sheet.dart';
import 'weather_screen.dart';

class TargetCountScreen extends StatefulWidget {
  const TargetCountScreen({
    super.key,
    required this.startDistanceKm,
    this.targetCount = 20,
  });

  final double startDistanceKm;
  final int targetCount;

  @override
  State<TargetCountScreen> createState() => _TargetCountScreenState();
}

class _TargetCountScreenState extends State<TargetCountScreen> {
  late int _targetCount;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _targetCount = widget.targetCount.clamp(0, 99).toInt();
  }

  Future<void> _goNext() async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);
    try {
      final deliveryStart = await Navigator.of(context).push<DeliverySession>(
        MaterialPageRoute(
          builder: (_) => WeatherScreen(
            targetCount: _targetCount,
            startDistanceKm: widget.startDistanceKm,
          ),
        ),
      );
      if (mounted && deliveryStart != null) {
        Navigator.of(context).pop(deliveryStart);
      }
    } finally {
      if (mounted) setState(() => _isNavigating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('目標件数'), centerTitle: true),
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
                value: _targetCount.toString(),
                unit: '件',
                icon: Icons.flag,
              ),
              const SizedBox(height: 12),
              const Text('ⓘ 前回の目標件数を表示しています。\n違う場合のみ変更してください。'),
              const SizedBox(height: 24),
              OptionButton(
                text: '変更する',
                icon: Icons.edit,
                onPressed: () async {
                  final value = await ScrollPickerBottomSheet.showDigits(
                    context: context,
                    title: '目標件数',
                    unit: '件',
                    currentValue: _targetCount,
                    digitCount: 2,
                  );
                  if (value != null && mounted) {
                    setState(() => _targetCount = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              PrimaryButton(text: '次へ', onPressed: _goNext),
            ],
          ),
        ),
      ),
    );
  }
}
