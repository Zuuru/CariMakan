import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carimakan/core/theme/app_colors.dart';
import 'package:carimakan/core/widgets/custom_back_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../pesanan/presentation/pages/tracker_dine_in_page.dart';
import '../../../pesanan/presentation/pages/tracker_takeaway_page.dart';
import '../../../promo/presentation/pages/promo_page.dart';
import '../../../pendaftaran_resto/presentation/pages/status_pendaftaran_page.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _markAsRead(String notifId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notifId)
        .update({'isRead': true});
  }

  Future<void> _markAllAsRead() async {
    if (currentUser == null) return;
    
    final querySnapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: currentUser!.uid)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (var doc in querySnapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Semua notifikasi telah ditandai dibaca.', style: GoogleFonts.poppins()),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleNotificationClick(Map<String, dynamic> notif) {
    final notifId = notif['id'] ?? '';
    if (notif['isRead'] == false && notifId.isNotEmpty) {
      _markAsRead(notifId);
    }

    final type = notif['type'] ?? '';
    final data = notif['data'] as Map<String, dynamic>? ?? {};

    if (type == 'order_status') {
      final orderId = data['orderId'] as String?;
      final orderType = data['orderType'] as String? ?? 'Dine In';
      
      if (orderId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => orderType == 'Take Away'
                ? TrackerTakeawayPage(orderId: orderId)
                : TrackerDineInPage(orderId: orderId),
          ),
        );
      }
    } else if (type == 'promo') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PromoPage(onBack: () => Navigator.pop(context)),
        ),
      );
    } else if (type == 'resto_registration') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const StatusPendaftaranPage(
            initialStatus: RegistrationStatus.pending,
          ),
        ),
      );
    }
  }

  Widget _getIconForType(String type) {
    IconData iconData = Icons.notifications_rounded;
    Color color = Colors.grey;

    if (type == 'promo') {
      iconData = Icons.local_offer_rounded;
      color = Colors.amber.shade700;
    } else if (type == 'order_status') {
      iconData = Icons.receipt_long_rounded;
      color = AppColors.primary;
    } else if (type == 'resto_registration') {
      iconData = Icons.storefront_rounded;
      color = Colors.green.shade600;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color, size: 24),
    );
  }

  String _formatNotificationTime(Timestamp? timestamp) {
    if (timestamp == null) return 'Baru saja';
    final DateTime date = timestamp.toDate().toLocal();
    final DateTime now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m yang lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}j yang lalu';
    } else if (difference.inDays == 1) {
      return 'Kemarin';
    } else {
      return DateFormat('dd MMM yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: const CustomBackButton(),
          title: Text(
            'Notifikasi',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
        ),
        body: const Center(
          child: Text('Silakan login terlebih dahulu.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const CustomBackButton(),
        title: Text(
          'Notifikasi',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.textMain,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _markAllAsRead,
            icon: const Icon(Icons.done_all_rounded, color: AppColors.primary),
            tooltip: 'Tandai semua telah dibaca',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', whereIn: [currentUser!.uid, 'all'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final List<Map<String, dynamic>> notifs = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          }).toList();

          // Sort by createdAt descending
          notifs.sort((a, b) {
            final tA = a['createdAt'] as Timestamp?;
            final tB = b['createdAt'] as Timestamp?;
            if (tA == null) return 1;
            if (tB == null) return -1;
            return tB.compareTo(tA);
          });

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: notifs.length,
            separatorBuilder: (context, index) => const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)),
            itemBuilder: (context, index) {
              final notif = notifs[index];
              final isRead = notif['isRead'] as bool? ?? false;
              final timestamp = notif['createdAt'] as Timestamp?;

              return InkWell(
                onTap: () => _handleNotificationClick(notif),
                child: Container(
                  color: isRead ? Colors.transparent : AppColors.primary.withOpacity(0.04),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _getIconForType(notif['type'] ?? ''),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    notif['title'] ?? '',
                                    style: GoogleFonts.poppins(
                                      fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.textMain,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatNotificationTime(timestamp),
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              notif['body'] ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: isRead ? AppColors.textSecondary : AppColors.textMain.withOpacity(0.85),
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (!isRead) ...[
                        const SizedBox(width: 10),
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 8),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 72,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Belum ada notifikasi',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Semua update pesanan, promo spesial, dan status akun kamu akan muncul di sini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
