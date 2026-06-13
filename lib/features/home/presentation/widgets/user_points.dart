import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carimakan/core/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserPoints extends StatelessWidget {
  const UserPoints({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return _buildPointsDisplay(0);
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return _buildPointsDisplay(0);
        }
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final points = (data?['poin_reward'] as num?)?.toInt() ?? 0;
        return _buildPointsDisplay(points);
      },
    );
  }

  Widget _buildPointsDisplay(int points) {
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
          '$points',
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
