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
  final String? statusText;

  const CardPesanan({
    super.key,
    required this.status,
    required this.restoName,
    required this.itemName,
    required this.time,
    required this.orderType,
    required this.imageUrl,
    this.statusText,
  });

  Color _getStatusColor(String? statusText, bool isProcess) {
    final status = statusText?.toLowerCase() ?? (isProcess ? 'diproses' : 'selesai');
    if (status == 'paid') return const Color(0xFFE3861B); // Orange
    if (status == 'diproses') return const Color(0xFF1D4ED8); // Blue
    if (status == 'siap') return const Color(0xFF10B981); // Green
    if (status == 'selesai' || status == 'complete') return const Color(0xFF6B7280); // Gray
    return const Color(0xFFE3861B); // Default waiting (orange)
  }

  Color _getCardBgColor(String? statusText, bool isProcess) {
    final status = statusText?.toLowerCase() ?? (isProcess ? 'diproses' : 'selesai');
    if (status == 'paid') return const Color(0xFFFFF7ED); // Soft Orange
    if (status == 'diproses') return const Color(0xFFEFF6FF); // Soft Blue
    if (status == 'siap') return const Color(0xFFECFDF5); // Soft Green
    if (status == 'selesai' || status == 'complete') return const Color(0xFFF9FAFB); // Soft Gray
    return const Color(0xFFFFF7ED);
  }

  Color _getHeaderBgColor(String? statusText, bool isProcess) {
    final status = statusText?.toLowerCase() ?? (isProcess ? 'diproses' : 'selesai');
    if (status == 'paid') return const Color(0xFFFFEDD5); // Amber 100
    if (status == 'diproses') return const Color(0xFFDBEAFE); // Blue 100
    if (status == 'siap') return const Color(0xFFD1FAE5); // Emerald 100
    if (status == 'selesai' || status == 'complete') return const Color(0xFFE5E7EB); // Gray 100
    return const Color(0xFFFFEDD5);
  }

  Color _getTextColor(String? statusText, bool isProcess) {
    final status = statusText?.toLowerCase() ?? (isProcess ? 'diproses' : 'selesai');
    if (status == 'paid') return const Color(0xFFC2410C); // Amber 700
    if (status == 'diproses') return const Color(0xFF1E40AF); // Blue 700
    if (status == 'siap') return const Color(0xFF047857); // Emerald 700
    if (status == 'selesai' || status == 'complete') return const Color(0xFF4B5563); // Gray 700
    return const Color(0xFFC2410C);
  }

  @override
  Widget build(BuildContext context) {
    final isProcess = status == PesananStatus.process;
    final statusLow = statusText?.toLowerCase() ?? (isProcess ? 'diproses' : 'selesai');

    final String displayStatus;
    final String statusIcon;

    if (statusLow == 'diproses') {
      displayStatus = 'Diproses';
      statusIcon = 'assets/images/icon_pesanan/process.png';
    } else if (statusLow == 'siap') {
      displayStatus = 'Siap Diambil';
      statusIcon = 'assets/images/icon_pesanan/process.png';
    } else if (statusLow == 'selesai' || statusLow == 'complete') {
      displayStatus = 'Selesai';
      statusIcon = 'assets/images/icon_pesanan/complete.png';
    } else {
      displayStatus = 'Menunggu Konfirmasi';
      statusIcon = 'assets/images/icon_pesanan/process.png';
    }

    final isDineIn = orderType == OrderType.dineIn;
    final badgeColor = isDineIn ? const Color(0xFFD33400) : const Color(0xFFE3861B);
    final badgeText = isDineIn ? 'Dine In' : 'Take Away';
    final textColor = _getTextColor(statusText, isProcess);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _getCardBgColor(statusText, isProcess),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Accent Line
            Container(
              width: 6,
              color: _getStatusColor(statusText, isProcess),
            ),
            Expanded(
              child: Column(
                children: [
                  // Header Status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _getHeaderBgColor(statusText, isProcess),
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          statusIcon,
                          width: 30,
                          height: 30,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            statusLow == 'selesai' || statusLow == 'complete'
                                ? Icons.check_circle_outline
                                : Icons.schedule,
                            color: textColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          displayStatus,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          time,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: textColor.withValues(alpha: 0.7),
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
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 70,
                                  height: 70,
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
                                  fontSize: 16,
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
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                itemName,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(
                                color: badgeColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                badgeText,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
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
            ),
          ],
        ),
      ),
    );
  }
}
