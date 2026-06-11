import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carimakan/core/widgets/custom_back_button.dart';
import '../../data/pesanan_service.dart';
import 'order_receipt_page.dart';

class QrisScanPage extends StatefulWidget {
  final String menuName;
  final double totalPrice;
  final Map<String, List<Map<String, dynamic>>> selectedVariants;

  const QrisScanPage({
    Key? key,
    required this.menuName,
    required this.totalPrice,
    required this.selectedVariants,
  }) : super(key: key);

  @override
  State<QrisScanPage> createState() => _QrisScanPageState();
}

class _QrisScanPageState extends State<QrisScanPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 72,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: Center(child: CustomBackButton()),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.qr_code_2, size: 16, color: Colors.black),
              const SizedBox(width: 8),
              Text(
                'QRIS',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Text(
              'Scan disini yakk',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 32),
            // Placeholder for QR Code
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: const Center(
                child: Icon(Icons.qr_code_scanner, size: 150, color: Colors.black),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                setState(() {
                  _isLoading = true;
                });
                
                final orderId = await PesananService.createOrder(
                  menuName: widget.menuName,
                  totalPrice: widget.totalPrice,
                  paymentMethod: 'QRIS',
                  customization: widget.selectedVariants,
                );

                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });

                  if (orderId != 'error_creating_order') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderReceiptPage(
                          orderId: orderId,
                          menuName: widget.menuName,
                          totalPrice: widget.totalPrice,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Gagal membuat pesanan, coba lagi!')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE30613),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                minimumSize: const Size(double.infinity, 54),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Confirm',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
