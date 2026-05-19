import 'dart:async';
import 'package:flutter/material.dart';

class PromoBanner extends StatefulWidget {
  const PromoBanner({super.key});

  @override
  State<PromoBanner> createState() => _PromoBannerState();
}

class _PromoBannerState extends State<PromoBanner> {
  static const List<String> promoImages = [
    'assets/images/promo/temcyy.png',
    'assets/images/promo/butterhub.jpeg',
    'assets/images/promo/sarapan sehat.png',
    'assets/images/promo/ngopi kalcer.png',
    'assets/images/promo/WhatsApp Image 2026-04-15 at 2.38.46 PM.jpeg',
  ];

  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // viewportFraction 0.9 makes the next item slightly visible
    _pageController = PageController(viewportFraction: 0.9, initialPage: 0);
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_pageController.hasClients) {
        _currentPage++;
        if (_currentPage >= promoImages.length) {
          _currentPage = 0;
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.fastOutSlowIn,
          );
        } else {
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.fastOutSlowIn,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 166,
      child: PageView.builder(
        controller: _pageController,
        padEnds: false, // Ensures the first item aligns to the left
        onPageChanged: (int page) {
          _currentPage = page;
        },
        itemCount: promoImages.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              image: DecorationImage(
                image: AssetImage(promoImages[index]),
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }
}
