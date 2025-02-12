import 'package:flutter/material.dart';
import 'WeatherScreen.dart'; // Import the mobile screen
import 'TabletWeatherScreen.dart'; // Import the tablet screen

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isTablet = constraints.maxWidth >= 600; // Check if screen width is for tablet

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: isTablet ? const TabletWeatherScreen() : const WeatherScreen(),
        );
      },
    );
  }
}
