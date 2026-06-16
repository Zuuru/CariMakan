import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/cloudinary_config.dart';

/// Service untuk menangani pengunggahan berkas media ke Cloudinary.
/// Menggunakan metode REST API Unsigned Upload sehingga aman tanpa API Secret Key di sisi klien.
class CloudinaryService {
  /// Mengunggah file gambar lokal ke Cloudinary.
  /// 
  /// Menerima parameter [imageFile] berupa objek File gambar.
  /// Mengembalikan [String] URL secure_url gambar jika berhasil, atau [null] jika gagal.
  static Future<String?> uploadImage(File imageFile) async {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload');
    
    try {
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(responseBody);
        return data['secure_url'] as String?;
      } else {
        String errorMsg = 'Status ${response.statusCode}';
        try {
          final Map<String, dynamic> errorData = jsonDecode(responseBody);
          if (errorData['error'] != null && errorData['error']['message'] != null) {
            errorMsg = errorData['error']['message'];
          }
        } catch (_) {
          errorMsg = responseBody;
        }
        throw Exception('Cloudinary: $errorMsg');
      }
    } catch (e) {
      print('Exception during Cloudinary upload: $e');
      rethrow;
    }
  }

  /// Mengunggah stream bytes (misal: gambar QR Code yang di-render) ke Cloudinary.
  /// 
  /// Menerima parameter [bytes] berupa daftar byte gambar, dan [filename] untuk penamaan berkas.
  /// Mengembalikan [String] URL secure_url gambar jika berhasil, atau [null] jika gagal.
  static Future<String?> uploadBytes(List<int> bytes, String filename) async {
    final url = Uri.parse('https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload');
    
    try {
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
        ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(responseBody);
        return data['secure_url'] as String?;
      } else {
        String errorMsg = 'Status ${response.statusCode}';
        try {
          final Map<String, dynamic> errorData = jsonDecode(responseBody);
          if (errorData['error'] != null && errorData['error']['message'] != null) {
            errorMsg = errorData['error']['message'];
          }
        } catch (_) {
          errorMsg = responseBody;
        }
        throw Exception('Cloudinary: $errorMsg');
      }
    } catch (e) {
      print('Exception during Cloudinary bytes upload: $e');
      rethrow;
    }
  }
}
