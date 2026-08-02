import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/delivery_record.dart';
import '../../repositories/delivery_repository.dart';
import '../../services/delivery_calculator.dart';

class HistoryDetailScreen extends StatefulWidget {
  const HistoryDetailScreen({super.key, required this.record, this.repository});

  final DeliveryRecord record;
  final DeliveryRepository? repository;

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  late final DeliveryRepository _repository;
  bool _isDeleting = false;
  bool _isDeleteFlowActive = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? DeliveryRepository();
  }

  String _date(DateTime value) => '${value.year}年${value.month}月${value.day}日';
  String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  String _yen(num value) => value.round().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  String _duration(num value, {bool perDelivery = false}) {
    final minutes = value.round();
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    final text = hours == 0
        ? '$rest分'
        : rest == 0
        ? '$hours時間'
        : '$hours時間$rest分';
    return perDelivery ? '$text／件' : text;
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 132,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Text(value, textAlign: TextAlign.end)),
      ],
    ),
  );

  Future<void> _delete() async {
    if (_isDeleteFlowActive || widget.record.id == null) return;
    setState(() => _isDeleteFlowActive = true);
    var isClosingDialog = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('この配達記録を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () {
              if (isClosingDialog) return;
              isClosingDialog = true;
              Navigator.of(context).pop(false);
            },
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              if (isClosingDialog) return;
              isClosingDialog = true;
              Navigator.of(context).pop(true);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('削除する'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed != true) {
      setState(() => _isDeleteFlowActive = false);
      return;
    }
    setState(() => _isDeleting = true);
    try {
      final deleted = await _repository.deleteDeliveryRecord(widget.record.id!);
      if (deleted != 1) throw StateError('Delivery record was not deleted');
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error, stackTrace) {
      debugPrint('Failed to delete delivery record: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _isDeleteFlowActive = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('削除に失敗しました。もう一度お試しください')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final started = DateTime.fromMillisecondsSinceEpoch(
      record.startedAtUtcMs,
      isUtc: true,
    ).toLocal();
    final finished = DateTime.fromMillisecondsSinceEpoch(
      record.finishedAtUtcMs,
      isUtc: true,
    ).toLocal();
    final metrics = DeliveryCalculator.calculateSavedTotals(
      DeliveryTotals(
        sales: record.salesYen,
        deliveryCount: record.deliveryCount,
        onlineMinutes: record.onlineMinutes,
        distanceKm: record.travelDistanceKm,
        fuelUsedLiters: record.fuelUsedLiters,
        fuelCostYen: record.fuelCostYen,
        profitYen: record.profitYen,
        sessionCount: 1,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('履歴詳細')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _row('配達日', _date(finished)),
                      _row('開始日時', '${_date(started)} ${_time(started)}'),
                      _row('終了日時', '${_date(finished)} ${_time(finished)}'),
                      _row('目標件数', '${record.targetCount}件'),
                      _row('天気', record.weather),
                      _row('オンライン時間', _duration(record.onlineMinutes)),
                      _row('売上', '${_yen(record.salesYen)}円'),
                      _row('配達件数', '${record.deliveryCount}件'),
                      _row(
                        '走行距離',
                        '${record.travelDistanceKm.toStringAsFixed(1)}km',
                      ),
                      _row(
                        '平均燃費',
                        '${record.fuelEfficiencyKmPerLiter.toStringAsFixed(1)}km/L',
                      ),
                      _row('ガソリン単価', '${record.fuelPriceYenPerLiter}円/L'),
                      _row(
                        'ガソリン使用量',
                        '${record.fuelUsedLiters.toStringAsFixed(2)}L',
                      ),
                      _row('ガソリン代', '${_yen(record.fuelCostYen)}円'),
                      _row('利益', '${_yen(record.profitYen)}円'),
                      _row('時給', '${_yen(metrics.hourlyProfit)}円／時間'),
                      _row(
                        '平均利益',
                        '${_yen(metrics.averageProfitPerDelivery)}円／件',
                      ),
                      _row(
                        '平均走行距離',
                        '${metrics.distancePerDelivery.toStringAsFixed(1)}km／件',
                      ),
                      _row(
                        '平均配達時間',
                        _duration(
                          metrics.minutesPerDelivery,
                          perDelivery: true,
                        ),
                      ),
                      _row(
                        '平均消費ガソリン',
                        '${metrics.gasolinePerDelivery.toStringAsFixed(2)}L／件',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _isDeleteFlowActive ? null : _delete,
                icon: _isDeleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline),
                label: Text(_isDeleting ? '削除中…' : 'この記録を削除'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
