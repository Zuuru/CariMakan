import 'package:cloud_firestore/cloud_firestore.dart';

class Restaurant {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double rating;
  final String imageUrl;
  final bool isOpen;
  final String category;
  final int queueCount;

  Restaurant({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.imageUrl,
    required this.isOpen,
    required this.category,
    required this.queueCount,
  });

  factory Restaurant.fromFirestore(String id, Map<String, dynamic> data) {
    double lat = 0.0;
    double lng = 0.0;
    if (data['lokasi'] != null) {
      try {
        final loc = data['lokasi'];
        if (loc is GeoPoint) {
          lat = loc.latitude;
          lng = loc.longitude;
        } else if (loc is Map) {
          lat = (loc['latitude'] as num?)?.toDouble() ?? 0.0;
          lng = (loc['longitude'] as num?)?.toDouble() ?? 0.0;
        }
      } catch (e) {
        // Fallback or ignore
      }
    } else {
      lat = (data['latitude'] as num?)?.toDouble() ?? 0.0;
      lng = (data['longitude'] as num?)?.toDouble() ?? 0.0;
    }

    // Auto-correct: Pulau Jawa/Semarang ada di belahan bumi SELATAN (latitude negatif).
    // Jika latitude positif dan longitude ~105-115 (Indonesia), koreksi ke negatif.
    if (lat > 0 && lng > 100 && lng < 120) {
      lat = -lat;
    }

    // Resolve category: dari field 'category', atau fallback ke genres[0]
    final rawCategory = data['category'] as String?;
    final genresList = data['genres'] as List?;
    final category = (rawCategory != null && rawCategory.trim().isNotEmpty)
        ? rawCategory.trim()
        : (genresList != null && genresList.isNotEmpty ? genresList[0] as String : '');

    // Trim status untuk menghindari masalah spasi trailing seperti "aktif "
    final status = (data['status'] as String? ?? '').trim();

    return Restaurant(
      id: id,
      name: data['nama'] ?? data['name'] ?? '',
      address: data['lokasi_alamat'] ?? data['address'] ?? '',
      latitude: lat,
      longitude: lng,
      rating: (data['avg_rating'] as num?)?.toDouble() ?? (data['rating'] as num?)?.toDouble() ?? 0.0,
      imageUrl: data['foto_profil'] ?? data['imageUrl'] ?? 'https://via.placeholder.com/250x120',
      isOpen: status == 'aktif' || (data['isOpen'] as bool? ?? false),
      category: category,
      queueCount: (data['queueCount'] ?? data['total_review'] ?? 0) as int,
    );
  }
}
