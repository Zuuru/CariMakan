import 'package:cloud_firestore/cloud_firestore.dart';
import 'menu_model.dart';
import 'option_group_model.dart';
import 'option_item_model.dart';
import 'variant_template_model.dart';

/// Service untuk operasi CRUD menu dan variant ke Firestore.
///
/// Semua operasi dilakukan langsung dari Flutter ke Firestore
/// (tanpa melalui backend Node.js), sesuai pembagian tugas di
/// docs/workflow_menu_variant.md.
class MenuService {
  static final _db = FirebaseFirestore.instance;
  static const _menuCollection = 'menus';
  static const _templateCollection = 'variant_templates';

  // ════════════════════════════════════════════════════════════════
  //  MENU CRUD
  // ════════════════════════════════════════════════════════════════

  /// Stream real-time daftar menu milik sebuah resto.
  static Stream<List<MenuModel>> getMenusByResto(String restoId) {
    return _db
        .collection(_menuCollection)
        .where('resto_id', isEqualTo: restoId)
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => MenuModel.fromFirestore(doc)).toList());
  }

  /// Tambah menu baru ke Firestore. Mengembalikan document ID.
  static Future<String> tambahMenu(MenuModel menu) async {
    final docRef = await _db.collection(_menuCollection).add(menu.toFirestore());
    return docRef.id;
  }

  /// Update menu yang sudah ada di Firestore.
  static Future<void> updateMenu(MenuModel menu) async {
    await _db
        .collection(_menuCollection)
        .doc(menu.id)
        .update(menu.toFirestore());
  }

  /// Hapus menu beserta semua sub-collection variant-nya.
  static Future<void> hapusMenu(String menuId) async {
    final menuRef = _db.collection(_menuCollection).doc(menuId);

    // Hapus semua option_groups dan option_items di dalamnya
    final groups = await menuRef.collection('option_groups').get();
    for (final groupDoc in groups.docs) {
      final items = await groupDoc.reference.collection('option_items').get();
      for (final itemDoc in items.docs) {
        await itemDoc.reference.delete();
      }
      await groupDoc.reference.delete();
    }

    // Hapus dokumen menu itu sendiri
    await menuRef.delete();
  }

  /// Toggle status ketersediaan menu.
  static Future<void> toggleAvailability(String menuId, bool newStatus) async {
    await _db.collection(_menuCollection).doc(menuId).update({
      'is_available': newStatus,
    });
  }

  // ════════════════════════════════════════════════════════════════
  //  OPTION GROUP CRUD
  // ════════════════════════════════════════════════════════════════

  /// Stream real-time daftar option groups untuk sebuah menu.
  static Stream<List<OptionGroupModel>> getOptionGroups(String menuId) {
    return _db
        .collection(_menuCollection)
        .doc(menuId)
        .collection('option_groups')
        .orderBy('urutan')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OptionGroupModel.fromFirestore(doc, menuId: menuId))
            .toList());
  }

  /// Load option groups beserta items-nya (satu kali fetch, bukan stream).
  /// Digunakan saat membuka form edit menu.
  static Future<List<OptionGroupModel>> loadOptionGroupsWithItems(String menuId) async {
    final groupsSnapshot = await _db
        .collection(_menuCollection)
        .doc(menuId)
        .collection('option_groups')
        .orderBy('urutan')
        .get();

    final List<OptionGroupModel> groups = [];
    for (final groupDoc in groupsSnapshot.docs) {
      final group = OptionGroupModel.fromFirestore(groupDoc, menuId: menuId);

      // Load items di dalam grup ini
      final itemsSnapshot = await groupDoc.reference
          .collection('option_items')
          .orderBy('urutan')
          .get();

      group.items = itemsSnapshot.docs
          .map((itemDoc) =>
              OptionItemModel.fromFirestore(itemDoc, groupId: group.id))
          .toList();

      groups.add(group);
    }

    return groups;
  }

  /// Simpan option group beserta items-nya ke Firestore.
  /// Digunakan saat menambahkan grup baru (dari template atau custom).
  static Future<void> tambahOptionGroup(
    String menuId,
    OptionGroupModel group,
    List<OptionItemModel> items,
  ) async {
    final groupRef = await _db
        .collection(_menuCollection)
        .doc(menuId)
        .collection('option_groups')
        .add(group.toFirestore());

    // Simpan semua items dalam batch
    final batch = _db.batch();
    for (int i = 0; i < items.length; i++) {
      final itemRef = groupRef.collection('option_items').doc();
      batch.set(itemRef, items[i].copyWith(urutan: i).toFirestore());
    }
    await batch.commit();
  }

  /// Update option group beserta items-nya.
  /// Strategi: hapus semua items lama, tulis ulang items baru.
  static Future<void> updateOptionGroup(
    String menuId,
    OptionGroupModel group,
    List<OptionItemModel> items,
  ) async {
    final groupRef = _db
        .collection(_menuCollection)
        .doc(menuId)
        .collection('option_groups')
        .doc(group.id);

    // Update data grup
    await groupRef.update(group.toFirestore());

    // Hapus semua items lama
    final oldItems = await groupRef.collection('option_items').get();
    final batch = _db.batch();
    for (final doc in oldItems.docs) {
      batch.delete(doc.reference);
    }

    // Tulis items baru
    for (int i = 0; i < items.length; i++) {
      final itemRef = groupRef.collection('option_items').doc();
      batch.set(itemRef, items[i].copyWith(urutan: i).toFirestore());
    }
    await batch.commit();
  }

  /// Hapus option group beserta semua items di dalamnya.
  static Future<void> hapusOptionGroup(String menuId, String groupId) async {
    final groupRef = _db
        .collection(_menuCollection)
        .doc(menuId)
        .collection('option_groups')
        .doc(groupId);

    // Hapus semua items dulu
    final items = await groupRef.collection('option_items').get();
    final batch = _db.batch();
    for (final doc in items.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    // Hapus grup
    await groupRef.delete();
  }

  // ════════════════════════════════════════════════════════════════
  //  VARIANT TEMPLATES
  // ════════════════════════════════════════════════════════════════

  /// Ambil semua template variant dari Firestore.
  /// Jika database kosong, otomatis melakukan seeding data bawaan.
  static Future<List<VariantTemplateModel>> getVariantTemplates() async {
    var snapshot = await _db.collection(_templateCollection).get();
    
    if (snapshot.docs.isEmpty) {
      await seedVariantTemplates();
      snapshot = await _db.collection(_templateCollection).get();
    }
    
    return snapshot.docs
        .map((doc) => VariantTemplateModel.fromFirestore(doc))
        .toList();
  }

  /// Seed data template bawaan ke Firestore.
  /// Hanya perlu dijalankan sekali (development).
  static Future<void> seedVariantTemplates() async {
    // Cek apakah sudah ada data
    final existing = await _db.collection(_templateCollection).limit(1).get();
    if (existing.docs.isNotEmpty) return; // Sudah ada, skip

    final batch = _db.batch();
    for (final template in VariantTemplateModel.seedData) {
      final ref = _db.collection(_templateCollection).doc();
      batch.set(ref, template.toFirestore());
    }
    await batch.commit();
  }
}
