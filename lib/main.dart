import 'package:flutter/material.dart';

import 'screens/home/home_screen.dart';

void main() {
  runApp(const DeliveryProfitApp());
}

class DeliveryProfitApp extends StatelessWidget {
  const DeliveryProfitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Delivery Profit',

      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F7F5),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B00),
        ),
      ),

      home: const HomeScreen(),
    );
  }
}