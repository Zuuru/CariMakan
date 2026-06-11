import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cart_service.dart';
import '../../promo/data/promo_model.dart';

class PesananService {
  static final _db = FirebaseFirestore.instance;

  static Future<String> createOrder({
    required List<CartItemModel> cartItems,
    required double totalPrice,
    required String paymentMethod,
    required String restoId,
    required String type,
    required String tableOrPickupInfo,
    PromoModel? appliedPromo,
    double discount = 0.0,
    double? subtotal,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? 'guest_id';
      final userName = user?.displayName ?? 'Guest User';

      final docRef = _db.collection('orders').doc();
      final random = Random();
      final queueNum = '#${10 + random.nextInt(90)}';
      
      final orderData = {
        'id': docRef.id,
        'userId': userId,
        'userName': userName,
        'resto_id': restoId,
        'menuName': cartItems.length == 1 ? cartItems.first.menuName : '${cartItems.length} items',
        'totalPrice': totalPrice,
        'paymentMethod': paymentMethod,
        'status': 'paid',
        'orderDate': FieldValue.serverTimestamp(),
        'discount': discount,
        'subtotal': subtotal ?? totalPrice,
        'promoId': appliedPromo?.id,
        'promoCode': appliedPromo?.kode,
        'type': type,
        'tableOrPickupInfo': tableOrPickupInfo,
        'queueNumber': queueNum,
        'items': cartItems.map((item) => {
          'menuId': item.menuId,
          'menuName': item.menuName,
          'menuImage': item.menuImage,
          'basePrice': item.basePrice,
          'unitTotalPrice': item.totalPrice,
          'quantity': item.quantity,
          'customization': item.selectedVariants,
        }).toList(),
      };

      await docRef.set(orderData);
      return docRef.id;
    } catch (e) {
      print('Error creating order: $e');
      return 'error_creating_order';
    }
  }
}
