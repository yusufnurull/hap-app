// Layar Rekap admin: angka ringkasan hari ini dan jumlah pesanan per stand.
// Semua angka dihitung dari data Firestore secara real-time.

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/stand_model.dart';
import '../../services/admin_service.dart';
import '../../services/firestore_service.dart';
import '../../services/order_service.dart';
import '../../widgets/common.dart';
import 'admin_home_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  // Stream dibuat sekali di sini (bukan di build) supaya aplikasi tidak
  // berlangganan ulang ke Firestore setiap kali layar digambar ulang.
  late final Stream<RekapAdmin> _rekap = AdminService().streamRekap();
  late final Stream<List<StandModel>> _stands =
      FirestoreService().streamStands();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RoleHeader(
          subtitle: 'Kantin Pusat Kampus',
          badge: 'Hap! Admin',
          title: 'Rekap Hari Ini',
          trailing: IconButton(
            tooltip: 'Keluar',
            onPressed: () => keluarAdmin(context),
            icon: const Icon(Icons.logout_rounded),
            color: AppColors.textSoft,
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              // ---------------- Empat kartu angka ----------------
              StreamBuilder<RekapAdmin>(
                stream: _rekap,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return ErrorText(
                      'Gagal memuat rekap: ${pesanGalat(snap.error!)}',
                    );
                  }
                  final r = snap.data; // null = masih memuat
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _KartuAngka(
                              label: 'Pesanan hari ini',
                              nilai: r == null ? '-' : '${r.pesananHariIni}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _KartuAngka(
                              label: 'Selesai',
                              nilai: r == null ? '-' : '${r.selesaiHariIni}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _KartuAngka(
                              label: 'Stand buka',
                              nilai: r == null
                                  ? '-'
                                  : '${r.standBuka}/${r.totalStand}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _KartuAngka(
                              label: 'Penjual menunggu',
                              nilai: r == null ? '-' : '${r.penjualMenunggu}',
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // ---------------- Pesanan per stand ----------------
              const SectionHeading(title: 'Pesanan per Stand'),
              const SizedBox(height: 8),
              const RowDivider(),
              StreamBuilder<List<StandModel>>(
                stream: _stands,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: ErrorText(
                        'Gagal memuat stand: ${pesanGalat(snap.error!)}',
                      ),
                    );
                  }
                  if (!snap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  }
                  final stands = snap.data!;
                  if (stands.isEmpty) {
                    return const AdminPesanKosong(
                      icon: Icons.storefront_outlined,
                      pesan: 'Belum ada stand.',
                    );
                  }
                  return Column(
                    children: [
                      for (final s in stands) ...[
                        _BarisStand(key: ValueKey(s.id), stand: s),
                        const RowDivider(),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Kartu kecil berisi label dan angka besar.
class _KartuAngka extends StatelessWidget {
  const _KartuAngka({required this.label, required this.nilai});

  final String label;
  final String nilai;

  @override
  Widget build(BuildContext context) {
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
            label,
            style: hapText(12, weight: FontWeight.w500, color: AppColors.textMuted),
          ),
          const SizedBox(height: 6),
          Text(nilai, style: hapText(24, weight: FontWeight.w800, tabular: true)),
        ],
      ),
    );
  }
}

/// Satu baris stand beserta jumlah pesanannya hari ini.
/// Dibuat Stateful supaya stream ringkasan per stand hanya dibuat sekali.
class _BarisStand extends StatefulWidget {
  const _BarisStand({super.key, required this.stand});

  final StandModel stand;

  @override
  State<_BarisStand> createState() => _BarisStandState();
}

class _BarisStandState extends State<_BarisStand> {
  late final Stream<RingkasanHariIni> _ringkasan =
      OrderService().streamRingkasanHariIni(widget.stand.id);

  @override
  Widget build(BuildContext context) {
    final s = widget.stand;
    final status = s.isOpen ? 'Buka' : 'Tutup';
    final jam = s.openHours.isEmpty ? '' : ' · ${s.openHours}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name, style: hapText(16, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  '$status$jam',
                  style: hapText(
                    12,
                    weight: FontWeight.w500,
                    color: AppColors.textMuted,
                    tabular: true,
                  ),
                ),
              ],
            ),
          ),
          StreamBuilder<RingkasanHariIni>(
            stream: _ringkasan,
            builder: (context, snap) {
              final teks = snap.hasError
                  ? '-'
                  : snap.hasData
                  ? '${snap.data!.totalPesanan} pesanan'
                  : '...';
              return Text(
                teks,
                style: hapText(
                  14,
                  weight: FontWeight.w700,
                  color: AppColors.primary,
                  tabular: true,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
