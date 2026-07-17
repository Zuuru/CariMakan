import 'dart:convert';
import 'package:flutter/foundation.dart';

class CartItemModel {
  final String menuId;
  final String menuName;
  final String menuImage;
  final double basePrice;
  final double totalPrice;
  final String description;
  int quantity;
  final Map<String, List<Map<String, dynamic>>> selectedVariants;

  CartItemModel({
    required this.menuId,
    required this.menuName,
    required this.menuImage,
    required this.basePrice,
    required this.totalPrice,
    required this.description,
    this.quantity = 1,
    required this.selectedVariants,
  });

  /// Check if two items are exactly the same (same menu and variants)
  bool isSameAs(CartItemModel other) {
    if (menuId != other.menuId) return false;
    return jsonEncode(selectedVariants) == jsonEncode(other.selectedVariants);
  }

  Map<String, dynamic> toMap() {
    return {
      'menuId': menuId,
      'menuName': menuName,
      'menuImage': menuImage,
      'basePrice': basePrice,
      'totalPrice': totalPrice,
      'description': description,
      'quantity': quantity,
      'selectedVariants': selectedVariants,
    };
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    final rawVariants = map['selectedVariants'] as Map<String, dynamic>? ?? {};
    final variants = rawVariants.map(
      (key, value) => MapEntry(
        key,
        (value as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      ),
    );
    return CartItemModel(
      menuId: map['menuId'] as String? ?? '',
      menuName: map['menuName'] as String? ?? '',
      menuImage: map['menuImage'] as String? ?? '',
      basePrice: (map['basePrice'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      selectedVariants: variants,
    );
  }
}

class CartService extends ChangeNotifier {
  // Singleton instance
  static final CartService instance = CartService._internal();
  CartService._internal();

  // Map to store items grouped by Resto ID
  // key: restoId, value: list of CartItemModel
  final Map<String, List<CartItemModel>> _carts = {};

  List<CartItemModel> getItems(String restoId) {
    return _carts[restoId] ?? [];
  }

  int getTotalItems(String restoId) {
    final items = getItems(restoId);
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  double getTotalPrice(String restoId) {
    final items = getItems(restoId);
    return items.fold(0.0, (sum, item) => sum + (item.totalPrice * item.quantity));
  }

  void addItem(String restoId, CartItemModel newItem) {
    _carts.putIfAbsent(restoId, () => []);
    
    final items = _carts[restoId]!;
    // Check if identical item exists
    final index = items.indexWhere((item) => item.isSameAs(newItem));
    
    if (index >= 0) {
      // Increment quantity
      items[index].quantity += newItem.quantity;
    } else {
      // Add as new item
      items.add(newItem);
    }
    notifyListeners();
  }

  void updateQuantity(String restoId, CartItemModel targetItem, int newQuantity) {
    final items = _carts[restoId];
    if (items == null) return;

    final index = items.indexOf(targetItem);
    if (index >= 0) {
      if (newQuantity <= 0) {
        items.removeAt(index);
      } else {
        items[index].quantity = newQuantity;
      }
      notifyListeners();
    }
  }

  void updateItem(String restoId, CartItemModel oldItem, CartItemModel newItem) {
    final items = _carts[restoId];
    if (items == null) return;

    final index = items.indexOf(oldItem);
    if (index >= 0) {
      // Check if another identical item (same menu and variants) already exists in the cart
      final existingIndex = items.indexWhere((item) => item != oldItem && item.isSameAs(newItem));
      if (existingIndex >= 0) {
        // Merge them and remove the old item
        items[existingIndex].quantity += newItem.quantity;
        items.removeAt(index);
      } else {
        // Replace old item with the new one
        items[index] = newItem;
      }
      notifyListeners();
    }
  }

  void clearCart(String restoId) {
    _carts[restoId]?.clear();
    notifyListeners();
  }
}
