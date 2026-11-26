// Layar Kelola Stand: daftar semua stand, tambah stand baru, dan ubah data
// stand (termasuk buka/tutup dan foto) lewat form di bottom sheet.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/icon_map.dart';
import '../../models/stand_model.dart';
import '../../services/admin_service.dart';
import '../../services/cloudinary_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common.dart';
import 'admin_home_screen.dart';

class ManageStandsScreen extends StatefulWidget {
  const ManageStandsScreen({super.key});

  @override
  State<ManageStandsScreen> createState() => _ManageStandsScreenState();
}

class _ManageStandsScreenState extends State<ManageStandsScreen> {
  late final Stream<List<StandModel>> _stands =
      FirestoreService().streamStands();

  /// Membuka form. [stand] null = tambah stand baru, terisi = ubah stand.
  Future<void> _bukaForm([StandModel? stand]) async {
    final pesan = await showHapSheet<String>(
      context,
      builder: (_) => _FormStand(stand: stand),
    );
    if (pesan != null && mounted) tampilkanPesan(context, pesan);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StandModel>>(
      stream: _stands,
      builder: (context, snap) {
        final stands = snap.data ?? const <StandModel>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RoleHeader(
              subtitle: '${stands.length} stand terdaftar',
              badge: '',
              title: 'Kelola Stand',
              trailing: SizedBox(
                height: 44,
                child: FilledButton.icon(
                  onPressed: () => _bukaForm(),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Tambah'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    textStyle: hapText(14, weight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            Expanded(child: _isi(snap, stands)),
          ],
        );
      },
    );
  }

  Widget _isi(AsyncSnapshot<List<StandModel>> snap, List<StandModel> stands) {
    if (snap.hasError) {
      return AdminPesanKosong(
        icon: Icons.error_outline_rounded,
        pesan: 'Gagal memuat stand: ${pesanGalat(snap.error!)}',
      );
    }
    if (!snap.hasData) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (stands.isEmpty) {
      return const AdminPesanKosong(
        icon: Icons.storefront_outlined,
        pesan: 'Belum ada stand. Tekan Tambah untuk membuat stand pertama.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: stands.length,
      separatorBuilder: (context, index) => const RowDivider(),
      itemBuilder: (context, i) => _BarisStand(
        stand: stands[i],
        onUbah: () => _bukaForm(stands[i]),
      ),
    );
  }
}

/// Satu baris stand: nama, label Buka/Tutup, jenis makanan, jam, lokasi.
class _BarisStand extends StatelessWidget {
  const _BarisStand({required this.stand, required this.onUbah});

  final StandModel stand;
  final VoidCallback onUbah;

  @override
  Widget build(BuildContext context) {
    final s = stand;
    // Gabungkan jam dan lokasi, lewati yang kosong.
    final keterangan = [
      s.openHours,
      s.locationNote,
    ].where((t) => t.isNotEmpty).join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          _FotoStand(stand: s),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        s.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: hapText(16, weight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _LabelBuka(buka: s.isOpen),
                  ],
                ),
                if (s.foodTypes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    s.foodTypes,
                    style: hapText(13, color: AppColors.textSoft),
                  ),
                ],
                if (keterangan.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    keterangan,
                    style: hapText(
                      12,
                      color: AppColors.textMuted,
                      tabular: true,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlineAction(
            label: 'Ubah',
            onPressed: onUbah,
            fullWidth: false,
            height: 40,
            fontSize: 14,
            color: AppColors.textDark,
            borderColor: AppColors.outline,
          ),
        ],
      ),
    );
  }
}

/// Foto kecil stand di daftar. Belum ada foto = ikon stand.
class _FotoStand extends StatelessWidget {
  const _FotoStand({required this.stand});

  static const double _ukuran = 56;

  final StandModel stand;

  @override
  Widget build(BuildContext context) {
    final ikon = IconTile(icon: iconFor(stand.icon), size: _ukuran);
    if (!stand.hasPhoto) return ikon;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        // Versi kecil dari Cloudinary supaya hemat kuota.
        CloudinaryService.thumbnail(stand.photoUrl, 200),
        width: _ukuran,
        height: _ukuran,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => ikon,
      ),
    );
  }
}

/// Label kecil "Buka" (hijau) atau "Tutup" (krem).
class _LabelBuka extends StatelessWidget {
  const _LabelBuka({required this.buka});

  final bool buka;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: buka ? AppColors.success : AppColors.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        buka ? 'Buka' : 'Tutup',
        style: hapText(
          11,
          weight: FontWeight.w600,
          color: buka ? Colors.white : AppColors.textSoft,
          height: 1.2,
        ),
      ),
    );
  }
}

// =============================================================================
// Form tambah / ubah stand
// =============================================================================

class _FormStand extends StatefulWidget {
  const _FormStand({this.stand});

  /// null = tambah stand baru.
  final StandModel? stand;

  @override
  State<_FormStand> createState() => _FormStandState();
}

class _FormStandState extends State<_FormStand> {
  final _admin = AdminService();

  late final _nama = TextEditingController(text: widget.stand?.name ?? '');
  late final _jenis = TextEditingController(
    text: widget.stand?.foodTypes ?? '',
  );
  late final _jamBuka = TextEditingController(
    text: _isiAtauDefault(widget.stand?.openTime, '07.00'),
  );
  late final _jamTutup = TextEditingController(
    text: _isiAtauDefault(widget.stand?.closeTime, '15.00'),
  );
  late final _lokasi = TextEditingController(
    text: widget.stand?.locationNote ?? '',
  );
  late final Set<StandCategory> _kategori = <StandCategory>{
    ...?widget.stand?.categories,
  };
  late bool _buka = widget.stand?.isOpen ?? false;

  /// Foto yang baru dipilih dari galeri, belum diunggah.
  File? _fotoBaru;

  /// URL foto yang sudah tersimpan. Kosong = belum ada / dihapus.
  late String _fotoUrl = widget.stand?.photoUrl ?? '';

  bool _menyimpan = false;
  bool _mengunggah = false;
  String? _galat;

  bool get _adaFoto => _fotoBaru != null || _fotoUrl.isNotEmpty;

  bool get _standBaru => widget.stand == null;

  static String _isiAtauDefault(String? nilai, String bawaan) =>
      (nilai == null || nilai.isEmpty) ? bawaan : nilai;

  @override
  void dispose() {
    _nama.dispose();
    _jenis.dispose();
    _jamBuka.dispose();
    _jamTutup.dispose();
    _lokasi.dispose();
    super.dispose();
  }

  void _gantiKategori(StandCategory k) {
    setState(() {
      if (_kategori.contains(k)) {
        _kategori.remove(k);
      } else {
        _kategori.add(k);
      }
    });
  }

  /// Memilih foto dari galeri. Ukuran dikecilkan supaya unggah cepat.
  Future<void> _pilihFoto() async {
    try {
      final hasil = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        imageQuality: 80,
      );
      if (hasil == null || !mounted) return; // batal memilih
      setState(() {
        _fotoBaru = File(hasil.path);
        _galat = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _galat = 'Gagal membuka galeri: ${pesanGalat(e)}');
    }
  }

  void _hapusFoto() {
    setState(() {
      _fotoBaru = null;
      _fotoUrl = '';
    });
  }

  Future<void> _simpan() async {
    final nama = _nama.text.trim();
    final buka = _jamBuka.text.trim();
    final tutup = _jamTutup.text.trim();

    // Validasi sederhana sebelum menyimpan.
    if (nama.isEmpty) {
      setState(() => _galat = 'Nama stand wajib diisi.');
      return;
    }
    if (buka.isEmpty || tutup.isEmpty) {
      setState(() => _galat = 'Jam buka dan jam tutup wajib diisi.');
      return;
    }
    if (_kategori.isEmpty) {
      setState(() => _galat = 'Pilih minimal satu kategori.');
      return;
    }

    setState(() {
      _menyimpan = true;
      _galat = null;
    });

    // Urutan kategori mengikuti enum, bukan urutan diklik.
    final kategori = StandCategory.values.where(_kategori.contains).toList();

    try {
      // Unggah foto dulu (kalau ada yang baru), baru simpan URL-nya.
      if (_fotoBaru != null) {
        setState(() => _mengunggah = true);
        final url = await CloudinaryService().unggahFoto(_fotoBaru!);
        if (!mounted) return;
        // Simpan hasilnya supaya tidak diunggah ulang kalau simpan gagal.
        setState(() {
          _fotoUrl = url;
          _fotoBaru = null;
          _mengunggah = false;
        });
      }

      if (_standBaru) {
        await _admin.tambahStand(
          StandModel(
            id: '', // id dibuat oleh Firestore
            name: nama,
            isOpen: _buka,
            foodTypes: _jenis.text.trim(),
            openHours: '$buka–$tutup',
            locationNote: _lokasi.text.trim(),
            categories: kategori,
            icon: 'storefront',
            photoUrl: _fotoUrl,
          ),
        );
      } else {
        await _admin.ubahStand(
          widget.stand!.copyWith(
            name: nama,
            isOpen: _buka,
            foodTypes: _jenis.text.trim(),
            openHours: '$buka–$tutup',
            locationNote: _lokasi.text.trim(),
            categories: kategori,
            photoUrl: _fotoUrl,
          ),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(
        _standBaru ? 'Stand $nama ditambahkan.' : 'Perubahan $nama disimpan.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _galat = _mengunggah
            ? 'Gagal mengunggah foto: ${pesanGalat(e)}'
            : 'Gagal menyimpan: ${pesanGalat(e)}';
        _menyimpan = false;
        _mengunggah = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Garis kecil penanda bottom sheet bisa ditarik.
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _standBaru ? 'Tambah Stand' : 'Ubah Stand',
            style: hapText(20, weight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          const FieldLabel('Foto stand'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _KotakFoto(
                fotoBaru: _fotoBaru,
                fotoUrl: _fotoUrl,
                onTap: _menyimpan ? null : _pilihFoto,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Foto persegi (1:1) tampil di kartu stand. '
                      'Kosongkan bila cukup ikon.',
                      style: hapText(12, color: AppColors.textSoft),
                    ),
                    const SizedBox(height: 4),
                    TextAction(
                      label: _adaFoto ? 'Ganti foto' : 'Pilih foto',
                      onPressed: _menyimpan ? null : _pilihFoto,
                      fullWidth: false,
                      height: 36,
                      fontSize: 13,
                    ),
                    if (_adaFoto)
                      TextAction(
                        label: 'Hapus foto',
                        onPressed: _menyimpan ? null : _hapusFoto,
                        color: AppColors.textSoft,
                        fullWidth: false,
                        height: 36,
                        fontSize: 13,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LabeledField(
            label: 'Nama stand',
            child: HapField(controller: _nama, hint: 'Contoh: Warung Bu Sri'),
          ),
          const SizedBox(height: 12),
          LabeledField(
            label: 'Jenis makanan',
            child: HapField(
              controller: _jenis,
              hint: 'Contoh: Ayam geprek, nasi',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LabeledField(
                  label: 'Jam buka',
                  child: HapField(
                    controller: _jamBuka,
                    hint: '07.00',
                    tabular: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LabeledField(
                  label: 'Jam tutup',
                  child: HapField(
                    controller: _jamTutup,
                    hint: '15.00',
                    tabular: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LabeledField(
            label: 'Lokasi',
            child: HapField(
              controller: _lokasi,
              hint: 'Contoh: Kios 1 · Kiri tangga',
            ),
          ),
          const SizedBox(height: 12),
          const FieldLabel('Kategori'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final k in StandCategory.values)
                HapChip(
                  label: k.label,
                  selected: _kategori.contains(k),
                  onTap: () => _gantiKategori(k),
                  horizontal: 14,
                  vertical: 8,
                  fontSize: 13,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Stand buka sekarang',
                  style: hapText(14, weight: FontWeight.w600),
                ),
              ),
              HapSwitch(
                value: _buka,
                onChanged: (v) => setState(() => _buka = v),
                activeColor: AppColors.success,
              ),
            ],
          ),
          if (_galat != null) ...[
            const SizedBox(height: 12),
            ErrorText(_galat!),
          ],
          const SizedBox(height: 20),
          PrimaryButton(
            label: _mengunggah
                ? 'Mengunggah foto...'
                : _menyimpan
                ? 'Menyimpan...'
                : 'Simpan',
            onPressed: _menyimpan ? null : _simpan,
          ),
        ],
      ),
    );
  }
}

/// Kotak pratinjau foto stand di form. Ketuk untuk memilih foto.
class _KotakFoto extends StatelessWidget {
  const _KotakFoto({
    required this.fotoBaru,
    required this.fotoUrl,
    required this.onTap,
  });

  static const double _ukuran = 112;

  final File? fotoBaru;
  final String fotoUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final kosong = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.add_a_photo_rounded,
          size: 28,
          color: AppColors.textSoft,
        ),
        const SizedBox(height: 6),
        Text(
          'Pilih foto',
          style: hapText(
            12,
            weight: FontWeight.w600,
            color: AppColors.textSoft,
          ),
        ),
      ],
    );

    Widget isi;
    if (fotoBaru != null) {
      // Foto baru dari galeri (belum diunggah).
      isi = Image.file(fotoBaru!, fit: BoxFit.cover);
    } else if (fotoUrl.isNotEmpty) {
      // Foto lama dari Cloudinary.
      isi = Image.network(
        CloudinaryService.thumbnail(fotoUrl, 300),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => kosong,
      );
    } else {
      isi = kosong;
    }

    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.outline),
      ),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(width: _ukuran, height: _ukuran, child: isi),
      ),
    );
  }
}
