import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carimakan/core/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carimakan/features/map/services/firestore_service.dart';
import 'package:carimakan/features/map/models/restaurant.dart';
import 'package:carimakan/features/home/presentation/pages/resto_page.dart';

class CategoryProductsPage extends StatefulWidget {
  final String categoryName;

  const CategoryProductsPage({super.key, required this.categoryName});

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _filteredMenus = [];

  @override
  void initState() {
    super.initState();
    _loadMenus();
  }

  Future<void> _loadMenus() async {
    try {
      // Load all restaurants to map resto_id to Restaurant data
      final restos = await _firestoreService.getRestaurants();
      final Map<String, Restaurant> restoMap = {
        for (var r in restos) r.id: r
      };

      // Load all menus
      final menusSnapshot = await FirebaseFirestore.instance.collection('menus').get();
      
      final categoryLower = widget.categoryName.toLowerCase();
      List<String> keywords = [categoryLower];
      
      // Expand keywords based on category name
      if (categoryLower.contains('nasi')) keywords.addAll(['nasi']);
      else if (categoryLower.contains('minuman')) keywords.addAll(['minuman', 'es', 'teh', 'kopi', 'jus']);
      else if (categoryLower.contains('dessert')) keywords.addAll(['dessert', 'kue', 'manis', 'ice cream', 'es krim']);
      else if (categoryLower.contains('geprek')) keywords.addAll(['geprek']);
      else if (categoryLower.contains('bakso')) keywords.addAll(['bakso']);
      else if (categoryLower.contains('pizza')) keywords.addAll(['pizza']);
      else if (categoryLower.contains('cepat saji')) keywords.addAll(['burger', 'kentang', 'sosis', 'nugget', 'cepat saji', 'fastfood']);
      else if (categoryLower.contains('ayam')) keywords.addAll(['ayam', 'chicken']);
      else if (categoryLower.contains('kopi')) keywords.addAll(['kopi', 'coffee', 'latte', 'espresso']);

      List<Map<String, dynamic>> results = [];

      for (var doc in menusSnapshot.docs) {
        final data = doc.data();
        final name = (data['nama'] as String? ?? '').toLowerCase();
        final cat = (data['kategori'] as String? ?? '').toLowerCase();
        final restoId = data['resto_id'] as String?;

        bool match = false;
        for (var keyword in keywords) {
          if (name.contains(keyword) || cat.contains(keyword)) {
            match = true;
            break;
          }
        }

        if (match && restoId != null && restoMap.containsKey(restoId)) {
          results.add({
            'menu': data,
            'menuId': doc.id,
            'restaurant': restoMap[restoId],
          });
        }
      }

      if (mounted) {
        setState(() {
          _filteredMenus = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading category menus: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.categoryName,
          style: GoogleFonts.poppins(
            color: AppColors.textMain,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _filteredMenus.isEmpty
              ? _buildEmptyState()
              : _buildList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              'Sorry untuk ${widget.categoryName} masih belum tersedia nihh \uD83D\uDE22',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _filteredMenus.length,
      itemBuilder: (context, index) {
        final item = _filteredMenus[index];
        final menuData = item['menu'] as Map<String, dynamic>;
        final resto = item['restaurant'] as Restaurant;
        
        final String name = menuData['nama'] ?? 'Unknown';
        final double rawPrice = (menuData['harga'] ?? 0).toDouble();
        final String imageUrl = menuData['image_url'] ?? '';

        // format price
        final String valStr = rawPrice.toInt().toString();
        final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
        final String formatted = valStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
        final priceStr = 'Rp $formatted';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RestoPage(
                  name: resto.name,
                  imageUrl: resto.imageUrl,
                  distance: '1,2 km', // Mock distance as in search_page
                  queueCount: resto.queueCount,
                  restoId: resto.id,
                  initialRating: resto.rating,
                  initialReviewCount: resto.reviewCount,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.01),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrl.isEmpty
                      ? _buildFallbackImage()
                      : imageUrl.startsWith('http')
                          ? Image.network(
                              imageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
                            )
                          : Image.asset(
                              imageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
                            ),
                ),
                const SizedBox(width: 12),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        priceStr,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Restaurant info row
                      Row(
                        children: [
                          Icon(Icons.storefront_outlined, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              resto.name,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
        );
      },
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey.shade100,
      child: const Icon(Icons.restaurant, color: Colors.grey, size: 30),
    );
  }
}
