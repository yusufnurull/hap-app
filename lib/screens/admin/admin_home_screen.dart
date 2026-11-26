// Beranda administrator: kerangka dengan navigasi bawah, ditambah
// fungsi bantu (dialog konfirmasi, pesan, keluar) yang dipakai semua
// layar admin.

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/role_bottom_nav.dart';
import 'manage_stands_screen.dart';
import 'report_screen.dart';
import 'seller_verification_screen.dart';
import 'users_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        // IndexedStack menjaga keempat tab tetap hidup, jadi data dari
        // Firestore tidak dimuat ulang setiap kali pindah tab.
        child: IndexedStack(
          index: _tab,
          children: const [
            ReportScreen(),
            SellerVerificationScreen(),
            ManageStandsScreen(),
            UsersScreen(),
          ],
        ),
      ),
      bottomNavigationBar: RoleBottomNav(
        currentIndex: _tab,
        onSelect: (i) => setState(() => _tab = i),
        items: const [
          NavItem('Rekap', Icons.assignment_rounded),
          NavItem('Penjual', Icons.how_to_reg_rounded),
          NavItem('Stand', Icons.storefront_rounded),
          NavItem('Pengguna', Icons.group_rounded),
        ],
      ),
    );
  }
}

// =============================================================================
// Fungsi bantu untuk semua layar admin
// =============================================================================

/// Dialog konfirmasi sederhana. Mengembalikan true jika pengguna menekan
/// tombol [labelYa], false jika menekan Batal atau menutup dialog.
Future<bool> tanyaKonfirmasi(
  BuildContext context, {
  required String judul,
  required String pesan,
  required String labelYa,
}) async {
  final hasil = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(judul, style: hapText(18, weight: FontWeight.w700)),
      content: Text(
        pesan,
        style: hapText(14, color: AppColors.textSoft, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(
            'Batal',
            style: hapText(
              14,
              weight: FontWeight.w600,
              color: AppColors.textSoft,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(
            labelYa,
            style: hapText(
              14,
              weight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    ),
  );
  return hasil ?? false;
}

/// Menampilkan pesan singkat (SnackBar) di bawah layar.
void tampilkanPesan(BuildContext context, String pesan) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(pesan)));
}

/// Mengambil teks galat tanpa awalan "Exception: ".
String pesanGalat(Object error) =>
    error.toString().replaceFirst('Exception: ', '');

/// Keluar dari akun admin setelah konfirmasi. Router di app.dart otomatis
/// kembali ke layar login setelah Firebase sign-out.
Future<void> keluarAdmin(BuildContext context) async {
  final yakin = await tanyaKonfirmasi(
    context,
    judul: 'Keluar dari akun admin?',
    pesan: 'Kamu perlu login lagi untuk membuka panel admin.',
    labelYa: 'Keluar',
  );
  if (!yakin || !context.mounted) return;
  try {
    await AuthService().keluar();
    if (!context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  } catch (e) {
    if (!context.mounted) return;
    tampilkanPesan(context, 'Gagal keluar: ${pesanGalat(e)}');
  }
}

/// Tampilan kosong atau galat: ikon dan satu kalimat di tengah layar.
class AdminPesanKosong extends StatelessWidget {
  const AdminPesanKosong({super.key, required this.icon, required this.pesan});

  final IconData icon;
  final String pesan;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textFaint),
            const SizedBox(height: 12),
            Text(
              pesan,
              textAlign: TextAlign.center,
              style: hapText(14, color: AppColors.textMuted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
