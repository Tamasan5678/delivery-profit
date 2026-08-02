import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/delivery_record.dart';
import '../../repositories/delivery_repository.dart';
import 'history_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.repository});

  final DeliveryRepository? repository;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final DeliveryRepository _repository;
  List<DeliveryRecord> _records = const [];
  bool _isLoading = true;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? DeliveryRepository();
    _loadRecords();
  }

  Future<void> _openDetail(DeliveryRecord record) async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);
    try {
      final deleted = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) =>
              HistoryDetailScreen(record: record, repository: _repository),
        ),
      );
      if (!mounted || deleted != true) return;
      await _loadRecords();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('配達記録を削除しました')));
    } finally {
      if (mounted) setState(() => _isNavigating = false);
    }
  }

  Future<void> _loadRecords() async {
    try {
      final records = await _repository.getAllDeliveryRecords();
      if (!mounted) return;
      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to load delivery history: $error\n$stackTrace');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('履歴の読み込みに失敗しました')));
    }
  }

  String _date(DateTime value) => '${value.year}年${value.month}月${value.day}日';
  String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  String _yen(int value) => value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  String _duration(int minutes) {
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    if (hours == 0) return '$rest分';
    return rest == 0 ? '$hours時間' : '$hours時間$rest分';
  }

  Widget _recordCard(DeliveryRecord record) {
    final started = DateTime.fromMillisecondsSinceEpoch(
      record.startedAtUtcMs,
      isUtc: true,
    ).toLocal();
    final finished = DateTime.fromMillisecondsSinceEpoch(
      record.finishedAtUtcMs,
      isUtc: true,
    ).toLocal();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openDetail(record),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _date(finished),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Text('開始 ${_time(started)}　終了 ${_time(finished)}'),
              const Divider(height: 24),
              Text('売上 ${_yen(record.salesYen)}円'),
              Text('利益 ${_yen(record.profitYen)}円'),
              Text('${record.deliveryCount}件'),
              Text(_duration(record.onlineMinutes)),
              Text('${record.travelDistanceKm.toStringAsFixed(1)}km'),
              Text(record.weather),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('履歴')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _records.isEmpty
            ? const Center(child: Text('配達履歴はまだありません'))
            : RefreshIndicator(
                onRefresh: _loadRecords,
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _records.length,
                  itemBuilder: (_, index) => _recordCard(_records[index]),
                ),
              ),
      ),
    );
  }
}
