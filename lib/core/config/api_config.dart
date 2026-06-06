/// Konfigurasi API untuk koneksi ke backend Node.js.
///
/// Ubah [baseUrl] sesuai environment:
/// - Emulator Android: http://10.0.2.2:3000
/// - Emulator iOS: http://localhost:3000
/// - Device fisik: http://<IP_KOMPUTER>:3000
/// - Production: https://your-domain.com
class ApiConfig {
  // Untuk emulator Android, gunakan 10.0.2.2 (alias localhost dari emulator)
  static const String baseUrl = 'http://10.0.2.2:3000';
}
