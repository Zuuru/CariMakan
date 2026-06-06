import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OrderKaryawanCard extends StatelessWidget {
  final String queueNumber;
  final String type; // 'Dine In' or 'Take Away'
  final String tableOrPickupInfo; // 'Meja 01' or '12:30'
  final List<Map<String, dynamic>> items; // { 'name': 'Menu', 'qty': 2 }
  final String orderTime;
  final String status; // 'Menunggu', 'Diproses', 'Siap'
  final VoidCallback onTap;

  const OrderKaryawanCard({
    Key? key,
    required this.queueNumber,
    required this.type,
    required this.tableOrPickupInfo,
    required this.items,
    required this.orderTime,
    required this.status,
    required this.onTap,
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

  Color _getTypeColor(String type) {
    return type.toLowerCase() == 'dine in'
        ? const Color(0xFFED001E)
        : const Color(0xFFE3861B);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Queue Number Box
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                queueNumber,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1C1C1C),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getTypeColor(type),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              type,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            tableOrPickupInfo,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        orderTime,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Render up to 2 items
                  ...items.take(2).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      '${item['qty']}x ${item['name']}',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF4B5563),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
                  if (items.length > 2)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        '+ ${items.length - 2} item lainnya',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF9CA3AF),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Status Indicator
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
