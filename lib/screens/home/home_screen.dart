import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/delivery_record.dart';
import '../../models/delivery_session.dart';
import '../../models/finish_input_result.dart';
import '../../repositories/delivery_repository.dart';
import '../../services/delivery_calculator.dart';
import '../../services/active_delivery_storage.dart';
import '../../widgets/greeting_header.dart';
import '../../widgets/info_card.dart';
import '../../widgets/option_button.dart';
import '../../widgets/primary_button.dart';
import '../finish/finish_input_screen.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';
import '../start/start_distance_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.repository, this.activeDeliveryStorage});

  final DeliveryRepository? repository;
  final ActiveDeliveryStorage? activeDeliveryStorage;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final DeliveryRepository _repository;
  late final ActiveDeliveryStorage _activeDeliveryStorage;
  int _selectedIndex = 0;
  bool _isDelivering = false;
  bool _isLoading = true;
  bool _isInitializing = true;
  DeliverySession? _deliverySession;
  _SummaryPeriod _summaryPeriod = _SummaryPeriod.day;
  DeliveryTotals _totals = const DeliveryTotals();
  DeliveryTotals _todayTotals = const DeliveryTotals();
  int _summaryRequestGeneration = 0;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? DeliveryRepository();
    _activeDeliveryStorage =
        widget.activeDeliveryStorage ??
        const SharedPreferencesActiveDeliveryStorage();
    _initialize();
  }

  Future<void> _initialize() async {
    DeliverySession? session;
    try {
      session = await _activeDeliveryStorage.load();
      if (session != null) {
        final saved = await _repository.getDeliveryRecordBySessionId(
          session.sessionId,
        );
        if (saved != null) {
          session = null;
          try {
            await _activeDeliveryStorage.clear();
          } catch (error, stackTrace) {
            debugPrint(
              'Failed to clear already saved active delivery: '
              '$error\n$stackTrace',
            );
          }
        }
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to restore active delivery: $error\n$stackTrace');
      session = null;
    }
    await _loadSummary();
    if (!mounted) return;
    setState(() {
      _deliverySession = session;
      _isDelivering = session != null;
      _isInitializing = false;
    });
  }

  Future<void> _loadSummary() async {
    final requestGeneration = ++_summaryRequestGeneration;
    final requestedPeriod = _summaryPeriod;
    if (mounted) setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final recordsFuture = switch (requestedPeriod) {
        _SummaryPeriod.day => _repository.getDeliveryRecordsForDay(now),
        _SummaryPeriod.week => _repository.getDeliveryRecordsForWeek(now),
        _SummaryPeriod.month => _repository.getDeliveryRecordsForMonth(now),
      };
      final totals = _sumRecords(await recordsFuture);
      if (!mounted || requestGeneration != _summaryRequestGeneration) return;
      final todayTotals = requestedPeriod == _SummaryPeriod.day
          ? totals
          : _sumRecords(await _repository.getDeliveryRecordsForDay(now));
      if (!mounted || requestGeneration != _summaryRequestGeneration) return;
      setState(() {
        _totals = totals;
        _todayTotals = todayTotals;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to load delivery summary: $error\n$stackTrace');
      if (!mounted || requestGeneration != _summaryRequestGeneration) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('データの読み込みに失敗しました')));
    }
  }

  DeliveryTotals _sumRecords(List<DeliveryRecord> records) {
    return DeliveryTotals(
      sales: records.fold(0, (sum, record) => sum + record.salesYen),
      deliveryCount: records.fold(
        0,
        (sum, record) => sum + record.deliveryCount,
      ),
      onlineMinutes: records.fold(
        0,
        (sum, record) => sum + record.onlineMinutes,
      ),
      distanceKm: records.fold(
        0.0,
        (sum, record) => sum + record.travelDistanceKm,
      ),
      fuelUsedLiters: records.fold(
        0.0,
        (sum, record) => sum + record.fuelUsedLiters,
      ),
      fuelCostYen: records.fold(0, (sum, record) => sum + record.fuelCostYen),
      profitYen: records.fold(0, (sum, record) => sum + record.profitYen),
      sessionCount: records.length,
    );
  }

  Future<void> _selectDestination(int index) async {
    if (_isNavigating) return;
    if (index == 0) {
      setState(() => _selectedIndex = index);
      return;
    }
    setState(() => _isNavigating = true);
    try {
      if (index == 1) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => HistoryScreen(repository: _repository),
          ),
        );
        await _loadSummary();
        return;
      }
      if (index == 2) {
        await Navigator.of(
          context,
        ).push<void>(MaterialPageRoute(builder: (_) => const SettingsScreen()));
        await _loadSummary();
        return;
      }
    } finally {
      if (mounted) setState(() => _isNavigating = false);
    }
  }

  Future<void> _startDelivery() async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);
    try {
      final session = await Navigator.of(context).push<DeliverySession>(
        MaterialPageRoute(
          builder: (_) => StartDistanceScreen(repository: _repository),
        ),
      );
      if (!mounted || session == null) return;
      try {
        await _activeDeliveryStorage.save(session);
      } catch (error, stackTrace) {
        debugPrint('Failed to save active delivery: $error\n$stackTrace');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('配達情報を保存できませんでした。もう一度お試しください')),
        );
        return;
      }
      if (!mounted) return;
      setState(() {
        _isDelivering = true;
        _deliverySession = session;
      });
    } finally {
      if (mounted) setState(() => _isNavigating = false);
    }
  }

  Future<void> _finishDelivery() async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);
    try {
      final result = await Navigator.of(context).push<FinishInputResult>(
        MaterialPageRoute(
          builder: (_) => FinishInputScreen(
            session: _deliverySession!,
            repository: _repository,
            activeDeliveryStorage: _activeDeliveryStorage,
          ),
        ),
      );
      if (!mounted || result == null) return;
      setState(() {
        _isDelivering = false;
        _deliverySession = null;
        _summaryPeriod = _SummaryPeriod.day;
      });
      await _loadSummary();
    } finally {
      if (mounted) setState(() => _isNavigating = false);
    }
  }

  String _formatYen(num value) => value.round().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );

  String _formatDuration(int minutes) =>
      '${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')}';

  String _formatMinutes(double value) {
    final minutes = value.round();
    if (minutes < 60) return '$minutes分／件';
    final remaining = minutes % 60;
    return remaining == 0
        ? '${minutes ~/ 60}時間／件'
        : '${minutes ~/ 60}時間$remaining分／件';
  }

  String get _emptyMessage => switch (_summaryPeriod) {
    _SummaryPeriod.day => '本日のデータはありません',
    _SummaryPeriod.week => '今週のデータはありません',
    _SummaryPeriod.month => '今月のデータはありません',
  };

  Widget _buildPerformanceSummary() {
    final metrics = DeliveryCalculator.calculateSavedTotals(_totals);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<_SummaryPeriod>(
          segments: const [
            ButtonSegment(value: _SummaryPeriod.day, label: Text('日')),
            ButtonSegment(value: _SummaryPeriod.week, label: Text('週')),
            ButtonSegment(value: _SummaryPeriod.month, label: Text('月')),
          ],
          selected: {_summaryPeriod},
          onSelectionChanged: (value) {
            setState(() => _summaryPeriod = value.first);
            _loadSummary();
          },
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_totals.sessionCount == 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text(_emptyMessage)),
          )
        else ...[
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
            title: '平均利益',
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
            title: '平均配達時間',
            value: _formatMinutes(metrics.minutesPerDelivery),
            unit: '',
            icon: Icons.timer_outlined,
            fitValue: true,
          ),
          const SizedBox(height: 12),
          InfoCard(
            title: '平均消費ガソリン',
            value: metrics.gasolinePerDelivery.toStringAsFixed(2),
            unit: 'L／件',
            icon: Icons.local_gas_station,
            fitValue: true,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final todayMetrics = DeliveryCalculator.calculateSavedTotals(_todayTotals);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GreetingHeader(
                logoWidth: 180,
                logoBottomSpacing: 16,
                greeting: _isDelivering ? '配達中です' : null,
                subtitle: _isDelivering ? '安全運転でいきましょう' : null,
              ),
              const SizedBox(height: 24),
              if (!_isDelivering)
                PrimaryButton(text: '🚗 配達開始', onPressed: _startDelivery),
              if (_isDelivering) ...[
                const SizedBox(height: 16),
                OptionButton(
                  text: '配達終了',
                  icon: Icons.stop_circle_outlined,
                  onPressed: _finishDelivery,
                ),
                const SizedBox(height: 24),
                const Text(
                  '配達中',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InfoCard(
                        title: '目標件数',
                        value: '${_deliverySession?.targetCount ?? 0}',
                        unit: '件',
                        icon: Icons.flag,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InfoCard(
                        title: '天気',
                        value: _deliverySession?.weather ?? '',
                        unit: '',
                        icon: Icons.wb_sunny_outlined,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: InfoCard(
                      title: '今日の利益',
                      value: _formatYen(todayMetrics.profit),
                      unit: '円',
                      icon: Icons.account_balance_wallet,
                      fitValue: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InfoCard(
                      title: '今日の売上',
                      value: _formatYen(_todayTotals.sales),
                      unit: '円',
                      icon: Icons.payments,
                      fitValue: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InfoCard(
                      title: '今日の件数',
                      value: '${_todayTotals.deliveryCount}',
                      unit: '件',
                      icon: Icons.delivery_dining,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InfoCard(
                      title: 'オンライン',
                      value: _formatDuration(_todayTotals.onlineMinutes),
                      unit: '',
                      icon: Icons.timer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildPerformanceSummary(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectDestination,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'ホーム'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: '履歴'),
          NavigationDestination(icon: Icon(Icons.settings), label: '設定'),
        ],
      ),
    );
  }
}

enum _SummaryPeriod { day, week, month }
