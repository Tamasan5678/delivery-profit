import 'package:flutter/material.dart';

import '../../widgets/greeting_header.dart';
import '../../widgets/primary_button.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  String _selectedWeather = '晴れ';

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
          setState(() {
            _selectedWeather = label;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('今日の天気'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const GreetingHeader(),
              const SizedBox(height: 24),
              const Text(
                '今日の天気を選択してください。',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _weatherTile('晴れ', Icons.wb_sunny, Colors.orange),
              _weatherTile('曇り', Icons.cloud, Colors.blueGrey),
              _weatherTile('雨', Icons.umbrella, Colors.blue),
              const Spacer(),
              PrimaryButton(
                text: '配達を開始する',
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
