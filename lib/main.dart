import 'package:flutter/material.dart';

import 'core/theme/app_colors.dart';

void main() {
  runApp(const HapApp());
}

class HapApp extends StatelessWidget {
  const HapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hap!',
      theme: ThemeData(scaffoldBackgroundColor: AppColors.background),
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Hap!',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('Pesan, ambil, hap!'),
            ],
          ),
        ),
      ),
    );
  }
}
