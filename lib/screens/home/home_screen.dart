import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
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
  int? _targetCount;
  String? _weather;

  Future<void> _startDelivery() async {
    final deliveryStart = await Navigator.of(context).push<
        ({int targetCount, String weather})>(
      MaterialPageRoute(
        builder: (_) => const StartDistanceScreen(),
      ),
    );

    if (!mounted || deliveryStart == null) {
      return;
    }

    setState(() {
      _isDelivering = true;
      _targetCount = deliveryStart.targetCount;
      _weather = deliveryStart.weather;
    });
  }

  Future<void> _finishDelivery() async {
    final isCompleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const FinishInputScreen(),
      ),
    );

    if (!mounted || isCompleted != true) {
      return;
    }

    setState(() {
      _isDelivering = false;
      _targetCount = null;
      _weather = null;
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
              const GreetingHeader(
                logoWidth: 180,
                logoBottomSpacing: 16,
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
                        value: _targetCount?.toString() ?? '0',
                        unit: '件',
                        icon: Icons.flag,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InfoCard(
                        title: '天気',
                        value: _weather ?? '',
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
                      value: '0',
                      unit: '円',
                      icon: Icons.account_balance_wallet,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InfoCard(
                      title: '今日の売上',
                      value: '0',
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
                      value: '0',
                      unit: '件',
                      icon: Icons.delivery_dining,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InfoCard(
                      title: 'オンライン',
                      value: '0:00',
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
