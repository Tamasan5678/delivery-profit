import 'package:flutter/material.dart';

import '../../services/preferences_service.dart';
import '../../widgets/info_card.dart';
import '../../widgets/option_button.dart';
import '../../widgets/primary_button.dart';
import 'target_count_screen.dart';

class StartDistanceScreen extends StatefulWidget {
  const StartDistanceScreen({super.key});

  @override
  State<StartDistanceScreen> createState() =>
      _StartDistanceScreenState();
}

class _StartDistanceScreenState
    extends State<StartDistanceScreen> {
  int _startDistance = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDistance();
  }

  Future<void> _loadDistance() async {
    final distance =
    await PreferencesService.getEndDistance();

    setState(() {
      _startDistance = distance;
      _loading = false;
    });
  }

  Future<void> _editDistance() async {
    final controller = TextEditingController(
      text: _startDistance.toString(),
    );

    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("開始走行距離"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              suffixText: "km",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("キャンセル"),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  int.tryParse(controller.text),
                );
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        _startDistance = result;
      });
    }
  }

  Future<void> _next() async {
    await PreferencesService.saveStartDistance(
      _startDistance,
    );

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TargetCountScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("開始走行距離"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            InfoCard(
              title: "開始走行距離",
              value: _startDistance.toString(),
              unit: "km",
            ),

            const SizedBox(height: 20),

            OptionButton(
              text: "変更する",
              icon: Icons.edit,
              backgroundColor: Colors.white,
              borderColor: Colors.grey,
              textColor: Colors.black87,
              onPressed: _editDistance,
            ),

            const Spacer(),

            PrimaryButton(
              text: "次へ",
              onPressed: _next,
            ),
          ],
        ),
      ),
    );
  }
}