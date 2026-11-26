// Layar Pengguna admin: daftar semua akun, filter per peran, catatan
// "tidak diambil", serta menonaktifkan / mengaktifkan akun.

import 'package:flutter/material.dart';

import '../../core/constants/app_enums.dart';
import '../../core/constants/firestore_values.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';
import 'admin_home_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _admin = AdminService();

  // Ambil semua pengguna sekali, lalu saring per peran di aplikasi.
  // Cara ini tidak membutuhkan composite index tambahan di Firestore.
  late final Stream<List<UserModel>> _pengguna = _admin.streamPengguna();

  /// Peran yang sedang dipilih. null = Semua.
  UserRole? _filter;

  /// uid akun yang sedang diproses, supaya tombol tidak ditekan dua kali.
  final Set<String> _sedangDiproses = {};

  String get _uidSaya => AuthService().currentFirebaseUser?.uid ?? '';

  Future<void> _ubahStatus(UserModel u, {required bool aktif}) async {
    if (!aktif) {
      final yakin = await tanyaKonfirmasi(
        context,
        judul: 'Nonaktifkan ${u.name}?',
        pesan: 'Akun ini tidak bisa dipakai sampai diaktifkan lagi oleh admin.',
        labelYa: 'Nonaktifkan',
      );
      if (!yakin) return;
    }

    setState(() => _sedangDiproses.add(u.id));
    try {
      await _admin.ubahStatusAkun(u.id, aktif: aktif, uidAdmin: _uidSaya);
      if (!mounted) return;
      tampilkanPesan(
        context,
        aktif ? '${u.name} diaktifkan lagi.' : '${u.name} dinonaktifkan.',
      );
    } catch (e) {
      if (!mounted) return;
      tampilkanPesan(context, 'Gagal mengubah status: ${pesanGalat(e)}');
    } finally {
      if (mounted) setState(() => _sedangDiproses.remove(u.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: _pengguna,
      builder: (context, snap) {
        final semua = snap.data ?? const <UserModel>[];
        final tampil = _filter == null
            ? semua
            : semua.where((u) => u.role == _filter).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------------- Header + chip filter ----------------
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.surface)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pengguna',
                          style: hapText(
                            24,
                            weight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                      ),
                      Text(
                        '${tampil.length} akun',
                        style: hapText(
                          12,
                          weight: FontWeight.w500,
                          color: AppColors.textMuted,
                          tabular: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ChipRow(
                    gap: 8,
                    children: [
                      HapChip(
                        label: 'Semua',
                        selected: _filter == null,
                        onTap: () => setState(() => _filter = null),
                        horizontal: 16,
                        vertical: 8,
                        fontSize: 13,
                      ),
                      for (final r in UserRole.values)
                        HapChip(
                          label: r.label,
                          selected: _filter == r,
                          onTap: () => setState(() => _filter = r),
                          horizontal: 16,
                          vertical: 8,
                          fontSize: 13,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(child: _isi(snap, tampil)),
          ],
        );
      },
    );
  }

  Widget _isi(AsyncSnapshot<List<UserModel>> snap, List<UserModel> tampil) {
    if (snap.hasError) {
      return AdminPesanKosong(
        icon: Icons.error_outline_rounded,
        pesan: 'Gagal memuat pengguna: ${pesanGalat(snap.error!)}',
      );
    }
    if (!snap.hasData) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (tampil.isEmpty) {
      return const AdminPesanKosong(
        icon: Icons.group_outlined,
        pesan: 'Tidak ada pengguna di kategori ini.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: tampil.length,
      separatorBuilder: (context, index) => const RowDivider(),
      itemBuilder: (context, i) => _barisPengguna(tampil[i]),
    );
  }

  Widget _barisPengguna(UserModel u) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  u.name.isEmpty ? '(Tanpa nama)' : u.name,
                  style: hapText(16, weight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(u.email, style: hapText(12, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(
                  '${u.role.label} · ${_labelStatus(u.status)}',
                  style: hapText(
                    12,
                    weight: FontWeight.w500,
                    color: u.isActive ? AppColors.textSoft : AppColors.primary,
                  ),
                ),
                // Ditandai merah bila 3 kali atau lebih tidak mengambil pesanan.
                if (u.noShowCount >= 3) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Tidak diambil: ${u.noShowCount} kali',
                    style: hapText(
                      12,
                      weight: FontWeight.w600,
                      color: AppColors.primary,
                      tabular: true,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          _tombolAksi(u),
        ],
      ),
    );
  }

  /// Tombol di kanan baris, tergantung jenis dan status akun.
  Widget _tombolAksi(UserModel u) {
    final sibuk = _sedangDiproses.contains(u.id);
    final teksKecil = hapText(12, color: AppColors.textMuted);

    if (u.id == _uidSaya) return Text('Akun kamu', style: teksKecil);
    // Akun admin tidak bisa dinonaktifkan dari aplikasi.
    if (u.role == UserRole.admin) return const SizedBox.shrink();
    // Penjual yang menunggu diproses lewat tab Penjual (supaya stand ikut dibuat).
    if (u.status == AccountStatus.menunggu) {
      return Text('Cek di tab Penjual', style: teksKecil);
    }
    if (u.isActive) {
      return OutlineAction(
        label: 'Nonaktifkan',
        onPressed: sibuk ? null : () => _ubahStatus(u, aktif: false),
        fullWidth: false,
        height: 36,
        fontSize: 13,
        horizontalPadding: 12,
      );
    }
    return OutlineAction(
      label: 'Aktifkan',
      onPressed: sibuk ? null : () => _ubahStatus(u, aktif: true),
      fullWidth: false,
      height: 36,
      fontSize: 13,
      horizontalPadding: 12,
      color: AppColors.success,
    );
  }

  String _labelStatus(String status) {
    switch (status) {
      case AccountStatus.menunggu:
        return 'Menunggu verifikasi';
      case AccountStatus.nonaktif:
        return 'Nonaktif';
      default:
        return 'Aktif';
    }
  }
}
