import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PesananService {
  static final _db = FirebaseFirestore.instance;

  static Future<String> createOrder({
    required String menuName,
    required double totalPrice,
    required String paymentMethod,
    required Map<String, dynamic> customization,
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
        'customization': customization,
      };

      await docRef.set(orderData);
      return docRef.id;
    } catch (e) {
      print('Error creating order: $e');
      return 'error_creating_order';
    }
  }
}
