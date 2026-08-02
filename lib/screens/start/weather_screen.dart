import 'package:flutter/material.dart';

import '../../models/delivery_session.dart';
import '../../widgets/greeting_header.dart';
import '../../widgets/primary_button.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({
    super.key,
    required this.targetCount,
    required this.startDistanceKm,
  });

  final int targetCount;
  final double startDistanceKm;

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  String _selectedWeather = '晴れ';
  bool _isStarting = false;

  void _selectWeather(String weather) {
    // 遷移処理より先に選択値を確定させる。
    _selectedWeather = weather;
    setState(() {});
  }

  void _startDelivery() {
    if (_isStarting) {
      return;
    }

    _isStarting = true;
    final selectedWeather = _selectedWeather;

    Navigator.of(context).pop(
      DeliverySession(
        sessionId: DeliverySession.generateSessionId(),
        targetCount: widget.targetCount,
        weather: selectedWeather,
        startDistanceKm: widget.startDistanceKm,
        startedAtUtcMs: DateTime.now().toUtc().millisecondsSinceEpoch,
      ),
    );
  }

  Widget _weatherTile(String label, IconData icon, Color color) {
    final selected = _selectedWeather == label;

    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label),
        trailing: selected
            ? const Icon(Icons.check_circle, color: Colors.green)
            : null,
        onTap: () {
          _selectWeather(label);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('今日の天気'), centerTitle: true),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const GreetingHeader(),
                      const SizedBox(height: 24),
                      const Text(
                        '今日の天気を選択してください。',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _weatherTile('晴れ', Icons.wb_sunny, Colors.orange),
                      _weatherTile('曇り', Icons.cloud, Colors.blueGrey),
                      _weatherTile('雨', Icons.umbrella, Colors.blue),
                      const Spacer(),
                      PrimaryButton(text: '配達を開始する', onPressed: _startDelivery),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
