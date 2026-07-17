import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carimakan/core/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserPoints extends StatefulWidget {
  const UserPoints({super.key});

  @override
  State<UserPoints> createState() => _UserPointsState();
}

class _UserPointsState extends State<UserPoints> {
  Stream<DocumentSnapshot>? _pointsStream;
  String? _cachedUid;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  void _initStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _cachedUid = user.uid;
      _pointsStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots();
    } else {
      _cachedUid = null;
      _pointsStream = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return _buildPointsDisplay(0);
    }

    if (user.uid != _cachedUid) {
      _initStream();
    }

    if (_pointsStream == null) {
      return _buildPointsDisplay(0);
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: _pointsStream,
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
