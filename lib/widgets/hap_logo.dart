// Logo Hap! dari assets/images/LOGO_HAP.png.
// Bila file belum ada, tampil teks "Hap!" sebagai cadangan.

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

class HapLogo extends StatelessWidget {
  const HapLogo({super.key, this.height = 56});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/LOGO_HAP.png',
      height: height,
      fit: BoxFit.contain,
      semanticLabel: 'Hap!',
      errorBuilder: (_, __, ___) => Text(
        'Hap!',
        style: hapText(height * 0.5,
            weight: FontWeight.w800, color: AppColors.primary),
      ),
    );
  }
}
