import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carimakan/core/theme/app_colors.dart';
import 'package:carimakan/features/promo/data/promo_model.dart';
import 'package:carimakan/features/promo/data/promo_service.dart';
import 'package:carimakan/features/home/presentation/pages/resto_page.dart';
import 'package:carimakan/features/home/presentation/pages/search_page.dart';
import 'package:carimakan/features/map/models/restaurant.dart';

class PromoBanner extends StatefulWidget {
  const PromoBanner({super.key});

  @override
  State<PromoBanner> createState() => _PromoBannerState();
}

class _PromoBannerState extends State<PromoBanner> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;
  List<PromoModel> _activePromos = [];
  late final Stream<List<PromoModel>> _promosStream;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9, initialPage: 0);
    _promosStream = PromoService.getActivePromos();
  }

  void _startAutoSlide(int itemCount) {
    _timer?.cancel();
    if (itemCount <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_pageController.hasClients) {
        _currentPage++;
        if (_currentPage >= itemCount) {
          _currentPage = 0;
        }
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

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
                initialRating: restaurant.rating,
                initialReviewCount: restaurant.reviewCount,
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
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PromoModel>>(
      stream: _promosStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox.shrink(); // Hide banner if database error occurs
        }

        if (snapshot.connectionState == ConnectionState.waiting && _activePromos.isEmpty) {
          return Container(
            height: 166,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final promos = snapshot.data ?? [];
        
        // Restart timer and update list if count changes
        if (promos.length != _activePromos.length) {
          _activePromos = promos;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _startAutoSlide(_activePromos.length);
          });
        }

        if (_activePromos.isEmpty) {
          // Display an aesthetic brand banner if there are no promos in Firestore
          return Container(
            height: 166,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFFD33400), Color(0xFFFF6333)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD33400).withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'CariMakan Promo',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Diskon & Penawaran Spesial!',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nantikan promo menarik dari restoran favorit Anda segera.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SizedBox(
          height: 166,
          child: PageView.builder(
            controller: _pageController,
            padEnds: false,
            onPageChanged: (int page) {
              _currentPage = page;
            },
            itemCount: _activePromos.length,
            itemBuilder: (context, index) {
              final promo = _activePromos[index];
              return GestureDetector(
                onTap: () => _handlePromoTap(context, promo),
                child: Container(
                  margin: const EdgeInsets.only(right: 15),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        // Background Image or default Gradient
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
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFFD33400), Color(0xFFFF6333)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                ),
                        ),
  
                        // Dark overlay for text clarity
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.85),
                                  Colors.black.withValues(alpha: 0.3),
                                  Colors.transparent,
                                ],
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                              ),
                            ),
                          ),
                        ),
  
                        // Promo details text overlay
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    promo.isPercent
                                        ? 'DISKON ${promo.nilaiDiskon}%'
                                        : 'POTONGAN Rp ${PromoModel.formatNumber(promo.nilaiDiskon)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  promo.nama,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  promo.deskripsi,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.9),
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
              );
            },
          ),
        );
      },
    );
  }
}
