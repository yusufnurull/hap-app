// Layar pengelolaan stand kantin oleh admin.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/stand_model.dart';
import '../../providers/app_store.dart';
import '../../widgets/common.dart';

class ManageStandsScreen extends StatelessWidget {
  const ManageStandsScreen({super.key});

  void _openForm(BuildContext context, [StandModel? stand]) {
    final store = context.read<AppStore>();
    showHapSheet<void>(
      context,
      builder: (_) => _StandForm(
        stand: stand,
        defaultLocation: 'Kios ${store.stands.length + 1}',
        onSave: store.adminSaveStand,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();

    return Column(
      children: [
        RoleHeader(
          subtitle: '${store.stands.length} stand terdaftar',
          badge: '',
          title: 'Kelola Stand',
          trailing: FilledButton.icon(
            onPressed: () => _openForm(context),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Tambah'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle: hapText(13, weight: FontWeight.w700),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: store.stands.length,
            separatorBuilder: (_, __) => const RowDivider(),
            itemBuilder: (context, i) {
              final s = store.stands[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(s.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: hapText(16,
                                        weight: FontWeight.w600)),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: s.isOpen
                                      ? AppColors.success
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(s.isOpen ? 'Buka' : 'Tutup',
                                    style: hapText(
                                      11,
                                      weight: FontWeight.w600,
                                      color: s.isOpen
                                          ? Colors.white
                                          : AppColors.textSoft,
                                    )),
                              ),
                            ],
                          ),
                          Text(s.foodTypes,
                              style: hapText(13, color: AppColors.textSoft)),
                          Text('${s.openHours} · ${s.locationNote}',
                              style: hapText(12,
                                  color: AppColors.textMuted, tabular: true)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlineAction(
                      label: 'Ubah',
                      fullWidth: false,
                      height: 36,
                      fontSize: 13,
                      horizontalPadding: 14,
                      color: AppColors.textDark,
                      borderColor: AppColors.outline,
                      onPressed: () => _openForm(context, s),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

typedef _SaveStand = void Function({
  String? id,
  required String name,
  required String foodTypes,
  required String openHours,
  required String locationNote,
  required bool isOpen,
  required List<StandCategory> categories,
});

class _StandForm extends StatefulWidget {
  const _StandForm({
    required this.stand,
    required this.defaultLocation,
    required this.onSave,
  });

  final StandModel? stand;
  final String defaultLocation;
  final _SaveStand onSave;

  @override
  State<_StandForm> createState() => _StandFormState();
}

class _StandFormState extends State<_StandForm> {
  late final TextEditingController _name;
  late final TextEditingController _food;
  late final TextEditingController _hours;
  late final TextEditingController _location;
  late bool _isOpen;

  @override
  void initState() {
    super.initState();
    final s = widget.stand;
    _name = TextEditingController(text: s?.name ?? '');
    _food = TextEditingController(text: s?.foodTypes ?? '');
    _hours = TextEditingController(text: s?.openHours ?? '07.00–15.00');
    _location =
        TextEditingController(text: s?.locationNote ?? widget.defaultLocation);
    _isOpen = s?.isOpen ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _food.dispose();
    _hours.dispose();
    _location.dispose();
    super.dispose();
  }

  void _submit() {
    if (_name.text.trim().isEmpty) return;
    String orElse(TextEditingController c, String fallback) =>
        c.text.trim().isEmpty ? fallback : c.text.trim();

    widget.onSave(
      id: widget.stand?.id,
      name: _name.text.trim(),
      foodTypes: orElse(_food, 'Makanan kantin'),
      openHours: orElse(_hours, '07.00–15.00'),
      locationNote: orElse(_location, 'Area Kantin'),
      isOpen: _isOpen,
      categories: widget.stand?.categories ?? const [StandCategory.makananBerat],
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(widget.stand == null ? 'Tambah Stand' : 'Ubah Stand',
                    style: hapText(18, weight: FontWeight.w700)),
              ),
              IconButton(
                tooltip: 'Tutup form stand',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LabeledField(
            label: 'Nama stand',
            child: HapField(controller: _name, hint: 'Contoh: Bakso Pak Budi'),
          ),
          const SizedBox(height: 12),
          LabeledField(
            label: 'Jenis makanan',
            child: HapField(
                controller: _food, hint: 'Contoh: Bakso urat, mie ayam'),
          ),
          const SizedBox(height: 12),
          LabeledField(
            label: 'Jam buka',
            child: HapField(controller: _hours, tabular: true),
          ),
          const SizedBox(height: 12),
          LabeledField(
            label: 'Lokasi kios',
            child: HapField(controller: _location),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Status stand buka',
                  style: hapText(14, weight: FontWeight.w600)),
              HapSwitch(
                value: _isOpen,
                width: 48,
                height: 28,
                activeColor: AppColors.success,
                onChanged: (v) => setState(() => _isOpen = v),
              ),
            ],
          ),
          const SizedBox(height: 20),
          PrimaryButton(label: 'Simpan', onPressed: _submit),
        ],
      ),
    );
  }
}
