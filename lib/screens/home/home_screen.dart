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
              PrimaryButton(
                text: '🚗 配達開始',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const StartDistanceScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              OptionButton(
                text: '配達終了',
                icon: Icons.stop_circle_outlined,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const FinishInputScreen(),
                    ),
                  );
                },
              ),
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
