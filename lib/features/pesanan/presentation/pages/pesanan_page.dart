import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carimakan/core/theme/app_colors.dart';
import '../widgets/card_pesanan.dart';

class PesananPage extends StatelessWidget {
  final VoidCallback? onBack;

  const PesananPage({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header with Back Button, Search, and Filter
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onBack,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 20,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Cari pesanan...',
                          hintStyle: GoogleFonts.poppins(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppColors.textSecondary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 15,
                          ),
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textMain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 50,
                    width: 50,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.tune, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Divider
            Divider(color: Colors.grey[300], thickness: 1, height: 1),

            // List of Orders
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  120,
                ), // Padding bottom for nav
                children: const [
                  CardPesanan(
                    status: PesananStatus.process,
                    restoName: 'Ideologist Coffee And Social Space',
                    itemName: '1x Butterscotch Sea Salt',
                    time: '19.00',
                    orderType: OrderType.dineIn,
                    imageUrl:
                        'assets/images/menu/makanan/Chicken Cordon Bleu.jpg',
                  ),
                  CardPesanan(
                    status: PesananStatus.complete,
                    restoName: 'Ideologist Coffee And Social Space',
                    itemName: '1x Butterscotch Sea Salt',
                    time: '19.00',
                    orderType: OrderType.takeAway,
                    imageUrl:
                        'assets/images/menu/makanan/Chicken Cordon Bleu.jpg',
                  ),
                  // Tambahkan data pesanan lainnya di sini
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
