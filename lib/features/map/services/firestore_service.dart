import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/restaurant.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Restaurant>> streamRestaurants() {
    return _db.collection('restos').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Restaurant.fromFirestore(doc.id, doc.data());
      }).toList();
    });
  }

  Future<List<Restaurant>> getRestaurants() async {
    final snapshot = await _db.collection('restos').get();
    return snapshot.docs.map((doc) {
      return Restaurant.fromFirestore(doc.id, doc.data());
    }).toList();
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
        category: 'Minuman',
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
        category: 'Ayam',
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
        category: 'Bakso',
        queueCount: 2,
      ),
    ];
  }
}
