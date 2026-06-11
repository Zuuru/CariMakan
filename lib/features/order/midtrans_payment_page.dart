import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/services/midtrans_service.dart';

enum MidtransPaymentStatus { success, pending, error, closed }

class MidtransPaymentResult {
  final MidtransPaymentStatus status;
  final String? orderId;
  final String? message;

  const MidtransPaymentResult({
    required this.status,
    this.orderId,
    this.message,
  });
}

class MidtransQrisPage extends StatefulWidget {
  final MidtransQrisResult qrisResult;

  const MidtransQrisPage({
    super.key,
    required this.qrisResult,
  });

  @override
  State<MidtransQrisPage> createState() => _MidtransQrisPageState();
}

class _MidtransQrisPageState extends State<MidtransQrisPage> {
  Timer? _pollTimer;
  bool _isChecking = false;
  String _statusMessage = 'Scan QRIS untuk melakukan pembayaran';

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkPaymentStatus(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkPaymentStatus({bool silent = false}) async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    try {
      final status = await MidtransService.getTransactionStatus(widget.qrisResult.orderId);

      if (!mounted) return;

      if (MidtransService.isPaymentSuccess(status)) {
        _pollTimer?.cancel();
        Navigator.pop(
          context,
          MidtransPaymentResult(
            status: MidtransPaymentStatus.success,
            orderId: widget.qrisResult.orderId,
            message: 'Pembayaran QRIS berhasil',
          ),
        );
        return;
      }

      if (status == 'expire' || status == 'cancel' || status == 'deny') {
        _pollTimer?.cancel();
        setState(() {
          _statusMessage = 'Pembayaran gagal atau kedaluwarsa';
        });
        if (!silent) {
          Navigator.pop(
            context,
            MidtransPaymentResult(
              status: MidtransPaymentStatus.error,
              orderId: widget.qrisResult.orderId,
              message: 'Pembayaran gagal',
            ),
          );
        }
        return;
      }

      setState(() {
        _statusMessage = silent
            ? 'Menunggu pembayaran...'
            : 'Pembayaran belum diterima, coba lagi';
      });
    } catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal cek status: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  String _formatRupiah(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return 'Rp $buffer';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () {
            _pollTimer?.cancel();
            Navigator.pop(
              context,
              MidtransPaymentResult(
                status: MidtransPaymentStatus.closed,
                orderId: widget.qrisResult.orderId,
                message: 'Pembayaran dibatalkan',
              ),
            );
          },
        ),
        title: Text(
          'Bayar dengan QRIS',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              _formatRupiah(widget.qrisResult.grossAmount),
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFE30613),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nominal sudah otomatis sesuai total pesanan',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: QrImageView(
                data: widget.qrisResult.qrString,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan QR di atas via GoPay, OVO, DANA, m-Banking, atau e-wallet lainnya.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isChecking ? null : () => _checkPaymentStatus(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE30613),
                  disabledBackgroundColor: Colors.grey[400],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isChecking
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Sudah Bayar',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
