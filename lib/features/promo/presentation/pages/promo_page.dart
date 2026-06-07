import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:carimakan/core/theme/app_colors.dart';
import 'package:carimakan/features/promo/data/promo_model.dart';
import 'package:carimakan/features/promo/data/promo_service.dart';
import '../widgets/card_promo.dart';

class PromoPage extends StatelessWidget {
  final VoidCallback? onBack;
  
  const PromoPage({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // List of Promos (Scrolling behind header)
          Positioned.fill(
            child: StreamBuilder<List<PromoModel>>(
              stream: PromoService.getActivePromos(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        'Gagal memuat promo: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: Colors.red),
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                final promos = snapshot.data ?? [];

                if (promos.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.discount_outlined,
                              size: 64,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Belum Ada Promo Aktif',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMain,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Nantikan promo-promo menarik dari restoran kesayangan Anda segera!',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    MediaQuery.of(context).padding.top + 90, // Menambah sedikit padding agar tidak terpotong header glassmorphic
                    20,
                    120,
                  ),
                  itemCount: promos.length,
                  itemBuilder: (context, index) {
                    return CardPromo(
                      promo: promos[index],
                      onTap: () {
                        // Aksi saat card promo ditekan (opsional)
                      },
                    );
                  },
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
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
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
                                    color: Colors.black.withValues(alpha: 0.05),
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
                                  fontSize: 24,
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
