import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carimakan/core/theme/app_colors.dart';
import 'package:carimakan/features/promo/data/promo_model.dart';

class CardPromo extends StatelessWidget {
  final PromoModel promo;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const CardPromo({
    super.key,
    required this.promo,
    this.onTap,
    this.width = 375,
    this.height = 166,
  });

  Widget _buildRestoName(String? restoId) {
    if (restoId == null || restoId.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'Promo Global',
          style: GoogleFonts.poppins(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('restos').doc(restoId).get(),
      builder: (context, snapshot) {
        String restoName = 'Memuat...';
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            restoName = data?['name'] ?? 'Restoran';
          } else {
            restoName = 'Promo Resto';
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            restoName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    String formatDate(DateTime d) => '${d.day} ${months[d.month - 1]} ${d.year}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: height,
        margin: const EdgeInsets.only(bottom: 16),
        child: Stack(
          children: [
            // Main Card Background & Content
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    // Left Section (Ticket/Promo Info)
                    Container(
                      width: 77,
                      height: height,
                      color: AppColors.primary,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: RotatedBox(
                            quarterTurns: 3,
                            child: Text(
                              promo.isPercent
                                  ? '${promo.nilaiDiskon}% OFF'
                                  : 'Rp ${PromoModel.formatNumber(promo.nilaiDiskon)}\nOFF',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Right Section (Image & Details)
                    Expanded(
                      child: SizedBox(
                        height: height,
                        child: Stack(
                          children: [
                            // Background Image
                            Positioned.fill(
                              child: (promo.imageUrl != null && promo.imageUrl!.isNotEmpty)
                                  ? (promo.imageUrl!.startsWith('http')
                                      ? Image.network(
                                          promo.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            color: AppColors.cardBackground,
                                            child: const Center(
                                              child: Icon(Icons.restaurant_menu, color: AppColors.primary, size: 40),
                                            ),
                                          ),
                                        )
                                      : Image.asset(
                                          promo.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            color: AppColors.cardBackground,
                                            child: const Center(
                                              child: Icon(Icons.restaurant_menu, color: AppColors.primary, size: 40),
                                            ),
                                          ),
                                        ))
                                  : Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.primary.withValues(alpha: 0.85),
                                            AppColors.primary.withValues(alpha: 0.5),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.discount, color: Colors.white, size: 40),
                                      ),
                                    ),
                            ),

                            // Gradient Overlay for Text Readability
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black.withValues(alpha: 0.9),
                                      Colors.black.withValues(alpha: 0.4),
                                      Colors.transparent,
                                    ],
                                    begin: Alignment.bottomLeft,
                                    end: Alignment.topRight,
                                  ),
                                ),
                              ),
                            ),

                            // Content Details
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Row: Resto name badge & Promo code badge
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildRestoName(promo.restoId),
                                        if (promo.kode != null && promo.kode!.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              promo.kode!,
                                              style: GoogleFonts.poppins(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),

                                    // Column: Name, Description, and Validity Info
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          promo.nama,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          promo.deskripsi,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            color: Colors.white.withValues(alpha: 0.85),
                                            height: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        // Validity & Min. order requirement
                                        Text(
                                          'Min. Belanja: Rp ${PromoModel.formatNumber(promo.minBelanja)}  •  s.d. ${formatDate(promo.berakhir)}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white.withValues(alpha: 0.75),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Ticket Cutouts (decorative circles)
            Positioned(
              left: -8,
              top: 0,
              bottom: 0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  6,
                  (index) => Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppColors.background,
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
