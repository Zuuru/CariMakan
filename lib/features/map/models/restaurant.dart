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
        lat = loc.latitude;
        lng = loc.longitude;
      } catch (e) {
        // Fallback or ignore if it's not a GeoPoint
      }
    } else {
      lat = (data['latitude'] as num?)?.toDouble() ?? 0.0;
      lng = (data['longitude'] as num?)?.toDouble() ?? 0.0;
    }

    return Restaurant(
      id: id,
      name: data['nama'] ?? data['name'] ?? '',
      address: data['lokasi_alamat'] ?? data['address'] ?? '',
      latitude: lat,
      longitude: lng,
      rating: (data['avg_rating'] as num?)?.toDouble() ?? (data['rating'] as num?)?.toDouble() ?? 0.0,
      imageUrl: data['foto_profil'] ?? data['imageUrl'] ?? 'https://via.placeholder.com/250x120',
      isOpen: data['status'] == 'aktif' || (data['isOpen'] ?? true),
      category: data['category'] ?? (data['genres'] != null && (data['genres'] as List).isNotEmpty ? data['genres'][0] : ''),
      queueCount: data['queueCount'] ?? data['total_review'] ?? 0,
    );
  }
}
