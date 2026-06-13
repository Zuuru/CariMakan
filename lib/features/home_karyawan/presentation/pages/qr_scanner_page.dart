import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QrScannerPage extends StatefulWidget {
  final String restoId;
  final String? expectedOrderId; // Optional: jika scanner hanya dari 1 order

  const QrScannerPage({
    Key? key,
    required this.restoId,
    this.expectedOrderId,
  }) : super(key: key);

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final MobileScannerController _scannerController = MobileScannerController();

  bool _isProcessing = false;
  bool _hasScanned = false;
  String _statusMessage = 'Arahkan kamera ke QR code pickup customer';
  bool _isSuccess = false;
  bool _isError = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _onQrDetected(String rawValue) async {
    if (_hasScanned || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _hasScanned = true;
      _statusMessage = 'Memvalidasi QR...';
    });

    await _scannerController.stop();

    try {
      // rawValue berisi orderId yang di-encode ke QR
      final orderId = rawValue.trim();

      // Validasi: jika ada expected order ID, pastikan cocok
      if (widget.expectedOrderId != null &&
          widget.expectedOrderId!.isNotEmpty &&
          orderId != widget.expectedOrderId) {
        _setError('QR tidak sesuai dengan pesanan ini.');
        return;
      }

      // Ambil dokumen dari Firestore
      final docRef =
          FirebaseFirestore.instance.collection('orders').doc(orderId);
      final docSnap = await docRef.get();

      if (!docSnap.exists) {
        _setError('Pesanan tidak ditemukan.');
        return;
      }

      final data = docSnap.data()!;
      final status = data['status'] as String? ?? '';
      final tipe = data['type'] as String? ?? '';
      final restoId = data['resto_id'] as String? ?? '';

      // Validasi resto
      if (restoId != widget.restoId) {
        _setError('QR tidak valid untuk resto ini.');
        return;
      }

      // Validasi tipe harus Take Away
      if (tipe.toLowerCase() != 'take away') {
        _setError('Pesanan ini bukan Take Away.');
        return;
      }

      // Validasi status harus Siap
      if (status.toLowerCase() != 'siap') {
        _setError('Pesanan belum berstatus Siap.\nStatus saat ini: $status');
        return;
      }

      // Semua valid — update status ke Selesai
      await docRef.update({
        'status': 'Selesai',
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isSuccess = true;
          _statusMessage =
              'QR Valid! Pesanan berhasil dikonfirmasi\ndan diserahkan ke customer.';
        });
      }
    } catch (e) {
      _setError('Terjadi kesalahan: $e');
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _isError = true;
      _statusMessage = message;
    });
  }

  void _resetScanner() {
    setState(() {
      _isProcessing = false;
      _hasScanned = false;
      _isSuccess = false;
      _isError = false;
      _statusMessage = 'Arahkan kamera ke QR code pickup customer';
    });
    _scannerController.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Feed
          if (!_isSuccess && !_isError)
            MobileScanner(
              controller: _scannerController,
              onDetect: (capture) {
                final barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  final raw = barcode.rawValue;
                  if (raw != null && raw.isNotEmpty) {
                    _onQrDetected(raw);
                    break;
                  }
                }
              },
            ),

          // Overlay gradients
          if (!_isSuccess && !_isError) ...[
            // Top gradient
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 200,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Bottom gradient
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 250,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Scanner frame overlay
            _buildScannerFrame(),
          ],

          // Success / Error state
          if (_isSuccess || _isError)
            _buildResultOverlay(),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context, _isSuccess),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Scan QR Pickup',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  // Torch toggle
                  if (!_isSuccess && !_isError)
                    GestureDetector(
                      onTap: () => _scannerController.toggleTorch(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.flashlight_on_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Bottom instructions
          if (!_isSuccess && !_isError)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      if (_isProcessing) ...[
                        const CircularProgressIndicator(
                          color: Color(0xFFD33400),
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        _statusMessage,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'QR hanya berlaku untuk pesanan Take Away\nyang sudah berstatus Siap',
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScannerFrame() {
    const frameSize = 240.0;
    const cornerSize = 32.0;
    const cornerWidth = 4.0;

    return Center(
      child: SizedBox(
        width: frameSize,
        height: frameSize,
        child: Stack(
          children: [
            // Dark overlay outside frame – done via ClipPath on the camera feed
            // Corner decorations
            // Top Left
            Positioned(
              top: 0,
              left: 0,
              child: _buildCorner(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                ),
                top: 0,
                left: 0,
                width: cornerSize,
                height: cornerWidth,
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              child: _buildCorner(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                ),
                top: 0,
                left: 0,
                width: cornerWidth,
                height: cornerSize,
              ),
            ),
            // Top Right
            Positioned(
              top: 0,
              right: 0,
              child: _buildCorner(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                ),
                top: 0,
                right: 0,
                width: cornerSize,
                height: cornerWidth,
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: _buildCorner(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                ),
                top: 0,
                right: 0,
                width: cornerWidth,
                height: cornerSize,
              ),
            ),
            // Bottom Left
            Positioned(
              bottom: 0,
              left: 0,
              child: _buildCorner(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                ),
                bottom: 0,
                left: 0,
                width: cornerSize,
                height: cornerWidth,
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: _buildCorner(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                ),
                bottom: 0,
                left: 0,
                width: cornerWidth,
                height: cornerSize,
              ),
            ),
            // Bottom Right
            Positioned(
              bottom: 0,
              right: 0,
              child: _buildCorner(
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(8),
                ),
                bottom: 0,
                right: 0,
                width: cornerSize,
                height: cornerWidth,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: _buildCorner(
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(8),
                ),
                bottom: 0,
                right: 0,
                width: cornerWidth,
                height: cornerSize,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner({
    required BorderRadius borderRadius,
    double? top,
    double? left,
    double? right,
    double? bottom,
    required double width,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFD33400),
        borderRadius: borderRadius,
      ),
    );
  }

  Widget _buildResultOverlay() {
    return Container(
      color: Colors.black,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Result Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isSuccess
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : const Color(0xFFEF4444).withValues(alpha: 0.15),
                  border: Border.all(
                    color:
                        _isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    width: 3,
                  ),
                ),
                child: Icon(
                  _isSuccess ? Icons.check_circle : Icons.error,
                  size: 64,
                  color:
                      _isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                _isSuccess ? 'Berhasil!' : 'Gagal',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _statusMessage,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: Colors.white70,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              if (_isSuccess) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Selesai',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _resetScanner,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD33400),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code_scanner, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Scan Ulang',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.white30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Batal',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
