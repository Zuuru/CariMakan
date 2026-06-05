import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';

/// Service untuk operasi CRUD karyawan via backend Node.js.
///
/// Semua method mengambil fresh ID Token dari Firebase Auth
/// sebelum mengirim request ke backend. Token expire setiap 1 jam,
/// jadi jangan simpan token di variabel — selalu panggil getIdToken().
class KaryawanService {
  /// Mendapatkan fresh ID Token dari user yang sedang login (owner).
  static Future<String> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User belum login. Silakan login terlebih dahulu.');
    }
    // forceRefresh: false — Firebase SDK akan auto refresh jika token expired
    final token = await user.getIdToken();
    if (token == null) {
      throw Exception('Gagal mendapatkan ID Token.');
    }
    return token;
  }

  /// Header standar untuk semua request ke backend.
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// **POST /karyawan/tambah**
  ///
  /// Membuat akun karyawan baru via backend Node.js.
  /// Backend akan membuat akun Firebase Auth + dokumen Firestore.
  ///
  /// Throws [Exception] jika gagal (email sudah ada, validasi gagal, dll).
  static Future<Map<String, dynamic>> tambahKaryawan({
    required String nama,
    required String email,
    required String password,
  }) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${ApiConfig.baseUrl}/karyawan/tambah');

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        'nama': nama,
        'email': email,
        'password': password,
      }),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return body['data'];
    } else {
      throw Exception(body['error'] ?? 'Gagal menambah karyawan.');
    }
  }

  /// **PATCH /karyawan/suspend/:uid**
  ///
  /// Toggle status karyawan antara 'aktif' dan 'suspend'.
  /// Backend akan disable/enable akun di Firebase Auth + update Firestore.
  ///
  /// Returns status baru ('aktif' atau 'suspend').
  static Future<String> toggleSuspendKaryawan(String uid) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${ApiConfig.baseUrl}/karyawan/suspend/$uid');

    final response = await http.patch(
      url,
      headers: headers,
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return body['data']['status'];
    } else {
      throw Exception(body['error'] ?? 'Gagal mengubah status karyawan.');
    }
  }

  /// **DELETE /karyawan/:uid**
  ///
  /// Menghapus akun karyawan secara permanen.
  /// Backend akan hapus akun Firebase Auth + dokumen Firestore.
  ///
  /// ⚠️ Tidak bisa dikembalikan!
  static Future<void> hapusKaryawan(String uid) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${ApiConfig.baseUrl}/karyawan/$uid');

    final response = await http.delete(
      url,
      headers: headers,
    );

    final body = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(body['error'] ?? 'Gagal menghapus karyawan.');
    }
  }
}
