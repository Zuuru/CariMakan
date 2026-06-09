class CategoryModel {
  final String id;
  final String name;
  final String image;

  CategoryModel({
    required this.id,
    required this.name,
    required this.image,
  });

  factory CategoryModel.fromFirestore(String id, Map<String, dynamic> data) {
    return CategoryModel(
      id: id,
      name: data['name'] ?? '',
      image: data['image'] ?? data['imageUrl'] ?? '',
    );
  }
}
