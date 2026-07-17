import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteService extends ChangeNotifier {
  static final FavoriteService instance = FavoriteService._internal();
  
  FavoriteService._internal() {
    // Load immediately if user is already logged in
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _loadFavorites(currentUser.uid);
    }

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _loadFavorites(user.uid);
      } else {
        _favoriteRestos.clear();
        _favoriteMenus.clear();
        notifyListeners();
      }
    });
  }

  final Set<String> _favoriteRestos = {};
  final Set<String> _favoriteMenus = {};

  Set<String> get favoriteRestos => _favoriteRestos;
  Set<String> get favoriteMenus => _favoriteMenus;

  bool isFavorite(String id, bool isResto) {
    return isResto ? _favoriteRestos.contains(id) : _favoriteMenus.contains(id);
  }

  Future<void> _loadFavorites(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          final restos = List<String>.from(data['favorite_restos'] ?? []);
          final menus = List<String>.from(data['favorite_menus'] ?? []);
          
          _favoriteRestos.clear();
          _favoriteRestos.addAll(restos);
          
          _favoriteMenus.clear();
          _favoriteMenus.addAll(menus);
          
          notifyListeners();
          debugPrint('Favorites loaded: ${restos.length} restos, ${menus.length} menus');
        }
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  Future<void> toggleFavorite(String id, bool isResto) async {
    final targetSet = isResto ? _favoriteRestos : _favoriteMenus;
    final isAdding = !targetSet.contains(id);

    // Update UI immediately
    if (isAdding) {
      targetSet.add(id);
    } else {
      targetSet.remove(id);
    }
    notifyListeners();

    // Persist to Firestore safely
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final field = isResto ? 'favorite_restos' : 'favorite_menus';
        final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        
        if (isAdding) {
          await docRef.set({
            field: FieldValue.arrayUnion([id])
          }, SetOptions(merge: true));
        } else {
          await docRef.set({
            field: FieldValue.arrayRemove([id])
          }, SetOptions(merge: true));
        }
      } catch (e) {
        debugPrint('Error updating favorites in Firestore: $e');
      }
    }
  }
}
