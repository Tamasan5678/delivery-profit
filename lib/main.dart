import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'screens/home/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const DeliveryProfitApp());
}

class DeliveryProfitApp extends StatelessWidget {
  const DeliveryProfitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Delivery Profit',

      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,

      home: const HomeScreen(),
    );
  }
}