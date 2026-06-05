import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:carimakan/core/theme/app_colors.dart';
import 'package:carimakan/features/map/services/firestore_service.dart';
import 'package:carimakan/features/map/services/map_service.dart';
import 'package:carimakan/features/map/models/restaurant.dart';

class MiniMapWidget extends StatefulWidget {
  final VoidCallback onTap;

  const MiniMapWidget({super.key, required this.onTap});

  @override
  State<MiniMapWidget> createState() => _MiniMapWidgetState();
}

class _MiniMapWidgetState extends State<MiniMapWidget> {
  final MapController _mapController = MapController();
  final MapService _mapService = MapService();
  final FirestoreService _firestoreService = FirestoreService();

  LatLng _userLocation = const LatLng(-7.0494, 110.4382);
  List<Restaurant> _restaurants = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Load location
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission != LocationPermission.denied &&
            permission != LocationPermission.deniedForever) {
          final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
          );
          if (mounted) {
            setState(() {
              _userLocation = LatLng(pos.latitude, pos.longitude);
            });
            _mapController.move(_userLocation, 14.0);
          }
        }
      }
    } catch (_) {}

    // Load restaurants
    try {
      final restos = await _firestoreService.getRestaurants();
      final list = restos.isEmpty
          ? await _firestoreService.getMockRestaurants()
          : restos;
      if (mounted) {
        setState(() {
          _restaurants = list;
          _loading = false;
        });
      }
    } catch (_) {
      final list = await _firestoreService.getMockRestaurants();
      if (mounted) {
        setState(() {
          _restaurants = list;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      // User location
      Marker(
        point: _userLocation,
        width: 28,
        height: 28,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.white, blurRadius: 2, spreadRadius: 1),
                ],
              ),
            ),
          ],
        ),
      ),
      // Restaurant markers
      ..._restaurants.map((r) => Marker(
            point: LatLng(r.latitude, r.longitude),
            width: 36,
            height: 40,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.restaurant, color: Colors.white, size: 14),
                ),
                CustomPaint(
                  size: const Size(8, 5),
                  painter: _TrianglePainter(),
                ),
              ],
            ),
          )),
    ];

    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 200,
          width: double.infinity,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _userLocation,
                  initialZoom: 14.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none, // non-interactive preview
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'com.carimakan.app',
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),
              if (_loading)
                Container(
                  color: Colors.white.withValues(alpha: 0.6),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                      strokeWidth: 2,
                    ),
                  ),
                ),
              // Tap-to-expand overlay hint
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_full, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'Buka peta',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
