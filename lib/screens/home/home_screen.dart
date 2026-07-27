import 'package:flutter/material.dart';

import '../start/start_distance_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return "おはようございます！";
    } else if (hour < 18) {
      return "こんにちは！";
    } else {
      return "こんばんは！";
    }
  }

  String _today() {
    final now = DateTime.now();

    const week = [
      "月",
      "火",
      "水",
      "木",
      "金",
      "土",
      "日",
    ];

    return "${now.year}/${now.month}/${now.day}（${week[now.weekday - 1]}）";
  }

  Widget _infoCard(
      String title,
      String value,
      String unit,
      ) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mainButton(
      BuildContext context,
      String text,
      IconData icon,
      Color color,
      VoidCallback onPressed,
      ) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🚗 Delivery Profit"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _today(),
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _greeting(),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),

              _infoCard("今日の利益", "0", "円"),
              _infoCard("今日の売上", "0", "円"),
              _infoCard("今日の件数", "0", "件"),
              _infoCard("オンライン時間", "0:00", ""),

              const SizedBox(height: 25),

              _mainButton(
                context,
                "配達開始",
                Icons.play_arrow,
                Colors.orange,
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StartDistanceScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              _mainButton(
                context,
                "履歴",
                Icons.history,
                Colors.blue,
                    () {
                  // 今後実装
                },
              ),

              const SizedBox(height: 12),

              _mainButton(
                context,
                "設定",
                Icons.settings,
                Colors.grey,
                    () {
                  // 今後実装
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}