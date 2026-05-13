import 'package:flutter/material.dart';

class PromoBanner extends StatelessWidget {
  final List<String> promoImages = [
    'assets/images/promo/temcyy.png',
    'assets/images/promo/butterhub.jpeg',
    'assets/images/promo/sarapan sehat.png',
    'assets/images/promo/ngopi kalcer.png',
    'assets/images/promo/WhatsApp Image 2026-04-15 at 2.38.46 PM.jpeg',
    'assets/images/promo/temcyy.png',
  ];

  PromoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 166,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: promoImages.length,
        itemBuilder: (context, index) {
          return Container(
            width: 297,
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
