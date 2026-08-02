import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/delivery_record.dart';
import '../../models/finish_input_result.dart';
import '../../services/delivery_calculator.dart';
import '../../widgets/info_card.dart';
import '../../widgets/primary_button.dart';

class DailyResultScreen extends StatefulWidget {
  const DailyResultScreen({
    super.key,
    required this.result,
    required this.record,
  });

  final FinishInputResult result;
  final DeliveryRecord record;

  @override
  State<DailyResultScreen> createState() => _DailyResultScreenState();
}

class _DailyResultScreenState extends State<DailyResultScreen> {
  bool _isReturningHome = false;

  void _returnHome() {
    if (_isReturningHome) return;
    _isReturningHome = true;
    Navigator.of(context).pop();
  }

  String _formatYen(num value) => '${value.round()}'.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );

  String _formatMinutes(double value) {
    final minutes = value.round();
    if (minutes < 60) return '$minutes分／件';
    final remaining = minutes % 60;
    return remaining == 0
        ? '${minutes ~/ 60}時間／件'
        : '${minutes ~/ 60}時間$remaining分／件';
  }

  @override
  Widget build(BuildContext context) {
    final metrics = DeliveryCalculator.calculateSavedTotals(
      DeliveryTotals(
        sales: widget.record.salesYen,
        deliveryCount: widget.record.deliveryCount,
        onlineMinutes: widget.record.onlineMinutes,
        distanceKm: widget.record.travelDistanceKm,
        fuelUsedLiters: widget.record.fuelUsedLiters,
        fuelCostYen: widget.record.fuelCostYen,
        profitYen: widget.record.profitYen,
        sessionCount: 1,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('本日の配達結果'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InfoCard(
                title: '利益',
                value: _formatYen(metrics.profit),
                unit: '円',
                icon: Icons.account_balance_wallet,
                fitValue: true,
              ),
              const SizedBox(height: 12),
              InfoCard(
                title: '時給',
                value: _formatYen(metrics.hourlyProfit),
                unit: '円／時間',
                icon: Icons.schedule,
                fitValue: true,
              ),
              const SizedBox(height: 12),
              InfoCard(
                title: '平均利益／件',
                value: _formatYen(metrics.averageProfitPerDelivery),
                unit: '円／件',
                icon: Icons.trending_up,
                fitValue: true,
              ),
              const SizedBox(height: 12),
              InfoCard(
                title: '平均走行距離／件',
                value: metrics.distancePerDelivery.toStringAsFixed(1),
                unit: 'km／件',
                icon: Icons.route,
                fitValue: true,
              ),
              const SizedBox(height: 12),
              InfoCard(
                title: '平均配達時間／件',
                value: _formatMinutes(metrics.minutesPerDelivery),
                unit: '',
                icon: Icons.timer_outlined,
                fitValue: true,
              ),
              const SizedBox(height: 12),
              InfoCard(
                title: '平均消費ガソリン／件',
                value: metrics.gasolinePerDelivery.toStringAsFixed(2),
                unit: 'L／件',
                icon: Icons.local_gas_station,
                fitValue: true,
              ),
              const SizedBox(height: 24),
              PrimaryButton(text: 'ホームへ戻る', onPressed: _returnHome),
            ],
          ),
        ),
      ),
    );
  }
}
