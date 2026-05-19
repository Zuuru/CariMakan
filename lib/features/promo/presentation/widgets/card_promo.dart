import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carimakan/core/theme/app_colors.dart';

class CardPromo extends StatelessWidget {
  final String imageUrl;
  final String promoTitle;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const CardPromo({
    super.key,
    required this.imageUrl,
    required this.promoTitle,
    this.onTap,
    this.width = 375,
    this.height = 166,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: height,
        margin: const EdgeInsets.only(bottom: 16), // Dihilangkan right margin agar tidak overflow
        child: Stack(
          children: [
            // Main Card Background & Content
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    // Left Section (Ticket/Promo Info)
                    Container(
                      width: 77, // Lebar tetap untuk area abu-abu
                      height: height,
                      color: const Color(0xFFC4C4C4), // Grey color from design
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: RotatedBox(
                            quarterTurns: 3,
                            child: Text(
                              promoTitle,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Right Section (Image)
                    Expanded( // Menggunakan Expanded agar sisa ruang terisi otomatis tanpa overflow
                      child: SizedBox(
                        height: height,
                        child: imageUrl.startsWith('http')
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: AppColors.cardBackground,
                                  child: const Center(
                                    child: Icon(Icons.broken_image, color: Colors.grey),
                                  ),
                                ),
                              )
                            : Image.asset(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: AppColors.cardBackground,
                                  child: const Center(
                                    child: Icon(Icons.broken_image, color: Colors.grey),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Ticket Cutouts (Hiasan lingkaran)
            Positioned(
              left: -8, // Setengah lingkaran berada di luar
              top: 0,
              bottom: 0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  6, // Jumlah cekungan
                  (index) => Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppColors.background, // Warna background agar terlihat bolong
                      shape: BoxShape.circle,
                    ),
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

