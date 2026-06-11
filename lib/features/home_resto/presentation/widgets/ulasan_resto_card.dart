import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MockReview {
  final String id;
  final String namaPelanggan;
  final double rating;
  final String waktu;
  final String ulasan;
  final String menuDipesan;
  final String varianDipesan;
  String? balasanOwner;

  MockReview({
    required this.id,
    required this.namaPelanggan,
    required this.rating,
    required this.waktu,
    required this.ulasan,
    required this.menuDipesan,
    required this.varianDipesan,
    this.balasanOwner,
  });
}

class UlasanRestoCard extends StatefulWidget {
  const UlasanRestoCard({Key? key}) : super(key: key);

  @override
  State<UlasanRestoCard> createState() => _UlasanRestoCardState();
}

class _UlasanRestoCardState extends State<UlasanRestoCard> {
  String _selectedFilter = 'Semua'; // 'Semua', 'Positif', 'Kritik'
  
  // In-memory list of mock reviews
  late List<MockReview> _reviews;

  @override
  void initState() {
    super.initState();
    _reviews = [
      MockReview(
        id: '1',
        namaPelanggan: 'Ahmad Fauzi',
        rating: 5.0,
        waktu: '2 jam yang lalu',
        ulasan: 'Mie ayam level 3-nya pas mantap banget! Pedes gurihnya juara. Pangsit gorengnya juga renyah poll. Porsi pas buat makan siang.',
        menuDipesan: 'Mie Ayam',
        varianDipesan: 'Pedes: Level 3, Toping: Pangsit Goreng',
      ),
      MockReview(
        id: '2',
        namaPelanggan: 'Jessica Putri',
        rating: 4.0,
        waktu: 'Kemarin',
        ulasan: 'Es teh manisnya segar banget pas diminum siang-siang. Untuk chicken cordon bleu-nya rasanya enak, tapi keju di dalamnya agak asin dikit. Overall worth it dan ngenyangin.',
        menuDipesan: 'Chicken Cordon Bleu & Es Teh',
        varianDipesan: 'Minuman: Manis, Ukuran: Sedang',
        balasanOwner: 'Halo Kak Jessica, terima kasih atas masukannya! Keasinan keju mozarella di dalam ayam akan kami evaluasi lagi ke tim dapur ya. Ditunggu orderan berikutnya!',
      ),
      MockReview(
        id: '3',
        namaPelanggan: 'Budi Santoso',
        rating: 3.0,
        waktu: '3 hari yang lalu',
        ulasan: 'Rasa makanan enak tidak mengecewakan, cuman antrean pas jam makan siang cukup panjang dan pelayanannya agak lambat. Semoga ke depannya bisa dipercepat kinerjanya.',
        menuDipesan: 'Mie Ayam Goreng',
        varianDipesan: 'Pedes: Level 1, Toping: Bakso',
      ),
      MockReview(
        id: '4',
        namaPelanggan: 'Clara Devina',
        rating: 5.0,
        waktu: '4 hari yang lalu',
        ulasan: 'Butterscotch sea salt kopi-nya rasanya unik banget! Perpaduan manis gurihnya gurih asin sea salt-nya dapet banget. Tempatnya juga estetik nyaman buat nugas.',
        menuDipesan: 'Butterscotch Sea Salt',
        varianDipesan: 'Es: Sedikit, Gula: Normal',
      ),
      MockReview(
        id: '5',
        namaPelanggan: 'Rian Hidayat',
        rating: 2.0,
        waktu: '1 minggu yang lalu',
        ulasan: 'Ayam goreng spesialnya agak kurang matang di bagian dekat tulangnya, masih kemerahan. Tolong koki lebih teliti lagi saat menggoreng. Sambalnya sih enak pedes.',
        menuDipesan: 'Ayam Goreng Spesial',
        varianDipesan: 'Bagian: Paha Atas, Sambal: Bawang',
      ),
    ];
  }

  // Get color for avatar based on name initials
  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFFED001E), // Red
      const Color(0xFF007AFF), // Blue
      const Color(0xFF34C759), // Green
      const Color(0xFFFF9500), // Orange
      const Color(0xFF5856D6), // Purple
    ];
    int hash = name.codeUnits.fold(0, (prev, element) => prev + element);
    return colors[hash % colors.length];
  }

  // Show dialog for owner to reply to a review
  void _showReplyDialog(MockReview review) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Balas Ulasan ${review.namaPelanggan}',
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
                '"${review.ulasan}"',
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
                    borderSide: const BorderSide(color: Color(0xFFED001E)),
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
              onPressed: () {
                if (textController.text.trim().isNotEmpty) {
                  setState(() {
                    review.balasanOwner = textController.text.trim();
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Balasan untuk ${review.namaPelanggan} berhasil dikirim!',
                        style: GoogleFonts.outfit(),
                      ),
                      backgroundColor: const Color(0xFF34C759),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFED001E),
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
    // Filter reviews
    final filteredReviews = _reviews.where((review) {
      if (_selectedFilter == 'Positif') {
        return review.rating >= 4.0;
      } else if (_selectedFilter == 'Kritik') {
        return review.rating <= 3.0;
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.analytics_outlined, size: 14, color: Color(0xFFED001E)),
                  const SizedBox(width: 4),
                  Text(
                    'Analisis Aktif',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFED001E),
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
                color: Colors.black.withOpacity(0.04),
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
                            '4.8',
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
                          return const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 18,
                          );
                        }),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '1,248 Ulasan',
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
                    child: Column(
                      children: [
                        _buildDistributionRow('5 ★', 0.82, '82%'),
                        const SizedBox(height: 4),
                        _buildDistributionRow('4 ★', 0.12, '12%'),
                        const SizedBox(height: 4),
                        _buildDistributionRow('Kritik', 0.06, '6%'),
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
              Row(
                children: [
                  _buildFilterTab('Semua', _reviews.length),
                  const SizedBox(width: 8),
                  _buildFilterTab('Positif', _reviews.where((r) => r.rating >= 4).length),
                  const SizedBox(width: 8),
                  _buildFilterTab('Kritik', _reviews.where((r) => r.rating <= 3).length),
                ],
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
          color: isSelected ? const Color(0xFFED001E) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFED001E) : const Color(0xFFDDDDDD),
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
                color: isSelected ? Colors.white.withOpacity(0.25) : const Color(0xFFEEEEEE),
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

  Widget _buildReviewItem(MockReview review) {
    final initials = review.namaPelanggan
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join('');
    final avatarColor = _getAvatarColor(review.namaPelanggan);

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
                color: avatarColor.withOpacity(0.15),
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
                    review.namaPelanggan,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    review.waktu,
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
                  Icons.star_rounded,
                  color: index < review.rating ? Colors.amber : Colors.grey[300],
                  size: 16,
                );
              }),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Review comment
        Text(
          review.ulasan,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: Colors.black87,
            height: 1.4,
          ),
        ),
        
        const SizedBox(height: 8),
        
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
                color: Color(0xFFED001E),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '${review.menuDipesan} (${review.varianDipesan})',
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
        review.balasanOwner != null
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
                          'Balasan Anda',
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
                      review.balasanOwner!,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              )
            : Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _showReplyDialog(review),
                  icon: const Icon(Icons.reply, size: 14, color: Color(0xFFED001E)),
                  label: Text(
                    'Balas Ulasan',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFED001E),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
      ],
    );
  }
}
