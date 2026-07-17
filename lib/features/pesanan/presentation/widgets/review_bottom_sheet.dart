import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../data/review_service.dart';

/// Predefined review tags (bisa nanti diambil dari Firestore jika ada koleksi TAG_KATEGORI)
const List<Map<String, dynamic>> _kDefaultTags = [
  {'emoji': '📶', 'label': 'WiFi Cepet'},
  {'emoji': '😋', 'label': 'Makanan Enak'},
  {'emoji': '🪑', 'label': 'Tempat Luas'},
  {'emoji': '⚡', 'label': 'Pelayanan Cepat'},
  {'emoji': '🔌', 'label': 'Colokan Banyak'},
  {'emoji': '✨', 'label': 'Resto Bersih'},
  {'emoji': '🅿️', 'label': 'Parkir Luas'},
  {'emoji': '🌿', 'label': 'Suasana Adem'},
];

/// Bottom sheet for submitting or viewing a review for a completed order.
///
/// Usage:
/// ```dart
/// ReviewBottomSheet.show(context, orderId: ..., restoId: ..., restoName: ..., orderSummary: ...);
/// ```
class ReviewBottomSheet extends StatefulWidget {
  final String orderId;
  final String restoId;
  final String restoName;
  final String orderSummary;

  /// If non-null, the order has already been reviewed — show read-only view.
  final Map<String, dynamic>? existingReview;

  const ReviewBottomSheet({
    Key? key,
    required this.orderId,
    required this.restoId,
    required this.restoName,
    required this.orderSummary,
    this.existingReview,
  }) : super(key: key);

  static Future<bool?> show(
    BuildContext context, {
    required String orderId,
    required String restoId,
    required String restoName,
    required String orderSummary,
    Map<String, dynamic>? existingReview,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReviewBottomSheet(
        orderId: orderId,
        restoId: restoId,
        restoName: restoName,
        orderSummary: orderSummary,
        existingReview: existingReview,
      ),
    );
  }

  @override
  State<ReviewBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends State<ReviewBottomSheet> {
  int _ratingPelayanan = 0;
  int _ratingMakanan = 0;
  int _ratingFasilitas = 0;
  final _commentController = TextEditingController();
  final List<String> _selectedTags = [];
  bool _isSubmitting = false;

  double get _ratingTotal => _ratingPelayanan > 0 && _ratingMakanan > 0 && _ratingFasilitas > 0
      ? (_ratingPelayanan + _ratingMakanan + _ratingFasilitas) / 3.0
      : 0.0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_ratingPelayanan == 0 || _ratingMakanan == 0 || _ratingFasilitas == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Semua rating wajib diisi! Tap bintang untuk memberi nilai.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ReviewService.submitReview(
        orderId: widget.orderId,
        restoId: widget.restoId,
        ratingPelayanan: _ratingPelayanan,
        ratingMakanan: _ratingMakanan,
        ratingFasilitas: _ratingFasilitas,
        komentar: _commentController.text.trim(),
        selectedTags: _selectedTags,
      );

      if (mounted) {
        Navigator.pop(context, true); // return true = review submitted
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ulasan berhasil dikirim! Terima kasih 🌟',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim ulasan: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReadOnly = widget.existingReview != null;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: isReadOnly
                  ? _buildReadOnlyView(widget.existingReview!)
                  : _buildReviewForm(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Form view (before reviewing) ────────────────────────────────────────
  Widget _buildReviewForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildHeader(isReadOnly: false),
        const SizedBox(height: 24),

        // Pelayanan rating
        _buildRatingSection(
          label: 'Pelayanan',
          subtitle: 'Seberapa puas dengan pelayanannya?',
          icon: Icons.support_agent_rounded,
          color: const Color(0xFF6366F1),
          value: _ratingPelayanan,
          onChanged: (v) => setState(() => _ratingPelayanan = v),
        ),
        const SizedBox(height: 20),

        // Makanan rating
        _buildRatingSection(
          label: 'Makanan',
          subtitle: 'Seberapa enak makanannya?',
          icon: Icons.restaurant_rounded,
          color: const Color(0xFFEF4444),
          value: _ratingMakanan,
          onChanged: (v) => setState(() => _ratingMakanan = v),
        ),
        const SizedBox(height: 20),

        // Fasilitas rating
        _buildRatingSection(
          label: 'Fasilitas',
          subtitle: 'Seberapa nyaman fasilitasnya?',
          icon: Icons.chair_rounded,
          color: const Color(0xFF10B981),
          value: _ratingFasilitas,
          onChanged: (v) => setState(() => _ratingFasilitas = v),
        ),
        const SizedBox(height: 24),

        // Overall rating preview
        if (_ratingTotal > 0) ...[
          _buildOverallChip(),
          const SizedBox(height: 24),
        ],

        // Comment box
        _buildCommentBox(),
        const SizedBox(height: 20),

        // Tags
        _buildTagsSection(),
        const SizedBox(height: 28),

        // Submit button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitReview,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD33400),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    'Kirim Ulasan',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ─── Read-only view (already reviewed) ──────────────────────────────────
  Widget _buildReadOnlyView(Map<String, dynamic> review) {
    final pelayanan = (review['rating_pelayanan'] as num?)?.toInt() ?? 0;
    final makanan = (review['rating_makanan'] as num?)?.toInt() ?? 0;
    final fasilitas = (review['rating_fasilitas'] as num?)?.toInt() ?? 0;
    final total = (review['rating_total'] as num?)?.toDouble() ?? 0.0;
    final komentar = review['komentar'] as String? ?? '';
    final tags = (review['selected_tags'] as List?)?.cast<String>() ?? [];
    final reviewedAt = review['reviewed_at'] as Timestamp?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(isReadOnly: true),
        const SizedBox(height: 24),

        // Overall rating
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFD33400).withValues(alpha: 0.08),
                const Color(0xFFFF6B35).withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFD33400).withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    total.toStringAsFixed(1),
                    style: GoogleFonts.outfit(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFD33400),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(5, (i) => Icon(
                          i < total.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: Colors.amber,
                          size: 20,
                        )),
                      ),
                      Text(
                        'dari 5',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAspectChip('Pelayanan', pelayanan, const Color(0xFF6366F1)),
                  _buildAspectChip('Makanan', makanan, const Color(0xFFEF4444)),
                  _buildAspectChip('Fasilitas', fasilitas, const Color(0xFF10B981)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Komentar
        if (komentar.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.format_quote_rounded, color: Color(0xFFD33400), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Komentar kamu',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFD33400),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  komentar,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Tags
        if (tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) {
              final tagData = _kDefaultTags.firstWhere(
                (t) => t['label'] == tag,
                orElse: () => {'emoji': '🏷️', 'label': tag},
              );
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD33400).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFD33400).withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  '${tagData['emoji']} ${tagData['label']}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFD33400),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Reviewed at
        if (reviewedAt != null) ...[
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 6),
              Text(
                'Ditulis ${DateFormat('dd MMM yyyy · HH:mm').format(reviewedAt.toDate().toLocal())}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 8),
      ],
    );
  }

  // ─── Shared helper widgets ────────────────────────────────────────────────
  Widget _buildHeader({required bool isReadOnly}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFD33400).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_rate_rounded,
                color: Color(0xFFD33400),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isReadOnly ? 'Ulasan Kamu' : 'Ulasan untuk ${widget.restoName}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    widget.orderSummary,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingSection({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StarRating(value: value, onChanged: onChanged, size: 26),
        ],
      ),
    );
  }

  Widget _buildOverallChip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD33400), Color(0xFFFF6B35)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            'Rating keseluruhan: ',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
          Row(
            children: List.generate(5, (i) => Icon(
              i < _ratingTotal.round() ? Icons.star_rounded : Icons.star_outline_rounded,
              color: Colors.white,
              size: 18,
            )),
          ),
          const SizedBox(width: 6),
          Text(
            '(${_ratingTotal.toStringAsFixed(1)})',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ceritakan pengalamanmu',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _commentController,
          maxLines: 3,
          maxLength: 300,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
          decoration: InputDecoration(
            hintText: 'Tuliskan komentar (opsional)...',
            hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD33400), width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pilih yang sesuai',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _kDefaultTags.map((tag) {
            final label = tag['label'] as String;
            final isSelected = _selectedTags.contains(label);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedTags.remove(label);
                  } else {
                    _selectedTags.add(label);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFD33400)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFD33400)
                        : Colors.grey[300]!,
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFD33400).withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  '${tag['emoji']} $label',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAspectChip(String label, int value, Color color) {
    return Column(
      children: [
        Row(
          children: List.generate(5, (i) => Icon(
            i < value ? Icons.star_rounded : Icons.star_outline_rounded,
            color: Colors.amber,
            size: 14,
          )),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '$value / 5',
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

// ─── Star Rating Widget ────────────────────────────────────────────────────
class _StarRating extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  const _StarRating({
    required this.value,
    required this.onChanged,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        return GestureDetector(
          onTap: () => onChanged(starIndex),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: Icon(
              starIndex <= value ? Icons.star_rounded : Icons.star_outline_rounded,
              color: starIndex <= value ? Colors.amber : Colors.grey[300],
              size: size,
            ),
          ),
        );
      }),
    );
  }
}
