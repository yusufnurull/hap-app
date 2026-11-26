// Profil stand milik penjual: ringkasan, status buka/tutup, dan info stand.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/app_store.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';

// Angka ringkasan harian pada prototipe masih statis; nanti dihitung dari
// koleksi pesanan Firestore.
const List<({String code, String time, int total})> _todayCompleted = [
  (code: 'A-018', time: '11.40 WIB', total: 12000),
  (code: 'A-017', time: '11.35 WIB', total: 19000),
  (code: 'A-015', time: '11.20 WIB', total: 12000),
  (code: 'A-014', time: '11.15 WIB', total: 10000),
  (code: 'A-013', time: '11.05 WIB', total: 12000),
  (code: 'A-012', time: '10.55 WIB', total: 9000),
  (code: 'A-011', time: '10.45 WIB', total: 12000),
  (code: 'A-010', time: '10.30 WIB', total: 18000),
  (code: 'A-009', time: '10.20 WIB', total: 7000),
  (code: 'A-008', time: '10.10 WIB', total: 12000),
  (code: 'A-007', time: '09.55 WIB', total: 12000),
  (code: 'A-006', time: '09.40 WIB', total: 10000),
  (code: 'A-005', time: '09.25 WIB', total: 19000),
  (code: 'A-004', time: '09.10 WIB', total: 12000),
  (code: 'A-003', time: '08.50 WIB', total: 9000),
  (code: 'A-002', time: '08.30 WIB', total: 12000),
  (code: 'A-001', time: '08.15 WIB', total: 10000),
  (code: 'A-000', time: '07.50 WIB', total: 19000),
];

class StandProfileScreen extends StatefulWidget {
  const StandProfileScreen({super.key});

  @override
  State<StandProfileScreen> createState() => _StandProfileScreenState();
}

class _StandProfileScreenState extends State<StandProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _foodTypes;
  late final TextEditingController _openHours;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final stand = context.read<AppStore>().sellerStand;
    _name = TextEditingController(text: stand.name);
    _foodTypes = TextEditingController(text: stand.foodTypes);
    _openHours = TextEditingController(text: stand.openHours);
  }

  @override
  void dispose() {
    _name.dispose();
    _foodTypes.dispose();
    _openHours.dispose();
    super.dispose();
  }

  void _save() {
    final store = context.read<AppStore>();
    final stand = store.sellerStand;
    if (_name.text.trim().isEmpty) return;
    store.updateStandInfo(
      stand.id,
      name: _name.text.trim(),
      foodTypes:
          _foodTypes.text.trim().isEmpty ? stand.foodTypes : _foodTypes.text.trim(),
      openHours:
          _openHours.text.trim().isEmpty ? stand.openHours : _openHours.text.trim(),
    );
    setState(() => _saved = true);
  }

  void _showTodayOrders() {
    showHapSheet<void>(
      context,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.82,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pesanan Selesai Hari Ini',
                            style: hapText(18, weight: FontWeight.w700)),
                        Text(
                            'Kamis, 13 November · ${_todayCompleted.length} pesanan',
                            style: hapText(13, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup daftar pesanan',
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _todayCompleted.length,
                separatorBuilder: (_, __) => const RowDivider(),
                itemBuilder: (_, i) {
                  final o = _todayCompleted[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o.code,
                                style: hapText(15,
                                    weight: FontWeight.w700, tabular: true)),
                            Text(o.time,
                                style: hapText(12,
                                    color: AppColors.textMuted, tabular: true)),
                          ],
                        ),
                        Text(formatRupiah(o.total),
                            style: hapText(14,
                                weight: FontWeight.w700, tabular: true)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.surface)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total pendapatan',
                      style: hapText(14, weight: FontWeight.w600)),
                  Text('Rp214.000',
                      style: hapText(16,
                          weight: FontWeight.w800,
                          color: AppColors.primary,
                          tabular: true)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final stand = store.sellerStand;

    Widget stat(String label, Widget value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: hapText(12,
                      weight: FontWeight.w500, color: AppColors.textMuted)),
              const SizedBox(height: 2),
              value,
            ],
          ),
        );

    return Column(
      children: [
        RoleHeader(
          subtitle: stand.locationNote,
          badge: 'Hap! Penjual',
          title: 'Profil Stand',
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surface),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ringkasan hari ini',
                          style: hapText(16, weight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          stat(
                            'Pesanan selesai',
                            Text('18',
                                style: hapText(22,
                                    weight: FontWeight.w800, tabular: true)),
                          ),
                          stat(
                            'Pendapatan',
                            Text('Rp214.000',
                                style: hapText(18,
                                    weight: FontWeight.w800,
                                    color: AppColors.primary,
                                    tabular: true)),
                          ),
                          stat(
                            'Dibatalkan',
                            Text('1',
                                style: hapText(22,
                                    weight: FontWeight.w800, tabular: true)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Menu terlaris',
                          style: hapText(12,
                              weight: FontWeight.w500,
                              color: AppColors.textMuted)),
                      Text.rich(
                        TextSpan(
                          text: 'Nasi Ayam Geprek ',
                          children: [
                            TextSpan(
                              text: '(9 porsi)',
                              style: hapText(13, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        style: hapText(15, weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Diperbarui otomatis dari pesanan hari ini · Kamis, 13 November',
                        style: hapText(11, color: AppColors.textMuted),
                      ),
                      TextButton(
                        onPressed: _showTodayOrders,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                          alignment: Alignment.centerLeft,
                        ),
                        child: Text('Lihat pesanan hari ini',
                            style: hapText(13,
                                weight: FontWeight.w700,
                                color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surface),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status operasional',
                                style: hapText(12,
                                    weight: FontWeight.w500,
                                    color: AppColors.textMuted)),
                            const SizedBox(height: 2),
                            Text(
                              stand.isOpen ? 'Stand Buka' : 'Stand Tutup',
                              style: hapText(
                                18,
                                weight: FontWeight.w700,
                                color: stand.isOpen
                                    ? AppColors.success
                                    : const Color(0xA6302B27),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              stand.isOpen
                                  ? 'Pembeli bisa memesan menu sekarang.'
                                  : 'Menu tetap terlihat, tapi tidak bisa dipesan.',
                              style: hapText(12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      HapSwitch(
                        value: stand.isOpen,
                        width: 64,
                        height: 36,
                        activeColor: AppColors.success,
                        onChanged: (_) => store.toggleStandOpen(stand.id),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                LabeledField(
                  label: 'Nama stand',
                  child: HapField(
                    controller: _name,
                    onChanged: (_) => setState(() => _saved = false),
                  ),
                ),
                const SizedBox(height: 14),
                LabeledField(
                  label: 'Deskripsi / jenis makanan',
                  child: HapField(
                    controller: _foodTypes,
                    onChanged: (_) => setState(() => _saved = false),
                  ),
                ),
                const SizedBox(height: 14),
                LabeledField(
                  label: 'Jam buka–tutup',
                  child: HapField(
                    controller: _openHours,
                    tabular: true,
                    onChanged: (_) => setState(() => _saved = false),
                  ),
                ),
                if (_saved) ...[
                  const SizedBox(height: 12),
                  Text('Perubahan profil stand disimpan.',
                      style: hapText(13,
                          weight: FontWeight.w600, color: AppColors.success)),
                ],
                const SizedBox(height: 16),
                PrimaryButton(label: 'Simpan Profil Stand', onPressed: _save),
                const SizedBox(height: 12),
                OutlineAction(
                  label: 'Keluar',
                  height: 48,
                  fontSize: 14,
                  onPressed: () async {
                    try {
                      await AuthService().keluar();
                      if (!context.mounted) return;
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    } catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gagal keluar: $error')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
