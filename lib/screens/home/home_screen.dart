import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/delivery_session.dart';
import '../../models/finish_input_result.dart';
import '../finish/finish_input_screen.dart';
import '../start/start_distance_screen.dart';
import '../../widgets/greeting_header.dart';
import '../../widgets/info_card.dart';
import '../../widgets/option_button.dart';
import '../../widgets/primary_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isDelivering = false;
  DeliverySession? _deliverySession;
  int _todaySales = 0;
  int _todayDeliveryCount = 0;
  String _todayOnlineTime = '0:00';

  Future<void> _startDelivery() async {
    final deliveryStart = await Navigator.of(context).push<DeliverySession>(
      MaterialPageRoute(
        builder: (_) => const StartDistanceScreen(),
      ),
    );

    if (!mounted || deliveryStart == null) {
      return;
    }

    setState(() {
      _isDelivering = true;
      _deliverySession = deliveryStart;
    });
  }

  Future<void> _finishDelivery() async {
    final finishResult = await Navigator.of(context).push<FinishInputResult>(
      MaterialPageRoute(
        builder: (_) => const FinishInputScreen(),
      ),
    );

    if (!mounted || finishResult == null) {
      return;
    }

    setState(() {
      _todaySales = finishResult.sales;
      _todayDeliveryCount = finishResult.deliveryCount;
      _todayOnlineTime = finishResult.onlineTime;
      _isDelivering = false;
      _deliverySession = null;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                PrimaryButton(
                  text: '🚗 配達開始',
                  onPressed: _startDelivery,
                ),
              if (_isDelivering) const SizedBox(height: 16),
              if (_isDelivering)
                OptionButton(
                  text: '配達終了',
                  icon: Icons.stop_circle_outlined,
                  onPressed: _finishDelivery,
                ),
              if (_isDelivering) ...[
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
                        value: _deliverySession?.targetCount.toString() ?? '0',
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
                      value: _todaySales.toString(),
                      unit: '円',
                      icon: Icons.account_balance_wallet,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InfoCard(
                      title: '今日の売上',
                      value: _todaySales.toString(),
                      unit: '円',
                      icon: Icons.payments,
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
                      value: _todayDeliveryCount.toString(),
                      unit: '件',
                      icon: Icons.delivery_dining,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InfoCard(
                      title: 'オンライン',
                      value: _todayOnlineTime,
                      unit: '',
                      icon: Icons.timer,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'ホーム'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: '履歴'),
          NavigationDestination(icon: Icon(Icons.settings), label: '設定'),
        ],
      ),
    );
  }
}
