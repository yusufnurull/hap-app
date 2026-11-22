// Layar pengelolaan menu penjual: stok, ketersediaan, tambah/ubah menu.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/icon_map.dart';
import '../../models/menu_model.dart';
import '../../providers/app_store.dart';
import '../../widgets/common.dart';
import 'menu_form_screen.dart';

class ManageMenuScreen extends StatelessWidget {
  const ManageMenuScreen({super.key});

  void _openForm(BuildContext context, [MenuModel? item]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => MenuFormScreen(initialItem: item)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final stand = store.sellerStand;
    final menus = store.menus.where((m) => m.standId == stand.id).toList();

    return Stack(
      children: [
        Column(
          children: [
            RoleHeader(
              subtitle: '${stand.name} · ${stand.locationNote}',
              badge: 'Hap! Penjual',
              title: 'Kelola Menu',
              trailing: Text('${menus.length} menu',
                  style: hapText(12,
                      weight: FontWeight.w500,
                      color: AppColors.textMuted,
                      tabular: true)),
            ),
            if (menus.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Stok per menu hari ini',
                        style: hapText(12,
                            weight: FontWeight.w600,
                            color: AppColors.textMuted)),
                    TextButton(
                      onPressed: () => _openBulk(context, menus),
                      child: Text('Atur stok hari ini',
                          style: hapText(13,
                              weight: FontWeight.w700,
                              color: AppColors.primary)),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: menus.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Belum ada menu di stand ini',
                              style: hapText(16, weight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text(
                            'Ketuk tombol + di kanan bawah untuk menambah menu baru.',
                            style: hapText(14, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                      itemCount: menus.length,
                      separatorBuilder: (_, __) => const RowDivider(),
                      itemBuilder: (context, i) =>
                          _MenuRow(item: menus[i], onEdit: () => _openForm(context, menus[i])),
                    ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () => _openForm(context),
            tooltip: 'Tambah menu baru',
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: const CircleBorder(),
            child: const Icon(Icons.add_rounded, size: 28),
          ),
        ),
      ],
    );
  }

  void _openBulk(BuildContext context, List<MenuModel> menus) {
    final store = context.read<AppStore>();
    showHapSheet<void>(
      context,
      builder: (_) => _BulkStockSheet(
        menus: menus,
        onSave: store.bulkUpdateStocks,
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item, required this.onEdit});
  final MenuModel item;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final store = context.read<AppStore>();
    final available = !item.isOutOfStock;

    return Opacity(
      opacity: available ? 1 : 0.65,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            InkWell(
              onTap: onEdit,
              child: IconTile(icon: iconFor(item.icon), size: 48, iconSize: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: onEdit,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: hapText(15, weight: FontWeight.w600, height: 1.25)),
                    const SizedBox(height: 2),
                    Text(formatRupiah(item.price),
                        style: hapText(13,
                            weight: FontWeight.w700,
                            color: AppColors.primary,
                            tabular: true)),
                    Text(item.category.label,
                        style: hapText(12, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleIconButton(
                        icon: Icons.remove_rounded,
                        size: 24,
                        iconSize: 14,
                        tooltip: 'Kurangi stok ${item.name}',
                        onTap: item.stock <= 0
                            ? null
                            : () => store.adjustStock(item.id, item.stock - 1),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 26),
                        child: Text('${item.stock}',
                            textAlign: TextAlign.center,
                            style: hapText(13,
                                weight: FontWeight.w700, tabular: true)),
                      ),
                      CircleIconButton(
                        icon: Icons.add_rounded,
                        size: 24,
                        iconSize: 14,
                        tooltip: 'Tambah stok ${item.name}',
                        onTap: () => store.adjustStock(item.id, item.stock + 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HapSwitch(
                      value: available,
                      onChanged: (_) => store.toggleMenuAvailability(item.id),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 52,
                      child: Text(available ? 'Tersedia' : 'Habis',
                          style: hapText(
                            11,
                            weight: FontWeight.w600,
                            color: available
                                ? AppColors.textDark
                                : AppColors.textMuted,
                          )),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet "Atur stok hari ini": semua menu sekaligus.
class _BulkStockSheet extends StatefulWidget {
  const _BulkStockSheet({required this.menus, required this.onSave});
  final List<MenuModel> menus;
  final ValueChanged<Map<String, int>> onSave;

  @override
  State<_BulkStockSheet> createState() => _BulkStockSheetState();
}

class _BulkStockSheetState extends State<_BulkStockSheet> {
  late final Map<String, TextEditingController> _controllers = {
    for (final m in widget.menus)
      m.id: TextEditingController(text: '${m.stock}'),
  };

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final updates = <String, int>{};
    for (final m in widget.menus) {
      final parsed = int.tryParse(_controllers[m.id]!.text.trim());
      updates[m.id] = parsed == null ? m.stock : (parsed < 0 ? 0 : parsed);
    }
    widget.onSave(updates);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.82;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
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
                      Text('Atur stok hari ini',
                          style: hapText(18, weight: FontWeight.w700)),
                      Text('Isi jumlah porsi tersedia untuk setiap menu.',
                          style: hapText(13, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Tutup atur stok',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final m in widget.menus)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(m.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: hapText(14, weight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 80,
                          child: HapField(
                            controller: _controllers[m.id],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.end,
                            radius: 10,
                            vertical: 11,
                            tabular: true,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: PrimaryButton(label: 'Simpan stok', onPressed: _save),
          ),
        ],
      ),
    );
  }
}
