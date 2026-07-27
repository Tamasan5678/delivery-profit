import 'package:flutter/material.dart';

class TargetCountScreen extends StatelessWidget {
  const TargetCountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("目標件数"),
      ),
      body: const Center(
        child: Text(
          "目標件数画面",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}