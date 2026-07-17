import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carimakan/core/theme/app_colors.dart';
import 'package:carimakan/core/widgets/custom_back_button.dart';
import 'resto_page.dart';
import 'package:carimakan/features/map/services/firestore_service.dart';
import 'package:carimakan/features/map/models/restaurant.dart';

class SearchPage extends StatefulWidget {
  final String? initialQuery;
  const SearchPage({super.key, this.initialQuery});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  String _searchQuery = '';
  String _selectedFilter = 'Semua'; // 'Semua', 'Restoran', 'Menu'
  bool _isLoading = true;

  List<Restaurant> _restaurants = [];
  List<SearchMenuItem> _menuItems = [];

  List<Restaurant> _filteredRestaurants = [];
  List<SearchMenuItem> _filteredMenuItems = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _searchQuery = widget.initialQuery!;
    }
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Load restaurants from Firestore
      List<Restaurant> loadedRestos = await _firestoreService.getRestaurants();
      if (loadedRestos.isEmpty) {
        // Fallback to mock restaurants
        loadedRestos = await _firestoreService.getMockRestaurants();
      }

      // Build menu items mapped to these restaurants
      final List<SearchMenuItem> loadedMenus = [];
      for (var resto in loadedRestos) {
        final restoMenus = _getMenusForRestaurant(resto);
        loadedMenus.addAll(restoMenus);
      }

      if (mounted) {
        setState(() {
          _restaurants = loadedRestos;
          _menuItems = loadedMenus;
          _isLoading = false;
          _applySearch();
        });
      }
    } catch (e) {
      debugPrint("Error loading search data: $e");
      // Load mock as safety net
      final mockRestos = await _firestoreService.getMockRestaurants();
      final List<SearchMenuItem> mockMenus = [];
      for (var resto in mockRestos) {
        mockMenus.addAll(_getMenusForRestaurant(resto));
      }

      if (mounted) {
        setState(() {
          _restaurants = mockRestos;
          _menuItems = mockMenus;
          _isLoading = false;
          _applySearch();
        });
      }
    }
  }

  List<SearchMenuItem> _getMenusForRestaurant(Restaurant resto) {
    // We map mock menus specifically based on restaurant name or category
    if (resto.name.contains('Ideologist')) {
      return [
        SearchMenuItem(
          id: '${resto.id}_m1',
          name: 'Butterscotch Sea Salt',
          price: 'Rp 37.000',
          imageUrl: 'assets/images/menu/minuman/images.jpg',
          category: 'Minuman',
          restaurant: resto,
        ),
        SearchMenuItem(
          id: '${resto.id}_m2',
          name: 'Chicken Cordon Bleu',
          price: 'Rp 45.000',
          imageUrl: 'assets/images/menu/makanan/Chicken Cordon Bleu.jpg',
          category: 'Makanan',
          restaurant: resto,
        ),
        SearchMenuItem(
          id: '${resto.id}_m3',
          name: 'Caramel Macchiato',
          price: 'Rp 35.000',
          imageUrl: 'https://images.unsplash.com/photo-1541167760496-1628856ab772?w=500',
          category: 'Minuman',
          restaurant: resto,
        ),
        SearchMenuItem(
          id: '${resto.id}_m4',
          name: 'Croissant Chocolate',
          price: 'Rp 28.000',
          imageUrl: 'https://images.unsplash.com/photo-1549931319-a545dcf3bc73?w=500',
          category: 'Makanan',
          restaurant: resto,
        ),
      ];
    } else if (resto.name.contains('Parjo') || resto.name.contains('Burjo')) {
      return [
        SearchMenuItem(
          id: '${resto.id}_m1',
          name: 'Nasi Goreng Parjo',
          price: 'Rp 15.000',
          imageUrl: 'https://images.unsplash.com/photo-1601050690597-df056fb4ce78?w=500',
          category: 'Makanan',
          restaurant: resto,
        ),
        SearchMenuItem(
          id: '${resto.id}_m2',
          name: 'Mie Dog Dog',
          price: 'Rp 13.000',
          imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=500',
          category: 'Makanan',
          restaurant: resto,
        ),
        SearchMenuItem(
          id: '${resto.id}_m3',
          name: 'Es Teh Manis',
          price: 'Rp 3.000',
          imageUrl: 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=500',
          category: 'Minuman',
          restaurant: resto,
        ),
        SearchMenuItem(
          id: '${resto.id}_m4',
          name: 'Nasi Ayam Bali',
          price: 'Rp 18.000',
          imageUrl: 'https://images.unsplash.com/photo-1562967914-608f82629710?w=500',
          category: 'Makanan',
          restaurant: resto,
        ),
      ];
    } else {
      // Warmindo Berkah or general fallback
      return [
        SearchMenuItem(
          id: '${resto.id}_m1',
          name: 'Indomie Goreng Tante',
          price: 'Rp 10.000',
          imageUrl: 'https://images.unsplash.com/photo-1612927601601-6638404737ce?w=500',
          category: 'Makanan',
          restaurant: resto,
        ),
        SearchMenuItem(
          id: '${resto.id}_m2',
          name: 'Nasi Omelet',
          price: 'Rp 12.000',
          imageUrl: 'https://images.unsplash.com/photo-1518492104633-130d0cc84637?w=500',
          category: 'Makanan',
          restaurant: resto,
        ),
        SearchMenuItem(
          id: '${resto.id}_m3',
          name: 'Es Jeruk',
          price: 'Rp 5.000',
          imageUrl: 'https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=500',
          category: 'Minuman',
          restaurant: resto,
        ),
        SearchMenuItem(
          id: '${resto.id}_m4',
          name: 'Gorengan Tempe',
          price: 'Rp 2.000',
          imageUrl: 'https://images.unsplash.com/photo-1600271886742-f049cd451bba?w=500',
          category: 'Makanan',
          restaurant: resto,
        ),
      ];
    }
  }

  void _applySearch() {
    setState(() {
      if (_searchQuery.trim().isEmpty) {
        _filteredRestaurants = [];
        _filteredMenuItems = [];
        return;
      }

      final queryLower = _searchQuery.toLowerCase();

      // Filter Restaurants
      _filteredRestaurants = _restaurants.where((resto) {
        return resto.name.toLowerCase().contains(queryLower) ||
            resto.category.toLowerCase().contains(queryLower) ||
            resto.address.toLowerCase().contains(queryLower);
      }).toList();

      // Filter Menus
      _filteredMenuItems = _menuItems.where((menu) {
        return menu.name.toLowerCase().contains(queryLower) ||
            menu.category.toLowerCase().contains(queryLower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(130),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      // Back Button
                      const CustomBackButton(),
                      const SizedBox(width: 12),
                      // Search Bar Field
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _searchController,
                            autofocus: widget.initialQuery == null,
                            onChanged: (value) {
                              _searchQuery = value;
                              _applySearch();
                            },
                            decoration: InputDecoration(
                              hintText: 'Cari resto atau menu...',
                              hintStyle: GoogleFonts.poppins(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18, color: Colors.black54),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = '';
                                          _applySearch();
                                        });
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppColors.textMain,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Filter Tags
                _buildFilterChips(),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : _buildBodyContent(),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['Semua', 'Restoran', 'Menu'];
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                filter,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                }
              },
              selectedColor: AppColors.primary,
              backgroundColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                  width: 0.8,
                ),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_searchQuery.trim().isEmpty) {
      return _buildEmptyState();
    }

    final showResto = _selectedFilter == 'Semua' || _selectedFilter == 'Restoran';
    final showMenu = _selectedFilter == 'Semua' || _selectedFilter == 'Menu';

    final totalRestoCount = showResto ? _filteredRestaurants.length : 0;
    final totalMenuCount = showMenu ? _filteredMenuItems.length : 0;

    if (totalRestoCount == 0 && totalMenuCount == 0) {
      return _buildNoResultsState();
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        if (showResto && _filteredRestaurants.isNotEmpty) ...[
          _buildSectionHeader('Restoran Terdekat'),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredRestaurants.length,
            itemBuilder: (context, index) {
              return _buildRestaurantCard(_filteredRestaurants[index]);
            },
          ),
          const SizedBox(height: 16),
        ],
        if (showMenu && _filteredMenuItems.isNotEmpty) ...[
          _buildSectionHeader('Menu Pilihan'),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredMenuItems.length,
            itemBuilder: (context, index) {
              return _buildMenuCard(_filteredMenuItems[index]);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textMain,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Yuk, cari kuliner favoritmu!',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                'Ketik nama restoran atau menu makanan yang ingin kamu temukan.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Ups! Hasil tidak ditemukan',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                'Coba gunakan kata kunci lain atau periksa kembali filter pencarianmu.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantCard(Restaurant resto) {
    // Custom distance mapping to match mock data or set dynamically
    final distanceStr = resto.id == 'mock_1'
        ? '2,14 km'
        : resto.id == 'mock_2'
            ? '0,95 km'
            : '1,20 km';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestoPage(
              name: resto.name,
              imageUrl: resto.imageUrl,
              distance: distanceStr,
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
          color: AppColors.cardBackground.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: resto.imageUrl.isEmpty
                  ? _buildFallbackImage()
                  : resto.imageUrl.startsWith('http')
                      ? Image.network(
                          resto.imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
                        )
                      : Image.asset(
                          resto.imageUrl,
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
                    resto.name,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppColors.starColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${resto.rating}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.circle,
                        size: 4,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        distanceStr,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Open/Closed Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: resto.isOpen
                              ? const Color(0xFFE6F4EA)
                              : const Color(0xFFFCE8E6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          resto.isOpen ? 'Buka' : 'Tutup',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: resto.isOpen ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Queue count
                      Row(
                        children: [
                          const Icon(Icons.people_outline, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '${resto.queueCount} Antrean',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
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
  }

  Widget _buildMenuCard(SearchMenuItem item) {
    // Custom distance mapping to match mock data or set dynamically
    final distanceStr = item.restaurant.id == 'mock_1'
        ? '2,14 km'
        : item.restaurant.id == 'mock_2'
            ? '0,95 km'
            : '1,20 km';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestoPage(
              name: item.restaurant.name,
              imageUrl: item.restaurant.imageUrl,
              distance: distanceStr,
              queueCount: item.restaurant.queueCount,
              restoId: item.restaurant.id,
              initialRating: item.restaurant.rating,
              initialReviewCount: item.restaurant.reviewCount,
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
              child: item.imageUrl.isEmpty
                  ? _buildFallbackImage()
                  : item.imageUrl.startsWith('http')
                      ? Image.network(
                          item.imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
                        )
                      : Image.asset(
                          item.imageUrl,
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
                    item.name,
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
                    item.price,
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
                          item.restaurant.name,
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

class SearchMenuItem {
  final String id;
  final String name;
  final String price;
  final String imageUrl;
  final String category;
  final Restaurant restaurant;

  SearchMenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.restaurant,
  });
}
