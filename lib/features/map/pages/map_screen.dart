import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:carimakan/core/theme/app_colors.dart';
import '../models/restaurant.dart';
import '../services/firestore_service.dart';
import '../services/map_service.dart';
import '../widgets/restaurant_marker.dart';
import 'package:carimakan/core/widgets/custom_back_button.dart';
import 'package:carimakan/features/home/presentation/pages/resto_page.dart';

class MapScreen extends StatefulWidget {
  final String? initialSearchQuery;

  const MapScreen({super.key, this.initialSearchQuery});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final FirestoreService _firestoreService = FirestoreService();
  final MapService _mapService = MapService();

  LatLng _userLocation = const LatLng(-7.0494, 110.4382); // Default Tembalang Semarang
  bool _isLoadingLocation = true;
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  double _selectedRadius = 5.0; // 5 km default
  final TextEditingController _radiusInputController = TextEditingController(text: '5');

  List<Restaurant> _allRestaurants = [];
  List<Restaurant> _filteredRestaurants = [];
  StreamSubscription? _restoSubscription;

  final List<String> _categories = [
    'Semua',
    'Ayam',
    'Bakso',
    'Seafood',
    'Minuman',
    'Dessert'
  ];

  final List<double> _radii = [1.0, 3.0, 5.0, 10.0]; // kept for quick-select buttons

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchQuery != null) {
      _searchQuery = widget.initialSearchQuery!;
    }
    _initLocation();
    _loadRestaurants();
  }

  @override
  void dispose() {
    _restoSubscription?.cancel();
    _radiusInputController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      final position = await _mapService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
        _mapController.move(_userLocation, 15.0);
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _loadRestaurants() {
    // Stream restaurants from Firestore. Fallback to mock data if Firestore returns empty.
    _restoSubscription = _firestoreService.streamRestaurants().listen((restaurants) {
      if (restaurants.isEmpty) {
        // Mock fallback so the screen is wowed and works instantly
        _firestoreService.getMockRestaurants().then((mockList) {
          if (mounted) {
            setState(() {
              _allRestaurants = mockList;
              _applyFilters();
            });
          }
        });
      } else {
        if (mounted) {
          setState(() {
            _allRestaurants = restaurants;
            _applyFilters();
          });
        }
      }
    }, onError: (e) {
      debugPrint('Firestore stream error: $e. Using mock fallback.');
      _firestoreService.getMockRestaurants().then((mockList) {
        if (mounted) {
          setState(() {
            _allRestaurants = mockList;
            _applyFilters();
          });
        }
      });
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredRestaurants = _allRestaurants.where((resto) {
        // Search Filter
        final matchSearch = resto.name.toLowerCase().contains(_searchQuery.toLowerCase());

        // Category Filter
        final matchCategory = _selectedCategory == 'Semua' ||
            resto.category.toLowerCase() == _selectedCategory.toLowerCase();

        // Radius Filter
        final distance = _mapService.calculateDistance(
          _userLocation.latitude,
          _userLocation.longitude,
          resto.latitude,
          resto.longitude,
        );
        final matchRadius = distance <= _selectedRadius;

        return matchSearch && matchCategory && matchRadius;
      }).toList();
    });
  }

  void _showRestaurantDetails(Restaurant restaurant) {
    final distance = _mapService.calculateDistance(
      _userLocation.latitude,
      _userLocation.longitude,
      restaurant.latitude,
      restaurant.longitude,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: restaurant.imageUrl.startsWith('http')
                        ? Image.network(
                            restaurant.imageUrl,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey[200],
                              child: const Icon(Icons.restaurant, size: 40, color: Colors.grey),
                            ),
                          )
                        : Image.asset(
                            restaurant.imageUrl,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey[200],
                              child: const Icon(Icons.restaurant, size: 40, color: Colors.grey),
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          restaurant.name,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          restaurant.address,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              restaurant.rating.toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.circle,
                              size: 6,
                              color: restaurant.isOpen ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              restaurant.isOpen ? 'Buka' : 'Tutup',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: restaurant.isOpen ? Colors.green : Colors.red,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.location_on, color: AppColors.primary, size: 14),
                            const SizedBox(width: 2),
                            Text(
                              '${distance.toStringAsFixed(2)} km',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RestoPage(
                              name: restaurant.name,
                              imageUrl: restaurant.imageUrl,
                              distance: '${distance.toStringAsFixed(2)} km',
                              queueCount: restaurant.queueCount,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'Lihat Detail',
                        style: GoogleFonts.poppins(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _showQueueBookingDialog(restaurant);
                      },
                      child: Text(
                        'Ambil Antrian',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showQueueBookingDialog(Restaurant restaurant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Ambil Antrean',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda ingin mengambil antrean di ${restaurant.name}?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Berhasil mengambil antrean di ${restaurant.name}!',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(
              'Ambil',
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Generate map markers
    final List<Marker> markers = [];

    // User marker
    markers.add(
      Marker(
        point: _userLocation,
        width: 40,
        height: 40,
        child: const UserLocationMarkerWidget(),
      ),
    );

    // Restaurant markers
    for (final resto in _filteredRestaurants) {
      markers.add(
        Marker(
          point: LatLng(resto.latitude, resto.longitude),
          width: 45,
          height: 45,
          child: RestaurantMarkerWidget(
            onTap: () => _showRestaurantDetails(resto),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Flutter Map Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation,
              initialZoom: 15.0,
              maxZoom: 18.0,
              minZoom: 10.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.carimakan.app',
              ),
              MarkerLayer(markers: markers),
            ],
          ),

          // Top Overlay: Search Bar & Categories
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search & Back button row
                  Row(
                    children: [
                      const CustomBackButton(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: TextEditingController(text: _searchQuery)
                              ..selection = TextSelection.fromPosition(
                                TextPosition(offset: _searchQuery.length),
                              ),
                            onChanged: (val) {
                              _searchQuery = val;
                              _applyFilters();
                            },
                            decoration: InputDecoration(
                              hintText: 'Cari nama restoran...',
                              hintStyle: GoogleFonts.poppins(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                              prefixIcon: const Icon(Icons.search, color: Colors.grey),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Horizontal Categories
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: GestureDetector(
                            onTap: () {
                              _selectedCategory = cat;
                              _applyFilters();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  cat,
                                  style: GoogleFonts.poppins(
                                    color: isSelected ? Colors.white : Colors.black87,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Re-center button
          Positioned(
            right: 16,
            bottom: 200,
            child: FloatingActionButton(
              heroTag: 'recenter_btn',
              backgroundColor: Colors.white,
              elevation: 4,
              onPressed: () {
                _mapController.move(_userLocation, 15.0);
              },
              child: const Icon(Icons.my_location, color: AppColors.primary),
            ),
          ),

          // Radius Slider Panel at Bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Radius Pencarian',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      // Manual radius text input
                      Container(
                        width: 72,
                        height: 36,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primary, width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _radiusInputController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                ),
                                onSubmitted: (val) {
                                  final parsed = double.tryParse(val);
                                  if (parsed != null && parsed > 0 && parsed <= 50) {
                                    setState(() {
                                      _selectedRadius = parsed;
                                    });
                                    _applyFilters();
                                  } else {
                                    _radiusInputController.text = _selectedRadius.toStringAsFixed(_selectedRadius.truncateToDouble() == _selectedRadius ? 0 : 1);
                                  }
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Text(
                                'km',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('0 km', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor: Colors.grey[200],
                            thumbColor: AppColors.primary,
                            overlayColor: AppColors.primary.withValues(alpha: 0.15),
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                          ),
                          child: Slider(
                            value: _selectedRadius.clamp(0.5, 20.0),
                            min: 0.5,
                            max: 20.0,
                            divisions: 39,
                            onChanged: (val) {
                              setState(() {
                                _selectedRadius = double.parse(val.toStringAsFixed(1));
                                _radiusInputController.text = _selectedRadius.truncateToDouble() == _selectedRadius
                                    ? _selectedRadius.toInt().toString()
                                    : _selectedRadius.toStringAsFixed(1);
                              });
                              _applyFilters();
                            },
                          ),
                        ),
                      ),
                      Text('20 km', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  // Quick select buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [1.0, 3.0, 5.0, 10.0].map((r) {
                      final isSelected = _selectedRadius == r;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedRadius = r;
                            _radiusInputController.text = r.toInt().toString();
                          });
                          _applyFilters();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.grey[300]!,
                            ),
                          ),
                          child: Text(
                            '${r.toInt()} km',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.black54,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Bottom alert indicator if loading location
          if (_isLoadingLocation)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
