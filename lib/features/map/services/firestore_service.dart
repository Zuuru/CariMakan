import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/restaurant.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Restaurant>> streamRestaurants() {
    return _db.collection('restaurants').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Restaurant.fromFirestore(doc.id, doc.data());
      }).toList();
    });
  }

  Future<List<Restaurant>> getRestaurants() async {
    final snapshot = await _db.collection('restaurants').get();
    return snapshot.docs.map((doc) {
      return Restaurant.fromFirestore(doc.id, doc.data());
    }).toList();
  }

  Future<void> injectLocationsToExistingRestaurants() async {
    try {
      final snapshot = await _db.collection('restaurants').get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final lokasi = data['lokasi'];
        final Map<String, dynamic> updates = {};

        // --- Cek dan perbaiki koordinat ---
        if (lokasi is GeoPoint) {
          double lat = lokasi.latitude;
          final double lng = lokasi.longitude;

          // Koreksi latitude positif di area Indonesia (Jawa = selatan = negatif)
          if (lat > 0 && lng > 100 && lng < 120) {
            updates['lokasi'] = GeoPoint(-lat, lng);
          }
        } else if (lokasi == null) {
          // Tidak ada koordinat sama sekali, beri default Tembalang
          updates['lokasi'] = const GeoPoint(-7.0494, 110.4382);
          updates['lokasi_alamat'] = data['lokasi_alamat'] ?? 'Semarang, Jawa Tengah';
        }

        // --- Trim status jika ada spasi trailing ---
        final rawStatus = data['status'] as String?;
        if (rawStatus != null && rawStatus != rawStatus.trim()) {
          updates['status'] = rawStatus.trim();
        }

        // --- Inject category dari genres jika category belum ada ---
        final rawCategory = data['category'] as String?;
        if (rawCategory == null || rawCategory.trim().isEmpty) {
          final genres = data['genres'] as List?;
          if (genres != null && genres.isNotEmpty) {
            updates['category'] = genres[0] as String;
          }
        }

        if (updates.isNotEmpty) {
          await _db.collection('restaurants').doc(doc.id).update(updates);
          print('✅ Fixed doc "${data['nama']}": $updates');
        }
      }
    } catch (e) {
      print('Error injecting locations: $e');
    }
  }


  Future<void> seedRestaurants() async {
    try {
      final snapshot = await _db.collection('restaurants').limit(1).get();
      if (snapshot.docs.isEmpty) {
        final List<Map<String, dynamic>> initialRestaurants = [
          {
            'nama': 'Ideologist Coffee And Social Space',
            'lokasi_alamat': 'Jl. Baskoro No.38, Tembalang, Kec. Tembalang, Kota Semarang',
            'lokasi': const GeoPoint(-7.0485, 110.4395),
            'avg_rating': 4.9,
            'foto_profil': 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=500&auto=format&fit=crop&q=60',
            'status': 'aktif',
            'category': 'Cafe',
            'total_review': 4
          },
          {
            'nama': 'Burjo Parjo Sipodang',
            'lokasi_alamat': 'Jl. Sipodang, Tembalang, Kec. Tembalang, Kota Semarang',
            'lokasi': const GeoPoint(-7.0512, 110.4368),
            'avg_rating': 4.7,
            'foto_profil': 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=500&auto=format&fit=crop&q=60',
            'status': 'aktif',
            'category': 'Makanan Berat',
            'total_review': 8
          },
          {
            'nama': 'Warmindo Berkah',
            'lokasi_alamat': 'Jl. Prof. Soedarto, Tembalang, Kec. Tembalang, Kota Semarang',
            'lokasi': const GeoPoint(-7.0501, 110.4412),
            'avg_rating': 4.5,
            'foto_profil': 'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=500&auto=format&fit=crop&q=60',
            'status': 'nonaktif',
            'category': 'Makanan Berat',
            'total_review': 2
          },
          {
            'nama': 'McDonald\'s Tembalang',
            'lokasi_alamat': 'Jl. Ngesrep Timur V No.25, Sumurboto, Kec. Banyumanik, Kota Semarang',
            'lokasi': const GeoPoint(-7.0450, 110.4420),
            'avg_rating': 4.6,
            'foto_profil': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500&auto=format&fit=crop&q=60',
            'status': 'aktif',
            'category': 'Fastfood',
            'total_review': 15
          },
          {
            'nama': 'Kopi Kenangan Tembalang',
            'lokasi_alamat': 'Jl. Prof. Soedarto No.12, Tembalang, Kec. Tembalang, Kota Semarang',
            'lokasi': const GeoPoint(-7.0490, 110.4390),
            'avg_rating': 4.8,
            'foto_profil': 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=500&auto=format&fit=crop&q=60',
            'status': 'aktif',
            'category': 'Cafe',
            'total_review': 12
          },
          {
            'nama': 'Mie Gacoan Tembalang',
            'lokasi_alamat': 'Jl. Kompol Maksum, Tembalang, Kec. Tembalang, Kota Semarang',
            'lokasi': const GeoPoint(-7.0480, 110.4410),
            'avg_rating': 4.7,
            'foto_profil': 'https://images.unsplash.com/photo-1552611052-33e04de081de?w=500&auto=format&fit=crop&q=60',
            'status': 'aktif',
            'category': 'Makanan Berat',
            'total_review': 24
          },
          {
            'nama': 'KFC Tembalang',
            'lokasi_alamat': 'Jl. Setiabudi No.110, Srondol Kulon, Kec. Banyumanik, Kota Semarang',
            'lokasi': const GeoPoint(-7.0460, 110.4400),
            'avg_rating': 4.5,
            'foto_profil': 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=500&auto=format&fit=crop&q=60',
            'status': 'aktif',
            'category': 'Fastfood',
            'total_review': 18
          },
          {
            'nama': 'Sweet & Chill Dessert',
            'lokasi_alamat': 'Jl. Banjarsari No.45, Tembalang, Kec. Tembalang, Kota Semarang',
            'lokasi': const GeoPoint(-7.0525, 110.4385),
            'avg_rating': 4.8,
            'foto_profil': 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=500&auto=format&fit=crop&q=60',
            'status': 'aktif',
            'category': 'Dessert',
            'total_review': 7
          }
        ];

        for (final resto in initialRestaurants) {
          await _db.collection('restaurants').add(resto);
        }
      }
    } catch (e) {
      print('Error seeding: $e');
    }
  }

  Future<List<Restaurant>> getMockRestaurants() async {
    return [
      Restaurant(
        id: 'mock_1',
        name: 'Ideologist Coffee And Social Space',
        address: 'Jl. Baskoro No.38, Tembalang, Kec. Tembalang, Kota Semarang',
        latitude: -7.0485,
        longitude: 110.4395,
        rating: 4.9,
        imageUrl: 'assets/images/ideologist.jpg',
        isOpen: true,
        category: 'Cafe',
        queueCount: 4,
      ),
      Restaurant(
        id: 'mock_2',
        name: 'Burjo Parjo Sipodang',
        address: 'Jl. Sipodang, Tembalang, Kec. Tembalang, Kota Semarang',
        latitude: -7.0512,
        longitude: 110.4368,
        rating: 4.7,
        imageUrl: 'assets/images/parjo sipodang.jpg',
        isOpen: true,
        category: 'Makanan Berat',
        queueCount: 8,
      ),
      Restaurant(
        id: 'mock_3',
        name: 'Warmindo Berkah',
        address: 'Jl. Prof. Soedarto, Tembalang, Kec. Tembalang, Kota Semarang',
        latitude: -7.0501,
        longitude: 110.4412,
        rating: 4.5,
        imageUrl: 'https://via.placeholder.com/250x120',
        isOpen: false,
        category: 'Makanan Berat',
        queueCount: 2,
      ),
    ];
  }
}
