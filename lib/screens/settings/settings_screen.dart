import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../services/preferences_service.dart';
import '../../widgets/info_card.dart';
import '../../widgets/scroll_picker_bottom_sheet.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    this.saveCalculationSettings = PreferencesService.saveCalculationSettings,
  });

  final Future<bool> Function({
    required double averageFuelEfficiency,
    required int gasolinePrice,
  })
  saveCalculationSettings;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _averageFuelEfficiency =
      PreferencesService.defaultAverageFuelEfficiency;
  int _gasolinePrice = PreferencesService.defaultGasolinePrice;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await PreferencesService.getCalculationSettings();
    if (!mounted) return;
    setState(() {
      _averageFuelEfficiency = settings.fuelEfficiency;
      _gasolinePrice = settings.fuelPrice;
    });
  }

  Future<void> _selectFuelEfficiency() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final value = await ScrollPickerBottomSheet.showNumber(
        context: context,
        title: '平均燃費',
        unit: 'km/L',
        min: 10,
        max: 500,
        step: 1,
        currentValue: (_averageFuelEfficiency * 10).round(),
        labelBuilder: (value) => (value / 10).toStringAsFixed(1),
      );
      if (value == null || !mounted) return;
      final fuelEfficiency = value / 10;
      try {
        final saved = await widget.saveCalculationSettings(
          averageFuelEfficiency: fuelEfficiency,
          gasolinePrice: _gasolinePrice,
        );
        if (!mounted) return;
        if (!saved) {
          _showSaveError();
          return;
        }
        setState(() => _averageFuelEfficiency = fuelEfficiency);
      } catch (_) {
        if (mounted) _showSaveError();
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _selectGasolinePrice() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final value = await ScrollPickerBottomSheet.showNumber(
        context: context,
        title: 'ガソリン単価',
        unit: '円/L',
        min: 100,
        max: 300,
        step: 1,
        currentValue: _gasolinePrice,
      );
      if (value == null || !mounted) return;
      try {
        final saved = await widget.saveCalculationSettings(
          averageFuelEfficiency: _averageFuelEfficiency,
          gasolinePrice: value,
        );
        if (!mounted) return;
        if (!saved) {
          _showSaveError();
          return;
        }
        setState(() => _gasolinePrice = value);
      } catch (_) {
        if (mounted) _showSaveError();
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSaveError() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('設定を保存できませんでした')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('設定')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('車両設定', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              InfoCard(
                title: '平均燃費',
                value: _averageFuelEfficiency.toStringAsFixed(1),
                unit: 'km/L',
                icon: Icons.local_gas_station_outlined,
                onTap: _isSaving ? null : _selectFuelEfficiency,
                fitValue: true,
              ),
              const SizedBox(height: 12),
              InfoCard(
                title: 'ガソリン単価',
                value: _gasolinePrice.toString(),
                unit: '円/L',
                icon: Icons.payments_outlined,
                onTap: _isSaving ? null : _selectGasolinePrice,
                fitValue: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
