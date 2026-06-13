import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carimakan/core/widgets/custom_back_button.dart';
import 'package:carimakan/core/theme/app_colors.dart';
import 'package:carimakan/features/promo/data/promo_model.dart';
import 'package:carimakan/features/promo/data/promo_service.dart';
import 'package:carimakan/features/home/presentation/pages/resto_page.dart';
import 'package:carimakan/features/home/presentation/pages/search_page.dart';
import 'package:carimakan/features/map/models/restaurant.dart';
import '../widgets/card_promo.dart';

class PromoPage extends StatelessWidget {
  final VoidCallback? onBack;
  
  const PromoPage({super.key, this.onBack});

  void _handlePromoTap(BuildContext context, PromoModel promo) async {
    if (promo.restoId == null || promo.restoId!.isEmpty) {
      // Navigate to SearchPage for global promos
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SearchPage(),
        ),
      );
    } else {
      // Show loading overlay while fetching restaurant details
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );

      try {
        final restoDoc = await FirebaseFirestore.instance
            .collection('restaurants')
            .doc(promo.restoId)
            .get();

        // Close loading dialog
        if (context.mounted) {
          Navigator.pop(context);
        }

        if (restoDoc.exists && context.mounted) {
          final data = restoDoc.data()!;
          final restaurant = Restaurant.fromFirestore(restoDoc.id, data);
          
          // Custom distance mapping to match mock data or set dynamically
          final distanceStr = restaurant.id == 'mock_1'
              ? '2,14 km'
              : restaurant.id == 'mock_2'
                  ? '0,95 km'
                  : '1,20 km';

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RestoPage(
                name: restaurant.name,
                imageUrl: restaurant.imageUrl,
                distance: distanceStr,
                queueCount: restaurant.queueCount,
                restoId: restaurant.id,
              ),
            ),
          );
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Restoran tidak ditemukan')),
            );
          }
        }
      } catch (e) {
        // Close loading dialog if error
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memuat restoran: $e')),
          );
        }
      }
    }
  }

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
                    final promo = promos[index];
                    return CardPromo(
                      promo: promo,
                      onTap: () => _handlePromoTap(context, promo),
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
                          CustomBackButton(onPressed: onBack),
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
