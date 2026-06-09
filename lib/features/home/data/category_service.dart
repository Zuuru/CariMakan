import 'package:cloud_firestore/cloud_firestore.dart';
import 'category_model.dart';

class CategoryService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Stream<List<CategoryModel>> getCategories() {
    return _db.collection('categories').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return CategoryModel.fromFirestore(doc.id, doc.data());
      }).toList();
    });
  }
}
