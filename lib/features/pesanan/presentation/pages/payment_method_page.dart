import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carimakan/core/widgets/custom_back_button.dart';
import '../../data/cart_service.dart';
import '../../../promo/data/promo_model.dart';
import 'qris_scan_page.dart';


class PaymentMethodPage extends StatelessWidget {
  final List<CartItemModel> cartItems;
  final double totalPrice;
  final String restoId;
  final PromoModel? appliedPromo;
  final double discount;
  final double subtotal;

  const PaymentMethodPage({
    Key? key,
    required this.cartItems,
    required this.totalPrice,
    required this.restoId,
    this.appliedPromo,
    this.discount = 0.0,
    required this.subtotal,
  }) : super(key: key);

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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'Pembayaran',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),

            // Kartu Kredit Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kartu Kredit',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '1 Kartu Ditambahkan',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Credit Card Widget
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3F51B5), Color(0xFF9C27B0)], // Blue to Purple gradient
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Credit Card',
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                      ),
                      Text(
                        '**** 9876',
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Jull Tampan',
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'BRI',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Lainnya Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Lainnya',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '2 Metode Ditambahkan',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Other Methods
            _buildMethodItem(
              imagePath: 'assets/images/Icon/qris.png',
              title: 'QRIS',
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildMethodItem(
              icon: Icons.qr_code_scanner,
              title: 'Scan QRIS',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QrisScanPage(
                      cartItems: cartItems,
                      totalPrice: totalPrice,
                      restoId: restoId,
                      appliedPromo: appliedPromo,
                      discount: discount,
                      subtotal: subtotal,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildMethodItem(
              imagePath: 'assets/images/Icon/dana.png',
              title: 'Dana',
              onTap: () {},
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodItem({
    IconData? icon,
    String? imagePath,
    required String title,
    required VoidCallback onTap,
    Color iconColor = Colors.black,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            if (imagePath != null)
              Image.asset(imagePath, height: 24)
            else if (icon != null)
              Icon(icon, color: iconColor),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
