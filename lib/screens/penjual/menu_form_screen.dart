// Formulir tambah atau ubah menu.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/icon_map.dart';
import '../../models/menu_model.dart';
import '../../providers/app_store.dart';
import '../../widgets/common.dart';

class MenuFormScreen extends StatefulWidget {
  const MenuFormScreen({super.key, this.initialItem});

  /// null = tambah menu baru.
  final MenuModel? initialItem;

  @override
  State<MenuFormScreen> createState() => _MenuFormScreenState();
}

class _MenuFormScreenState extends State<MenuFormScreen> {
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  late final TextEditingController _description;
  late MenuCategory _category;
  late int _iconIndex;
  String _error = '';

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    _name = TextEditingController(text: item?.name ?? '');
    _price = TextEditingController(text: item == null ? '' : '${item.price}');
    _stock = TextEditingController(text: item == null ? '15' : '${item.stock}');
    _description = TextEditingController(text: item?.description ?? '');
    _category = item?.category ?? MenuCategory.makanan;
    final found = item == null ? -1 : foodIconOptions.indexOf(item.icon);
    _iconIndex = found >= 0 ? found : 0;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _stock.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    final store = context.read<AppStore>();
    final price = int.tryParse(_price.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
    final stockParsed = double.tryParse(_stock.text.trim()) ?? 0;
    final stock = stockParsed < 0 ? 0 : stockParsed.round();

    if (_name.text.trim().isEmpty || price == 0) {
      setState(() => _error = 'Isi nama menu dan harga yang valid.');
      return;
    }
    setState(() => _error = '');

    final description = _description.text.trim();
    store.saveSellerMenu(
      id: widget.initialItem?.id,
      name: _name.text.trim(),
      price: price,
      stock: stock,
      category: _category,
      description: description.isEmpty
          ? 'Menu pilihan dari ${store.sellerStand.name}.'
          : description,
      icon: foodIconOptions[_iconIndex],
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initialItem != null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: editing ? 'Ubah Menu' : 'Tambah Menu'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FieldLabel('Foto menu'),
                    Material(
                      color: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0x26302B27)),
                      ),
                      child: InkWell(
                        customBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onTap: () => setState(() =>
                            _iconIndex = (_iconIndex + 1) % foodIconOptions.length),
                        child: SizedBox(
                          width: double.infinity,
                          height: 144,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(iconFor(foodIconOptions[_iconIndex]),
                                  size: 36, color: const Color(0xA6302B27)),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add_a_photo_rounded,
                                      size: 16, color: AppColors.textSoft),
                                  const SizedBox(width: 6),
                                  Text('Ketuk untuk unggah foto',
                                      style: hapText(12,
                                          weight: FontWeight.w600,
                                          color: AppColors.textSoft)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    LabeledField(
                      label: 'Nama menu',
                      child: HapField(
                        controller: _name,
                        hint: 'Contoh: Nasi Ayam Geprek',
                      ),
                    ),
                    const SizedBox(height: 16),
                    LabeledField(
                      label: 'Harga (Rp)',
                      child: HapField(
                        controller: _price,
                        hint: '12000',
                        keyboardType: TextInputType.number,
                        tabular: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LabeledField(
                      label: 'Stok hari ini',
                      child: HapField(
                        controller: _stock,
                        hint: '15',
                        keyboardType: TextInputType.number,
                        tabular: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const FieldLabel('Kategori'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final c in MenuCategory.values)
                          HapChip(
                            label: c.label,
                            selected: _category == c,
                            horizontal: 16,
                            vertical: 8,
                            fontSize: 13,
                            onTap: () => setState(() => _category = c),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LabeledField(
                      label: 'Deskripsi singkat',
                      child: HapField(
                        controller: _description,
                        hint: 'Tulis bahan utama atau level pedas',
                        maxLines: 3,
                        vertical: 14,
                      ),
                    ),
                    if (_error.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ErrorText(_error),
                    ],
                    const SizedBox(height: 24),
                    PrimaryButton(label: 'Simpan', onPressed: _submit),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
