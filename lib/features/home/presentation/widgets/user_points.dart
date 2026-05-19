import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carimakan/core/theme/app_colors.dart';

class UserPoints extends StatelessWidget {
  const UserPoints({super.key});

  @override
  Widget build(BuildContext context) {
    // Nantinya di sini kita bisa menambahkan StreamBuilder
    // untuk mengambil data real-time dari database.
    return Row(
      children: [
        Image.asset(
          'assets/images/Icon/coin.png',
          width: 21,
          height: 21,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.monetization_on,
            size: 21,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '100', // Placeholder amount
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
          ),
        ),
      ],
    );
  }
}
