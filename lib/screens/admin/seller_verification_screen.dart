// Layar Verifikasi Penjual: admin menyetujui atau menolak penjual yang
// baru mendaftar. Menyetujui = membuat stand + mengaktifkan akun.

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/admin_service.dart';
import '../../widgets/common.dart';
import 'admin_home_screen.dart';

class SellerVerificationScreen extends StatefulWidget {
  const SellerVerificationScreen({super.key});

  @override
  State<SellerVerificationScreen> createState() =>
      _SellerVerificationScreenState();
}

class _SellerVerificationScreenState extends State<SellerVerificationScreen> {
  final _admin = AdminService();
  late final Stream<List<UserModel>> _pendaftar =
      _admin.streamPenjualMenunggu();

  /// uid penjual yang sedang diproses, supaya tombolnya tidak ditekan dua kali.
  final Set<String> _sedangDiproses = {};

  String _namaStand(UserModel p) =>
      p.proposedStandName.isEmpty ? 'stand ini' : p.proposedStandName;

  Future<void> _setujui(UserModel p) async {
    final yakin = await tanyaKonfirmasi(
      context,
      judul: 'Setujui ${_namaStand(p)}?',
      pesan:
          'Stand baru akan dibuat atas nama ${p.name} dan akunnya langsung '
          'aktif. Stand dibuat dalam keadaan tutup; penjual bisa membukanya '
          'sendiri.',
      labelYa: 'Setujui',
    );
    if (!yakin) return;

    setState(() => _sedangDiproses.add(p.id));
    try {
      await _admin.setujuiPenjual(p);
      if (!mounted) return;
      tampilkanPesan(context, '${_namaStand(p)} disetujui.');
    } catch (e) {
      if (!mounted) return;
      tampilkanPesan(context, 'Gagal menyetujui: ${pesanGalat(e)}');
    } finally {
      if (mounted) setState(() => _sedangDiproses.remove(p.id));
    }
  }

  Future<void> _tolak(UserModel p) async {
    final yakin = await tanyaKonfirmasi(
      context,
      judul: 'Tolak ${p.name}?',
      pesan: 'Akun ini akan dinonaktifkan dan tidak bisa berjualan.',
      labelYa: 'Tolak',
    );
    if (!yakin) return;

    setState(() => _sedangDiproses.add(p.id));
    try {
      await _admin.tolakPenjual(p.id);
      if (!mounted) return;
      tampilkanPesan(context, 'Pendaftaran ${p.name} ditolak.');
    } catch (e) {
      if (!mounted) return;
      tampilkanPesan(context, 'Gagal menolak: ${pesanGalat(e)}');
    } finally {
      if (mounted) setState(() => _sedangDiproses.remove(p.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: _pendaftar,
      builder: (context, snap) {
        final list = snap.data ?? const <UserModel>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RoleHeader(
              subtitle: 'Menunggu persetujuan',
              badge: 'Hap! Admin',
              title: 'Verifikasi Penjual',
              trailing: Text(
                '${list.length} pendaftar',
                style: hapText(
                  12,
                  weight: FontWeight.w500,
                  color: AppColors.textMuted,
                  tabular: true,
                ),
              ),
            ),
            Expanded(child: _isi(snap, list)),
          ],
        );
      },
    );
  }

  Widget _isi(AsyncSnapshot<List<UserModel>> snap, List<UserModel> list) {
    if (snap.hasError) {
      return AdminPesanKosong(
        icon: Icons.error_outline_rounded,
        pesan: 'Gagal memuat pendaftar: ${pesanGalat(snap.error!)}',
      );
    }
    if (!snap.hasData) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (list.isEmpty) {
      return const AdminPesanKosong(
        icon: Icons.how_to_reg_outlined,
        pesan: 'Belum ada pendaftar penjual baru.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final p = list[i];
        return _KartuPendaftar(
          penjual: p,
          // Hanya kartu pertama yang tombolnya merah penuh, supaya layar
          // tidak dipenuhi banyak tombol utama.
          utama: i == 0,
          sibuk: _sedangDiproses.contains(p.id),
          onSetujui: () => _setujui(p),
          onTolak: () => _tolak(p),
        );
      },
    );
  }
}

class _KartuPendaftar extends StatelessWidget {
  const _KartuPendaftar({
    required this.penjual,
    required this.utama,
    required this.sibuk,
    required this.onSetujui,
    required this.onTolak,
  });

  final UserModel penjual;
  final bool utama;
  final bool sibuk;
  final VoidCallback onSetujui;
  final VoidCallback onTolak;

  @override
  Widget build(BuildContext context) {
    final p = penjual;
    final kontak = p.phone.isEmpty ? p.email : '${p.email} · ${p.phone}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surface),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.proposedStandName.isEmpty
                ? '(Nama stand belum diisi)'
                : p.proposedStandName,
            style: hapText(16, weight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text('Pemilik: ${p.name}', style: hapText(14)),
          const SizedBox(height: 2),
          Text(kontak, style: hapText(12, color: AppColors.textMuted)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: utama
                    ? PrimaryButton(
                        label: 'Setujui',
                        onPressed: sibuk ? null : onSetujui,
                        height: 44,
                      )
                    : OutlineAction(
                        label: 'Setujui',
                        onPressed: sibuk ? null : onSetujui,
                        height: 44,
                      ),
              ),
              const SizedBox(width: 8),
              TextAction(
                label: 'Tolak',
                onPressed: sibuk ? null : onTolak,
                color: AppColors.textSoft,
                fullWidth: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
