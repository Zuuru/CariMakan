import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class UlasanRestoCard extends StatefulWidget {
  final String? restoId;
  final bool isCustomer;

  const UlasanRestoCard({
    Key? key,
    this.restoId,
    this.isCustomer = false,
  }) : super(key: key);

  @override
  State<UlasanRestoCard> createState() => _UlasanRestoCardState();
}

class _UlasanRestoCardState extends State<UlasanRestoCard> {
  String _selectedFilter = 'Semua'; // 'Semua', 'Positif', 'Kritik'

  // Get color for avatar based on name initials
  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFFD33400), // Red
      const Color(0xFF007AFF), // Blue
      const Color(0xFF34C759), // Green
      const Color(0xFFFF9500), // Orange
      const Color(0xFF5856D6), // Purple
    ];
    int hash = name.codeUnits.fold(0, (prev, element) => prev + element);
    return colors[hash % colors.length];
  }

  // Show dialog for owner to reply to a review
  void _showReplyDialog(String orderId, String namaPelanggan, String ulasan) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Balas Ulasan $namaPelanggan',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '"$ulasan"',
                style: GoogleFonts.outfit(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Tulis balasan Anda di sini...',
                  hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD33400)),
                  ),
                ),
                style: GoogleFonts.outfit(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: GoogleFonts.outfit(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (textController.text.trim().isNotEmpty) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('orders')
                        .doc(orderId)
                        .update({'balasan_owner': textController.text.trim()});
                    
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Balasan untuk $namaPelanggan berhasil dikirim!',
                            style: GoogleFonts.outfit(),
                          ),
                          backgroundColor: const Color(0xFF34C759),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Gagal mengirim balasan: $e',
                            style: GoogleFonts.outfit(),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD33400),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Kirim',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.restoId != null) {
      return _buildContent(widget.restoId!);
    }

    // If restoId is not provided (e.g. from owner dashboard), fetch it using current user's UID
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('restaurants')
          .where('owner_id', isEqualTo: uid)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFD33400)));
        }
        if (snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        final realRestoId = snapshot.data!.docs.first.id;
        return _buildContent(realRestoId);
      },
    );
  }

  Widget _buildContent(String restoId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('restaurants').doc(restoId).snapshots(),
      builder: (context, restoSnapshot) {
        if (restoSnapshot.hasError) {
          return Center(child: Text('Error: ${restoSnapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        if (!restoSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFD33400)));
        }
        if (!restoSnapshot.data!.exists) {
          return Center(
            child: Text(
              'Restoran tidak ditemukan',
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          );
        }

        final restoData = restoSnapshot.data!.data() as Map<String, dynamic>? ?? {};
        final avgRating = (restoData['avg_rating'] as num?)?.toDouble() ?? 0.0;
        final totalReview = (restoData['total_review'] as num?)?.toInt() ?? 0;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('resto_id', isEqualTo: restoId)
              .where('sudah_direview', isEqualTo: true)
              .snapshots(),
          builder: (context, reviewsSnapshot) {
            if (reviewsSnapshot.hasError) {
              return Center(child: Text('Error ulasan: ${reviewsSnapshot.error}', style: const TextStyle(color: Colors.red)));
            }
            if (!reviewsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFD33400)));
            }

            final allDocs = reviewsSnapshot.data!.docs;
            // Sort client-side to avoid needing a Firestore composite index
            final sortedDocs = allDocs.toList()..sort((a, b) {
              final dataA = a.data() as Map<String, dynamic>;
              final dataB = b.data() as Map<String, dynamic>;
              final timeA = dataA['reviewed_at'] as Timestamp?;
              final timeB = dataB['reviewed_at'] as Timestamp?;
              if (timeA == null && timeB == null) return 0;
              if (timeA == null) return 1;
              if (timeB == null) return -1;
              return timeB.compareTo(timeA); // descending
            });

            final allReviews = sortedDocs.map((d) => d.data() as Map<String, dynamic>..['id'] = d.id).toList();

            // Calculate exact averages based on all returned reviews for the aspect bars
            double totalPelayanan = 0;
            double totalMakanan = 0;
            double totalFasilitas = 0;
            
            int count5 = 0;
            int count4 = 0;
            int countKritik = 0;

            for (var r in allReviews) {
              totalPelayanan += (r['rating_pelayanan'] as num?)?.toDouble() ?? 0;
              totalMakanan += (r['rating_makanan'] as num?)?.toDouble() ?? 0;
              totalFasilitas += (r['rating_fasilitas'] as num?)?.toDouble() ?? 0;
              
              final total = (r['rating_total'] as num?)?.toDouble() ?? 0;
              if (total >= 4.5) {
                count5++;
              } else if (total >= 3.5) {
                count4++;
              } else {
                countKritik++;
              }
            }

            final len = allReviews.isNotEmpty ? allReviews.length : 1;
            final avgPelayanan = totalPelayanan / len;
            final avgMakanan = totalMakanan / len;
            final avgFasilitas = totalFasilitas / len;

            // Filter reviews
            final filteredReviews = allReviews.where((review) {
              final rating = (review['rating_total'] as num?)?.toDouble() ?? 0;
              if (_selectedFilter == 'Positif') {
                return rating >= 4.0;
              } else if (_selectedFilter == 'Kritik') {
                return rating <= 3.0;
              }
              return true; // 'Semua'
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Review & Ulasan',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    if (!widget.isCustomer)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.analytics_outlined, size: 14, color: Color(0xFFD33400)),
                            const SizedBox(width: 4),
                            Text(
                              'Analisis Aktif',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFD33400),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. ANALYTICS ROW (AVERAGE RATING & PROGRESS BARS)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Left side: Big Rating
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    avgRating.toStringAsFixed(1),
                                    style: GoogleFonts.outfit(
                                      fontSize: 42,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '/5',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: List.generate(5, (index) {
                                  return Icon(
                                    index < avgRating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                                    color: Colors.amber,
                                    size: 18,
                                  );
                                }),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$totalReview Ulasan',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF8C8C8C),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 24),
                          
                          // Right side: Rating Distribution Bars
                          Expanded(
                            child: widget.isCustomer
                                ? Column(
                                    children: [
                                      _buildAspectRow('Pelayanan', avgPelayanan),
                                      const SizedBox(height: 6),
                                      _buildAspectRow('Makanan', avgMakanan),
                                      const SizedBox(height: 6),
                                      _buildAspectRow('Fasilitas', avgFasilitas),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      _buildDistributionRow('5 ★', allReviews.isEmpty ? 0 : count5 / allReviews.length, '${allReviews.isEmpty ? 0 : (count5 / allReviews.length * 100).round()}%'),
                                      const SizedBox(height: 4),
                                      _buildDistributionRow('4 ★', allReviews.isEmpty ? 0 : count4 / allReviews.length, '${allReviews.isEmpty ? 0 : (count4 / allReviews.length * 100).round()}%'),
                                      const SizedBox(height: 4),
                                      _buildDistributionRow('Kritik', allReviews.isEmpty ? 0 : countKritik / allReviews.length, '${allReviews.isEmpty ? 0 : (countKritik / allReviews.length * 100).round()}%'),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Divider(color: Color(0xFFEEEEEE), thickness: 1),
                      ),
                      
                      // 2. FILTER TABS
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterTab('Semua', allReviews.length),
                            const SizedBox(width: 8),
                            _buildFilterTab('Positif', count5 + count4),
                            const SizedBox(width: 8),
                            _buildFilterTab('Kritik', countKritik),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 3. REVIEWS LIST
                      filteredReviews.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24.0),
                                child: Text(
                                  'Tidak ada ulasan dalam kategori ini',
                                  style: GoogleFonts.outfit(
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredReviews.length,
                              separatorBuilder: (context, index) => const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.0),
                                child: Divider(color: Color(0xFFF5F5F5), thickness: 1),
                              ),
                              itemBuilder: (context, index) {
                                final review = filteredReviews[index];
                                return _buildReviewItem(review);
                              },
                            ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAspectRow(String label, double val) {
    return Row(
      children: [
        SizedBox(
          width: 55,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: val / 5.0,
              backgroundColor: const Color(0xFFEEEEEE),
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFFD33400).withValues(alpha: 0.8),
              ),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 20,
          child: Text(
            val.toStringAsFixed(1),
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildDistributionRow(String label, double val, String percentText) {
    return Row(
      children: [
        SizedBox(
          width: 42,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: val,
              backgroundColor: const Color(0xFFEEEEEE),
              valueColor: AlwaysStoppedAnimation<Color>(
                label == 'Kritik' ? Colors.red.shade400 : Colors.amber.shade600,
              ),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 30,
          child: Text(
            percentText,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTab(String filterName, int count) {
    final isSelected = _selectedFilter == filterName;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filterName;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD33400) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFD33400) : const Color(0xFFDDDDDD),
          ),
        ),
        child: Row(
          children: [
            Text(
              filterName == 'Semua'
                  ? 'Semua'
                  : filterName == 'Positif'
                      ? 'Positif (⭐ 4-5)'
                      : 'Kritik/Saran (⭐ 1-3)',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey[800],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    String nama = review['userName'] ?? 'Customer';
    final parts = nama.split(' ');
    if (widget.isCustomer && parts.length > 1) {
      nama = '${parts[0]} ${parts[1][0]}.';
    }

    final initials = nama
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join('');
    final avatarColor = _getAvatarColor(nama);
    
    final rating = (review['rating_total'] as num?)?.toDouble() ?? 0.0;
    final timestamp = review['reviewed_at'] as Timestamp?;
    String waktu = '';
    if (timestamp != null) {
      waktu = DateFormat('dd MMM yyyy').format(timestamp.toDate().toLocal());
    }
    
    final ulasan = review['komentar'] as String? ?? '';
    final balasanOwner = review['balasan_owner'] as String?;
    final tags = (review['selected_tags'] as List?)?.cast<String>() ?? [];
    
    final menuDipesan = review['menuName'] ?? 'Pesanan';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row: Avatar & Name & Date
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: avatarColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: avatarColor,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nama,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    waktu,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            // Star rating row
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: Colors.amber,
                  size: 16,
                );
              }),
            ),
          ],
        ),
        
        if (ulasan.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            ulasan,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
        
        const SizedBox(height: 8),
        
        // Tags
        if (tags.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tags.map((tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
              ),
              child: Text(
                tag,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF10B981),
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 10),
        ],
        
        // Tag ordered items
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.local_pizza_outlined,
                size: 14,
                color: Color(0xFFD33400),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  menuDipesan,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 10),
        
        // Owner Reply Box OR Reply Button
        balasanOwner != null
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F8FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2ECFF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 14,
                          color: Color(0xFF007AFF),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Balasan Resto',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF007AFF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      balasanOwner,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              )
            : (!widget.isCustomer)
                ? Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _showReplyDialog(review['id'], nama, ulasan),
                      icon: const Icon(Icons.reply, size: 14, color: Color(0xFFD33400)),
                      label: Text(
                        'Balas Ulasan',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFD33400),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
      ],
    );
  }
}
