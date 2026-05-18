import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:carimakan/core/theme/app_colors.dart';
import '../widgets/card_promo.dart';

class PromoPage extends StatelessWidget {
  final VoidCallback? onBack;
  
  const PromoPage({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    // List promo dengan gambar dari assets/images/promo dan title bebas
    final List<Map<String, String>> promos = [
      {
        'title': 'Diskon Besar Deket lu!!',
        'image': 'assets/images/promo/temcyy.png',
      },
      {
        'title': 'PAPI DUO HEMAT!!',
        'image': 'assets/images/promo/WhatsApp Image 2026-04-15 at 2.38.46 PM.jpeg',
      },
      {
        'title': 'WAKTU SARAPAN!!',
        'image': 'assets/images/promo/sarapan sehat.png',
      },
      {
        'title': 'NGOPI KALCER!!',
        'image': 'assets/images/promo/ngopi kalcer.png',
      },
      {
        'title': 'BUTTERHUB DEAL!!',
        'image': 'assets/images/promo/butterhub.jpeg',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // List of Promos (Scrolling behind header)
          Positioned.fill(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 120, 20, 120), // Top padding for header space
              itemCount: promos.length,
              itemBuilder: (context, index) {
                return CardPromo(
                  promoTitle: promos[index]['title']!,
                  imageUrl: promos[index]['image']!,
                );
              },
            ),
          ),

          // Glassmorphic Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: onBack,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
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
                          Expanded(
                            child: Center(
                              child: Text(
                                'Promo',
                                style: GoogleFonts.poppins(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textMain,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 44),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
