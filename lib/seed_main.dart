// Titik masuk khusus untuk mengisi data awal Firebase.
// Bukan bagian dari aplikasi; jalankan dengan:
//   flutter run -t lib/seed_main.dart
//
// File ini berisi password akun uji: JANGAN di-commit ke GitHub
// (sudah perlu dimasukkan ke .gitignore).

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/constants/app_enums.dart';
import 'firebase_options.dart';
import 'services/seed_service.dart';

/// Akun uji. Boleh diubah; catat dan bagikan ke tim lewat grup.
const List<SeedAccount> _akunUji = [
  SeedAccount(
    nama: 'Pembeli Satu',
    email: 'pembeli1@hap.test',
    password: 'hap12345',
    noHp: '081200000001',
    role: UserRole.pembeli,
  ),
  SeedAccount(
    nama: 'Pembeli Dua',
    email: 'pembeli2@hap.test',
    password: 'hap12345',
    noHp: '081200000002',
    role: UserRole.pembeli,
  ),
  SeedAccount(
    nama: 'Bu Sri',
    email: 'penjual.busri@hap.test',
    password: 'hap12345',
    noHp: '081200000003',
    role: UserRole.penjual,
    standId: 'bu-sri',
  ),
  SeedAccount(
    nama: 'Mas Joko',
    email: 'penjual.joko@hap.test',
    password: 'hap12345',
    noHp: '081200000004',
    role: UserRole.penjual,
    standId: 'mas-joko',
  ),
  SeedAccount(
    nama: 'Admin Hap',
    email: 'admin@hap.test',
    password: 'hap12345',
    noHp: '081200000005',
    role: UserRole.admin,
  ),
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: _SeedScreen()),
  );
}

class _SeedScreen extends StatefulWidget {
  const _SeedScreen();

  @override
  State<_SeedScreen> createState() => _SeedScreenState();
}

class _SeedScreenState extends State<_SeedScreen> {
  final List<String> _log = [];
  String _hasil = '';
  bool _jalan = false;

  Future<void> _isi() async {
    setState(() {
      _jalan = true;
      _log.clear();
      _hasil = '';
    });
    try {
      final hasil = await SeedService().isiDataAwal(
        akun: _akunUji,
        onProgress: (pesan) => setState(() => _log.add(pesan)),
      );
      setState(() => _hasil = hasil);
    } catch (e) {
      setState(() => _hasil = 'Gagal: $e');
    } finally {
      setState(() => _jalan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seed data Hap!')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Akan membuat ${_akunUji.length} akun uji, 4 stand, dan menunya.',
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _jalan ? null : _isi,
              child: Text(_jalan ? 'Mengisi...' : 'Isi data awal'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  for (final baris in _log) Text('• $baris'),
                  if (_hasil.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _hasil,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
