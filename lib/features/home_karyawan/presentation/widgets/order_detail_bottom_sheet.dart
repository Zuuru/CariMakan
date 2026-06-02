import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OrderDetailBottomSheet extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final VoidCallback onMulaiProses;
  final VoidCallback onTandaiSiap;
  final VoidCallback onScanQR;

  const OrderDetailBottomSheet({
    Key? key,
    required this.orderData,
    required this.onMulaiProses,
    required this.onTandaiSiap,
    required this.onScanQR,
  }) : super(key: key);

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu':
        return const Color(0xFFE3861B); // Orange
      case 'diproses':
        return const Color(0xFF1D4ED8); // Blue
      case 'siap':
        return const Color(0xFF10B981); // Green
      default:
        return const Color(0xFF989898);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = orderData['status'] as String;
    final type = orderData['type'] as String;
    final items = orderData['items'] as List<Map<String, dynamic>>;
    final notes = orderData['notes'] as String?;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle Bar
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Header: Queue & Type
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Order ${orderData['queueNumber']}',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1C1C1C),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
          
          Text(
            '${orderData['type']} • ${orderData['tableOrPickupInfo']} • ${orderData['time']}',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFF3F4F6), thickness: 1),
          const SizedBox(height: 16),
          
          // Items List
          Text(
            'Daftar Pesanan',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1C1C1C),
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${item['qty']}x',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFB72B31),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'],
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1C1C1C),
                        ),
                      ),
                      if (item['note'] != null && item['note'].isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Catatan: ${item['note']}',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          )),
          
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFEE2E2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Color(0xFFEF4444)),
                      const SizedBox(width: 8),
                      Text(
                        'Catatan Tambahan',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notes,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: const Color(0xFF7F1D1D),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 32),
          
          // Actions
          _buildActionButtons(status, type),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String status, String type) {
    if (status.toLowerCase() == 'menunggu') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onMulaiProses,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1D4ED8), // Blue for process
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            'Mulai Proses',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    } else if (status.toLowerCase() == 'diproses') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTandaiSiap,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981), // Green for ready
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            'Tandai Siap',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    } else if (status.toLowerCase() == 'siap' && type.toLowerCase() == 'take away') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onScanQR,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB72B31), // Red for final action
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.qr_code_scanner, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Scan QR Pickup',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Completed or Dine-In ready (maybe just informational)
      return Center(
        child: Text(
          'Pesanan sudah siap',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280),
          ),
        ),
      );
    }
  }
}
