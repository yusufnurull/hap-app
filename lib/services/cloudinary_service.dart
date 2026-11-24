// Layanan unggah dan akses gambar Cloudinary.
//
// Memakai unsigned upload preset, jadi tidak ada API secret di dalam kode.
// Cloud name dan nama preset boleh di-commit karena bukan rahasia.
//
// Butuh paket: flutter pub add http

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class CloudinaryService {
  CloudinaryService({http.Client? client}) : _client = client ?? http.Client();

  // TODO(Rafli): isi dengan data dari dashboard Cloudinary.
  static const String cloudName = 'ISI_CLOUD_NAME';
  static const String uploadPreset = 'ISI_NAMA_PRESET';
  static const String folder = 'hap/menu';

  final http.Client _client;

  Uri get _uploadUri =>
      Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

  /// Mengunggah foto, lalu mengembalikan URL https-nya untuk disimpan
  /// di field `fotoUrl` menu.
  Future<String> unggahFoto(File file) async {
    final request = http.MultipartRequest('POST', _uploadUri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = folder
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await _client.send(request);
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      throw Exception('Gagal mengunggah foto (${streamed.statusCode}): $body');
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    return json['secure_url'] as String;
  }

  /// URL versi kecil untuk kartu menu, supaya hemat kuota dan cepat dimuat.
  /// Contoh: thumbnail(url, 300) -> .../upload/w_300,c_fill,q_auto,f_auto/...
  static String thumbnail(String url, int width) {
    if (url.isEmpty || !url.contains('/upload/')) return url;
    return url.replaceFirst(
      '/upload/',
      '/upload/w_$width,c_fill,q_auto,f_auto/',
    );
  }
}
