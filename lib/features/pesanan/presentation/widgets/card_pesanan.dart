import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carimakan/core/theme/app_colors.dart';

enum PesananStatus { process, complete }
enum OrderType { dineIn, takeAway }

class CardPesanan extends StatelessWidget {
  final PesananStatus status;
  final String restoName;
  final String itemName;
  final String time;
  final OrderType orderType;
  final String imageUrl;

  const CardPesanan({
    super.key,
    required this.status,
    required this.restoName,
    required this.itemName,
    required this.time,
    required this.orderType,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isProcess = status == PesananStatus.process;
    final headerColor = isProcess ? const Color(0xFFCEE0FF) : const Color(0xFF61CF61);
    final statusText = isProcess ? 'Baru proses' : 'Completed';
    final statusIcon = isProcess 
        ? 'assets/images/icon_pesanan/process.png' 
        : 'assets/images/icon_pesanan/complete.png';

    final isDineIn = orderType == OrderType.dineIn;
    final badgeColor = isDineIn ? const Color(0xFFED001E) : const Color(0xFFFF8800);
    final badgeText = isDineIn ? 'Dine In' : 'Take Away';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Image.asset(
                  statusIcon,
                  width: 40,
                  height: 40,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.info, size: 40),
                ),
                const SizedBox(width: 12),
                Text(
                  statusText,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMain.withOpacity(0.5),
                  ),
                ),
                const Spacer(),
                Text(
                  time,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMain.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          
          // Body Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        restoName,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        itemName,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badgeText,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
