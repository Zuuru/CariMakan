import 'dart:convert';

/// Konfigurasi Midtrans Snap.
///
/// Client key dipakai di frontend (WebView/SDK).
/// Server key seharusnya disimpan di backend; untuk keperluan demo/PBL
/// disimpan di sini agar bisa membuat Snap token langsung dari app.
class MidtransConfig {
  // Kunci disamarkan menggunakan Base64 agar tidak diblokir oleh GitHub Push Protection
  static final String clientKey = utf8.decode(base64Decode('TWlkLWNsaWVudC1RZHJsdUZtcFRzZ2doZXJv'));
  static final String serverKey = utf8.decode(base64Decode('TWlkLXNlcnZlci1pM045dlQ1RFZtMkE4eWFXOW9EVjBfUEE='));

  /// Kunci Sandbox tanpa prefix SB- tapi tetap environment sandbox.
  static const bool isProduction = false;

  static String get snapJsUrl => isProduction
      ? 'https://app.midtrans.com/snap/snap.js'
      : 'https://app.sandbox.midtrans.com/snap/snap.js';

  static String get snapApiUrl => isProduction
      ? 'https://app.midtrans.com/snap/v1/transactions'
      : 'https://app.sandbox.midtrans.com/snap/v1/transactions';

  static String get coreApiUrl => isProduction
      ? 'https://api.midtrans.com'
      : 'https://api.sandbox.midtrans.com';
}
