// Katalog stand dan menu yang tersedia bagi pembeli (tab Beranda).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/hap_logic.dart';
import '../../models/menu_model.dart';
import '../../models/stand_model.dart';
import '../../providers/app_store.dart';
import '../../widgets/cart_bar.dart';
import '../../widgets/common.dart';
import '../../widgets/hap_logo.dart';
import '../../widgets/menu_card.dart';
import '../../widgets/stand_card.dart';
import '../../widgets/switch_stand_dialog.dart';
import 'cart_screen.dart';
import 'stand_detail_screen.dart';

class KatalogScreen extends StatefulWidget {
  const KatalogScreen({super.key});

  @override
  State<KatalogScreen> createState() => _KatalogScreenState();
}

class _KatalogScreenState extends State<KatalogScreen> {
  final _search = TextEditingController();
  StandCategory? _category; // null = Semua

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openStand(StandModel stand) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StandDetailScreen(standId: stand.id),
      ),
    );
  }

  void _openCart() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CartScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final query = _search.text;
    final hasSearch = query.trim().isNotEmpty;

    final filtered =
        filterStands(store.stands, searchQuery: query, category: _category);
    final matchingStands = [...filtered.open, ...filtered.closed];
    final matchingMenus =
        hasSearch
        ? searchMenus(store.menus, store.stands, query)
        : <MenuModel>[];
    final summary = store.cartSummary;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const HapLogo(height: 36),
                    Text('Kantin Pusat Kampus',
                        style: hapText(12,
                            weight: FontWeight.w500,
                            color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Lapar, ${store.buyerName}? Pesan sekarang, ambil pas istirahat.',
                  style: hapText(14, height: 1.35),
                ),
                const SizedBox(height: 20),
                HapField(
                  controller: _search,
                  hint: 'Cari stand atau menu',
                  keyboardType: TextInputType.text,
                  onChanged: (_) => setState(() {}),
                  prefix: const Icon(Icons.search_rounded,
                      size: 20, color: AppColors.textMuted),
                  suffix: hasSearch
                      ? IconButton(
                          tooltip: 'Hapus pencarian',
                          onPressed: () => setState(_search.clear),
                          icon: const Icon(Icons.close_rounded,
                              size: 18, color: AppColors.textMuted),
                        )
                      : null,
                ),
                if (!hasSearch) ...[
                  const SizedBox(height: 20),
                  ChipRow(
                    children: [
                      HapChip(
                        label: 'Semua',
                        selected: _category == null,
                        onTap: () => setState(() => _category = null),
                      ),
                      for (final c in StandCategory.values)
                        HapChip(
                          label: c.label,
                          selected: _category == c,
                          onTap: () => setState(() => _category = c),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                if (hasSearch)
                  ..._searchResults(store, matchingStands, matchingMenus)
                else
                  ..._standSections(filtered),
              ],
            ),
          ),
        ),
        CartBar(
          standName: summary.standName,
          totalItems: summary.totalItems,
          totalPrice: summary.totalPrice,
          onOpenCart: _openCart,
        ),
      ],
    );
  }

  List<Widget> _standSections(StandFilterResult filtered) {
    return [
      SectionHeading(
        title: 'Buka sekarang',
        trailing: '${filtered.open.length} stand',
      ),
      const SizedBox(height: 12),
      if (filtered.open.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surface),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Belum ada stand buka untuk kategori ini',
                  style: hapText(15, weight: FontWeight.w600)),
              const SizedBox(height: 10),
              HapChip(
                label: 'Lihat semua stand',
                selected: false,
                horizontal: 14,
                vertical: 8,
                fontSize: 13,
                onTap: () => setState(() => _category = null),
              ),
            ],
          ),
        )
      else
        ..._spaced(
          [
            for (final s in filtered.open)
              StandCard(stand: s, onSelect: _openStand),
          ],
          10,
        ),
      if (filtered.closed.isNotEmpty) ...[
        const SizedBox(height: 24),
        SectionHeading(
          title: 'Tutup',
          trailing: '${filtered.closed.length} stand',
          muted: true,
        ),
        const SizedBox(height: 12),
        ..._spaced(
          [
            for (final s in filtered.closed)
              StandCard(stand: s, onSelect: _openStand),
          ],
          10,
        ),
      ],
    ];
  }

  List<Widget> _searchResults(
    AppStore store,
    List<StandModel> stands,
    List<MenuModel> menus,
  ) {
    if (stands.isEmpty && menus.isEmpty) {
      return [
        const Divider(),
        const SizedBox(height: 24),
        Text('Stand atau menu tidak ditemukan',
            style: hapText(16, weight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text('Coba kata kunci lain seperti geprek, es teh, atau Bu Sri.',
            style: hapText(14, color: AppColors.textMuted)),
        const SizedBox(height: 12),
        OutlineAction(
          label: 'Reset pencarian',
          fullWidth: false,
          height: 40,
          fontSize: 13,
          color: AppColors.textDark,
          borderColor: AppColors.surface,
          onPressed: () => setState(_search.clear),
        ),
      ];
    }

    return [
      if (stands.isNotEmpty) ...[
        SectionHeading(title: 'Stand', trailing: '${stands.length} stand'),
        const SizedBox(height: 12),
        ..._spaced(
          [for (final s in stands) StandCard(stand: s, onSelect: _openStand)],
          10,
        ),
        const SizedBox(height: 24),
      ],
      if (menus.isNotEmpty) ...[
        SectionHeading(title: 'Menu', trailing: '${menus.length} menu'),
        const SizedBox(height: 4),
        const RowDivider(),
        for (var i = 0; i < menus.length; i++)
          MenuCard(
            item: menus[i],
            standOpen: store.standById(menus[i].standId)?.isOpen ?? true,
            quantity: store.cart.items[menus[i].id] ?? 0,
            onAdd: (item) => addToCartWithConfirm(context, item),
            onRemove: store.removeFromCart,
            onTap: (menu) {
              final target = store.standById(menu.standId);
              if (target != null) _openStand(target);
            },
            showDivider: i < menus.length - 1,
          ),
      ],
    ];
  }

  List<Widget> _spaced(List<Widget> children, double gap) => [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          children[i],
        ],
      ];
}
