import 'package:flutter/material.dart';

// Sementara: akan dibuat ulang setelah Firebase siap. Versi lama ada di riwayat Git.
class SellerVerificationScreen extends StatelessWidget {
  const SellerVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_empty_rounded, size: 48),
            SizedBox(height: 12),
            Text('Halaman ini menunggu integrasi backend'),
          ],
        ),
      ),
    );
  }
}
