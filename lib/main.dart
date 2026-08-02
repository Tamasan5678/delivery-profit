import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme/app_theme.dart';
import 'screens/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await configureDeviceOrientations();

  runApp(const DeliveryProfitApp());
}

Future<void> configureDeviceOrientations() {
  return SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
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
