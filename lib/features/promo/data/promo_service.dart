import 'package:cloud_firestore/cloud_firestore.dart';
import 'promo_model.dart';

/// Service untuk operasi CRUD promo ke Firestore.
///
/// Semua operasi dilakukan langsung dari Flutter ke Firestore
/// (tanpa melalui backend Node.js), sesuai pembagian tugas di
/// docs/workflow_promo_voucher.md.
class PromoService {
  static final _db = FirebaseFirestore.instance;
  static const _collection = 'promo_voucher';
  static const _pemakaianCollection = 'voucher_pakai';

  /// Stream real-time daftar promo milik sebuah resto.
  /// Digunakan oleh ManajemenPromoPage untuk menampilkan list promo.
  static Stream<List<PromoModel>> getPromosByResto(String restoId) {
    return _db
        .collection(_collection)
        .where('resto_id', isEqualTo: restoId)
        .orderBy('mulai', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PromoModel.fromFirestore(doc))
            .toList());
  }

  /// Buat promo baru di Firestore.
  static Future<void> tambahPromo(PromoModel promo) async {
    await _db.collection(_collection).add(promo.toFirestore());
  }

  /// Update promo yang sudah ada di Firestore.
  /// Hanya boleh dilakukan jika belum ada customer yang memakai promo ini.
  static Future<void> updatePromo(PromoModel promo) async {
    await _db
        .collection(_collection)
        .doc(promo.id)
        .update(promo.toFirestore());
  }

  /// Toggle status aktif/nonaktif promo.
  static Future<void> toggleActive(String promoId, bool newIsActive) async {
    await _db.collection(_collection).doc(promoId).update({
      'is_active': newIsActive,
    });
  }

  /// Hapus promo dari Firestore.
  /// Hanya boleh dilakukan jika belum ada customer yang memakai promo ini.
  static Future<void> hapusPromo(String promoId) async {
    await _db.collection(_collection).doc(promoId).delete();
  }

  /// Hitung jumlah pemakaian promo dari koleksi `voucher_pakai`.
  /// Digunakan untuk menentukan apakah promo masih bisa diedit/dihapus.
  static Future<int> countPemakaian(String promoId) async {
    final snapshot = await _db
        .collection(_pemakaianCollection)
        .where('promo_id', isEqualTo: promoId)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Stream real-time semua promo aktif yang belum kadaluarsa.
  /// Digunakan oleh Customer PromoPage & PromoBanner.
  static Stream<List<PromoModel>> getActivePromos() {
    return _db
        .collection(_collection)
        .where('is_active', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PromoModel.fromFirestore(doc))
              .where((promo) => !promo.isExpired && !promo.isUpcoming)
              .toList()
              ..sort((a, b) => b.mulai.compareTo(a.mulai));
        });
  }
}
