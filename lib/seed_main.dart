// Titik masuk khusus untuk mengisi data awal Firestore.
// Bukan bagian dari aplikasi; jalankan sekali dengan:
//   flutter run -t lib/seed_main.dart
//
// Langkah:
// 1. Daftarkan 2 akun penjual uji dari aplikasi biasa.
// 2. Salin uid keduanya dari Firebase Console > Authentication.
// 3. Tempel di _pemilikStand di bawah, lalu jalankan file ini.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'services/seed_service.dart';

/// standId (dari mock_data.dart) -> uid penjual. Biarkan '' bila belum ada.
const Map<String, String> _pemilikStand = {
  'bu-sri': '', // penjual uji 1
  'mas-joko': '', // penjual uji 2
  'pojok-minuman': '',
  'pak-darmo': '',
};

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MaterialApp(home: _SeedScreen()));
}

class _SeedScreen extends StatefulWidget {
  const _SeedScreen();

  @override
  State<_SeedScreen> createState() => _SeedScreenState();
}

class _SeedScreenState extends State<_SeedScreen> {
  String _pesan = 'Tekan tombol untuk mengisi data awal.';
  bool _jalan = false;

  Future<void> _isi() async {
    setState(() => _jalan = true);
    try {
      final hasil = await SeedService().isiDataAwal(
        pemilikStand: _pemilikStand,
      );
      setState(() => _pesan = hasil);
    } catch (e) {
      setState(() => _pesan = 'Gagal: $e');
    } finally {
      setState(() => _jalan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seed data Hap!')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_pesan, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _jalan ? null : _isi,
                child: Text(_jalan ? 'Mengisi...' : 'Isi data awal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
