import 'package:flutter/material.dart';

class FavoriteService extends ChangeNotifier {
  static final FavoriteService instance = FavoriteService._internal();
  FavoriteService._internal();

  final Set<String> _favoriteRestos = {};
  final Set<String> _favoriteMenus = {};

  Set<String> get favoriteRestos => _favoriteRestos;
  Set<String> get favoriteMenus => _favoriteMenus;

  bool isFavorite(String id, bool isResto) {
    return isResto ? _favoriteRestos.contains(id) : _favoriteMenus.contains(id);
  }

  void toggleFavorite(String id, bool isResto) {
    final targetSet = isResto ? _favoriteRestos : _favoriteMenus;
    if (targetSet.contains(id)) {
      targetSet.remove(id);
    } else {
      targetSet.add(id);
    }
    notifyListeners();
  }
}
