import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../config/midtrans_config.dart';

class MidtransQrisResult {
  final String orderId;
  final String qrString;
  final String transactionId;
  final int grossAmount;
  final String transactionStatus;

  const MidtransQrisResult({
    required this.orderId,
    required this.qrString,
    required this.transactionId,
    required this.grossAmount,
    required this.transactionStatus,
  });
}

class MidtransService {
  static const _uuid = Uuid();

  /// Buat transaksi QRIS via Core API — nominal otomatis dari [grossAmount].
  static Future<MidtransQrisResult> createQrisCharge({
    required int grossAmount,
    required String itemName,
    required int itemPrice,
    required int itemQuantity,
    int? ppn,
    int? otherFee,
    String? customerName,
    String? customerEmail,
  }) async {
    final orderId = 'CM-${_uuid.v4().substring(0, 8).toUpperCase()}';
    final itemDetails = _buildItemDetails(
      itemName: itemName,
      itemPrice: itemPrice,
      itemQuantity: itemQuantity,
      ppn: ppn,
      otherFee: otherFee,
    );

    final body = <String, dynamic>{
      'payment_type': 'qris',
      'transaction_details': {
        'order_id': orderId,
        'gross_amount': grossAmount,
      },
      'item_details': itemDetails,
      'qris': {'acquirer': 'gopay'},
    };

    if (customerName != null || customerEmail != null) {
      body['customer_details'] = {
        if (customerName != null) 'first_name': customerName,
        if (customerEmail != null) 'email': customerEmail,
      };
    }

    final data = await _postCharge(body);
    final transactionId = data['transaction_id'] as String;
    final qrCodeImageUrl = 'https://api.sandbox.midtrans.com/v2/qris/$transactionId/qr-code';

    // Cetak link simulator di konsol debug agar memudahkan testing oleh developer
    print('\n================ MIDTRANS QRIS SIMULATOR URL ================');
    print('QR Code Image URL: $qrCodeImageUrl');
    print('Order ID: $orderId');
    print('=============================================================\n');

    return MidtransQrisResult(
      orderId: orderId,
      qrString: data['qr_string'] as String,
      transactionId: transactionId,
      grossAmount: grossAmount,
      transactionStatus: data['transaction_status'] as String? ?? 'pending',
    );
  }

  /// Cek status transaksi berdasarkan order ID.
  static Future<String> getTransactionStatus(String orderId) async {
    final auth = base64Encode(utf8.encode('${MidtransConfig.serverKey}:'));

    final response = await http.get(
      Uri.parse('${MidtransConfig.coreApiUrl}/v2/$orderId/status'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Basic $auth',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['transaction_status'] as String? ?? 'pending';
    }

    throw Exception(
      'Gagal cek status transaksi (${response.statusCode}): ${response.body}',
    );
  }

  static bool isPaymentSuccess(String status) {
    return status == 'capture' || status == 'settlement';
  }

  static Future<Map<String, dynamic>> _postCharge(
    Map<String, dynamic> body,
  ) async {
    final auth = base64Encode(utf8.encode('${MidtransConfig.serverKey}:'));

    final response = await http.post(
      Uri.parse('${MidtransConfig.coreApiUrl}/v2/charge'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Basic $auth',
      },
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final statusCode = data['status_code']?.toString();

    if (statusCode == '201' || statusCode == '200') {
      return data;
    }

    throw Exception(
      'Gagal membuat QRIS Midtrans ($statusCode): ${data['status_message'] ?? response.body}',
    );
  }

  static List<Map<String, dynamic>> _buildItemDetails({
    required String itemName,
    required int itemPrice,
    required int itemQuantity,
    int? ppn,
    int? otherFee,
  }) {
    final itemDetails = <Map<String, dynamic>>[
      {
        'id': 'menu-1',
        'price': itemPrice,
        'quantity': itemQuantity,
        'name': _truncate(itemName, 50),
      },
    ];

    if (ppn != null && ppn > 0) {
      itemDetails.add({
        'id': 'ppn',
        'price': ppn,
        'quantity': 1,
        'name': 'PPN',
      });
    }

    if (otherFee != null && otherFee > 0) {
      itemDetails.add({
        'id': 'fee',
        'price': otherFee,
        'quantity': 1,
        'name': 'Biaya lainnya',
      });
    }

    return itemDetails;
  }

  static String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) return value;
    return value.substring(0, maxLength);
  }
}
