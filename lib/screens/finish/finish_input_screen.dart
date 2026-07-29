import 'package:flutter/material.dart';

import '../../widgets/greeting_header.dart';
import '../../widgets/primary_button.dart';

class FinishInputScreen extends StatefulWidget {
  const FinishInputScreen({super.key});

  @override
  State<FinishInputScreen> createState() => _FinishInputScreenState();
}

class _FinishInputScreenState extends State<FinishInputScreen> {
  final onlineController = TextEditingController();
  final salesController = TextEditingController();
  final countController = TextEditingController();
  final distanceController = TextEditingController();
  bool _isCompleting = false;

  void _completeDelivery() {
    if (_isCompleting) {
      return;
    }

    final hasEmptyField = [
      onlineController,
      salesController,
      countController,
      distanceController,
    ].any((controller) => controller.text.trim().isEmpty);

    if (hasEmptyField) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('すべての項目を入力してください')),
      );
      return;
    }

    setState(() {
      _isCompleting = true;
    });
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    onlineController.dispose();
    salesController.dispose();
    countController.dispose();
    distanceController.dispose();
    super.dispose();
  }

  Widget inputField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.number}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('配達終了'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const GreetingHeader(),
              const SizedBox(height: 24),
              inputField(
                'オンライン時間（例：8:00）',
                onlineController,
                keyboardType: TextInputType.datetime,
              ),
              inputField('今日の売上（円）', salesController),
              inputField('配達件数', countController),
              inputField('走行距離（km）', distanceController),
              const SizedBox(height: 12),
              PrimaryButton(
                text: '保存する',
                onPressed: _completeDelivery,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
