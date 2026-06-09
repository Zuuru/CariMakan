import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PesananService {
  static final _db = FirebaseFirestore.instance;

  static Future<String> createOrder({
    required String menuName,
    required double totalPrice,
    required String paymentMethod,
    required String gula,
    required String es,
    required bool addBiscoff,
    required bool addCaramel,
    required int espressoShots,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? 'guest_id';
      final userName = user?.displayName ?? 'Guest User';

      final docRef = _db.collection('orders').doc();
      
      final orderData = {
        'id': docRef.id,
        'userId': userId,
        'userName': userName,
        'menuName': menuName,
        'totalPrice': totalPrice,
        'paymentMethod': paymentMethod,
        'status': 'paid',
        'orderDate': FieldValue.serverTimestamp(),
        'customization': {
          'gula': gula,
          'es': es,
          'addBiscoff': addBiscoff,
          'addCaramel': addCaramel,
          'espressoShots': espressoShots,
        },
      };

      await docRef.set(orderData);
      return docRef.id;
    } catch (e) {
      print('Error creating order: $e');
      return 'error_creating_order';
    }
  }
}
