import 'package:flutter/material.dart';

import '../../models/delivery_record.dart';
import '../../models/delivery_session.dart';
import '../../models/finish_input_result.dart';
import '../../repositories/delivery_repository.dart';
import '../../services/active_delivery_storage.dart';
import '../../services/delivery_calculator.dart';
import '../../services/preferences_service.dart';
import 'daily_result_screen.dart';
import '../../widgets/greeting_header.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/scroll_picker_bottom_sheet.dart';

class FinishInputScreen extends StatefulWidget {
  const FinishInputScreen({
    super.key,
    required this.session,
    this.repository,
    this.activeDeliveryStorage,
    this.saveEndDistance = PreferencesService.saveEndDistance,
  });

  final DeliverySession session;
  final DeliveryRepository? repository;
  final ActiveDeliveryStorage? activeDeliveryStorage;
  final Future<bool> Function(int distance) saveEndDistance;

  @override
  State<FinishInputScreen> createState() => _FinishInputScreenState();
}

class _FinishInputScreenState extends State<FinishInputScreen> {
  int _onlineHours = 0;
  int _onlineMinutes = 0;
  int _sales = 0;
  int _deliveryCount = 0;
  int _distance = 0;
  bool _isCompleting = false;
  late final DeliveryRepository _repository;
  late final ActiveDeliveryStorage _activeDeliveryStorage;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? DeliveryRepository();
    _activeDeliveryStorage =
        widget.activeDeliveryStorage ??
        const SharedPreferencesActiveDeliveryStorage();
  }

  Future<void> _completeDelivery() async {
    if (_isCompleting) {
      return;
    }

    setState(() {
      _isCompleting = true;
    });
    try {
      final settings = await PreferencesService.getCalculationSettings();
      final fuelEfficiency = settings.fuelEfficiency;
      final fuelPrice = settings.fuelPrice;
      if (fuelEfficiency <= 0 || fuelPrice <= 0) {
        if (!mounted) return;
        setState(() => _isCompleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('設定画面で平均燃費とガソリン単価を入力してください')),
        );
        return;
      }

      final result = FinishInputResult(
        onlineTime:
            '$_onlineHours:${_onlineMinutes.toString().padLeft(2, '0')}',
        sales: _sales,
        deliveryCount: _deliveryCount,
        distance: _distance,
      );
      final onlineMinutes = _onlineHours * 60 + _onlineMinutes;
      final metrics = DeliveryCalculator.calculate(
        totals: DeliveryTotals(
          sales: _sales,
          deliveryCount: _deliveryCount,
          onlineMinutes: onlineMinutes,
          distanceKm: _distance.toDouble(),
        ),
        averageFuelEfficiencyKmPerLiter: fuelEfficiency,
        gasolinePricePerLiter: fuelPrice.toDouble(),
      );
      final finishedAtUtcMs = DateTime.now().toUtc().millisecondsSinceEpoch;
      final record = DeliveryRecord(
        sessionId: widget.session.sessionId,
        startedAtUtcMs: widget.session.startedAtUtcMs,
        finishedAtUtcMs: finishedAtUtcMs,
        startDistanceKm: widget.session.startDistanceKm,
        targetCount: widget.session.targetCount,
        weather: widget.session.weather,
        onlineMinutes: onlineMinutes,
        salesYen: _sales,
        deliveryCount: _deliveryCount,
        travelDistanceKm: _distance.toDouble(),
        fuelEfficiencyKmPerLiter: fuelEfficiency,
        fuelPriceYenPerLiter: fuelPrice,
        fuelUsedLiters: metrics.gasolineLiters,
        fuelCostYen: metrics.gasolineCost,
        profitYen: metrics.profit,
        createdAtUtcMs: finishedAtUtcMs,
      );
      await _repository.insertDeliveryRecord(record);
      final savedRecord =
          await _repository.getDeliveryRecordBySessionId(record.sessionId) ??
          record;
      final endDistance =
          savedRecord.startDistanceKm + savedRecord.travelDistanceKm;
      if (endDistance.isFinite &&
          endDistance >= savedRecord.startDistanceKm &&
          endDistance >= 0) {
        try {
          final saved = await widget.saveEndDistance(endDistance.round());
          if (!saved) {
            debugPrint('Failed to cache last end distance');
          }
        } catch (error, stackTrace) {
          debugPrint('Failed to cache last end distance: $error\n$stackTrace');
        }
      }
      try {
        await _activeDeliveryStorage.clear();
      } catch (error, stackTrace) {
        debugPrint(
          'Failed to clear saved active delivery: $error\n$stackTrace',
        );
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement<void, FinishInputResult>(
        MaterialPageRoute(
          builder: (_) => DailyResultScreen(result: result, record: record),
        ),
        result: result,
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to save delivery record: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _isCompleting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('保存に失敗しました。もう一度お試しください')));
    }
  }

  Future<void> _selectOnlineTime() async {
    final value = await ScrollPickerBottomSheet.showDuration(
      context: context,
      currentHours: _onlineHours,
      currentMinutes: _onlineMinutes,
    );
    if (value != null && mounted) {
      setState(() {
        _onlineHours = value.hours;
        _onlineMinutes = value.minutes;
      });
    }
  }

  Future<void> _selectSales() async {
    final value = await ScrollPickerBottomSheet.showDigits(
      context: context,
      title: '今日の売上',
      unit: '円',
      currentValue: _sales,
      dimLeadingZeros: true,
      digitGroupSize: 3,
    );
    if (value != null && mounted) {
      setState(() => _sales = value);
    }
  }

  Future<void> _selectDeliveryCount() async {
    final value = await ScrollPickerBottomSheet.showDigits(
      context: context,
      title: '配達件数',
      unit: '件',
      currentValue: _deliveryCount,
      digitCount: 2,
    );
    if (value != null && mounted) {
      setState(() => _deliveryCount = value);
    }
  }

  Future<void> _selectDistance() async {
    final value = await ScrollPickerBottomSheet.showDigits(
      context: context,
      title: '走行距離',
      unit: 'km',
      currentValue: _distance,
    );
    if (value != null && mounted) {
      setState(() => _distance = value);
    }
  }

  Widget inputField(String label, String value, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.arrow_drop_down),
          ),
          child: Text(value),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('配達終了'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const GreetingHeader(
                greeting: 'お疲れさまでした！',
                subtitle: '本日も安全運転ありがとうございました',
              ),
              const SizedBox(height: 24),
              inputField(
                'オンライン時間',
                '$_onlineHours時間${_onlineMinutes.toString().padLeft(2, '0')}分',
                _selectOnlineTime,
              ),
              inputField('今日の売上（円）', '$_sales', _selectSales),
              inputField('配達件数', '$_deliveryCount', _selectDeliveryCount),
              inputField('走行距離（km）', '$_distance', _selectDistance),
              const SizedBox(height: 12),
              PrimaryButton(text: '保存する', onPressed: _completeDelivery),
            ],
          ),
        ),
      ),
    );
  }
}
