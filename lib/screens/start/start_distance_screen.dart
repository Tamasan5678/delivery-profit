import 'package:flutter/material.dart';

import '../../models/delivery_session.dart';
import '../../repositories/delivery_repository.dart';
import '../../services/preferences_service.dart';
import '../../widgets/greeting_header.dart';
import '../../widgets/info_card.dart';
import '../../widgets/option_button.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/scroll_picker_bottom_sheet.dart';
import 'target_count_screen.dart';

class StartDistanceScreen extends StatefulWidget {
  const StartDistanceScreen({
    super.key,
    this.repository,
    this.loadEndDistance = PreferencesService.getStoredEndDistance,
    this.saveEndDistance = PreferencesService.saveEndDistance,
  });

  final DeliveryRepository? repository;
  final Future<int?> Function() loadEndDistance;
  final Future<bool> Function(int distance) saveEndDistance;

  @override
  State<StartDistanceScreen> createState() => _StartDistanceScreenState();
}

class _StartDistanceScreenState extends State<StartDistanceScreen> {
  int _startDistance = 106620;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _restoreEndDistance();
  }

  Future<void> _restoreEndDistance() async {
    int? distance;
    try {
      distance = await widget.loadEndDistance();
      if (distance == null && widget.repository != null) {
        final records = await widget.repository!.getAllDeliveryRecords();
        if (records.isNotEmpty) {
          final latest = records.first;
          final candidate = latest.startDistanceKm + latest.travelDistanceKm;
          if (candidate.isFinite && candidate >= 0) {
            distance = candidate.round();
            try {
              await widget.saveEndDistance(distance);
            } catch (_) {
              // SQLite remains the recovery source when this cache write fails.
            }
          }
        }
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to restore last end distance: $error\n$stackTrace');
    }
    if (!mounted || distance == null || distance < 0) return;
    setState(() => _startDistance = distance!);
  }

  Future<void> _openDistancePicker() async {
    final value = await ScrollPickerBottomSheet.showDigits(
      context: context,
      title: '開始走行距離',
      unit: 'km',
      currentValue: _startDistance,
    );
    if (value != null && mounted) {
      setState(() => _startDistance = value);
    }
  }

  Future<void> _goNext() async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);
    try {
      final deliveryStart = await Navigator.of(context).push<DeliverySession>(
        MaterialPageRoute(
          builder: (_) =>
              TargetCountScreen(startDistanceKm: _startDistance.toDouble()),
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
      appBar: AppBar(title: const Text('配達開始'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const GreetingHeader(),
              const SizedBox(height: 24),
              InfoCard(
                title: '開始走行距離',
                value: _startDistance.toString(),
                unit: 'km',
                icon: Icons.speed,
              ),
              const SizedBox(height: 12),
              const Text('ⓘ 前回終了走行距離を表示しています。\n違う場合のみ変更してください。'),
              const SizedBox(height: 24),
              OptionButton(
                text: '変更する',
                icon: Icons.edit,
                onPressed: _openDistancePicker,
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
