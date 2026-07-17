import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewService {
  static final _db = FirebaseFirestore.instance;

  /// Submit a review for a completed order.
  /// Saves review fields to the order document and runs a transaction
  /// to update avg_rating + total_review on the restaurant document
  /// using the running-average algorithm.
  static Future<void> submitReview({
    required String orderId,
    required String restoId,
    required int ratingPelayanan,
    required int ratingMakanan,
    required int ratingFasilitas,
    String komentar = '',
    List<String> selectedTags = const [],
  }) async {
    // 1. Hitung rating total
    final ratingTotal =
        (ratingPelayanan + ratingMakanan + ratingFasilitas) / 3.0;

    // 2. Update order document — simpan review data
    await _db.collection('orders').doc(orderId).update({
      'rating_pelayanan': ratingPelayanan,
      'rating_makanan': ratingMakanan,
      'rating_fasilitas': ratingFasilitas,
      'rating_total': ratingTotal,
      'komentar': komentar,
      'selected_tags': selectedTags,
      'sudah_direview': true,
      'reviewed_at': FieldValue.serverTimestamp(),
    });

    // 3. Update avg_rating pada dokumen resto menggunakan running average (transaction)
    final restoRef = _db.collection('restaurants').doc(restoId);
    await _db.runTransaction((txn) async {
      final restoSnap = await txn.get(restoRef);
      if (!restoSnap.exists) return;

      final restoData = restoSnap.data() as Map<String, dynamic>;
      final double oldAvg =
          (restoData['avg_rating'] as num?)?.toDouble() ?? 0.0;
      final int oldCount = (restoData['total_review'] as num?)?.toInt() ?? 0;

      // Running average formula
      final double newAvg =
          ((oldAvg * oldCount) + ratingTotal) / (oldCount + 1);
      final int newCount = oldCount + 1;

      txn.update(restoRef, {
        'avg_rating': double.parse(newAvg.toStringAsFixed(1)),
        'total_review': newCount,
      });
    });
  }

  /// Stream reviews for a specific restaurant (for the resto page).
  static Stream<QuerySnapshot> getRestoReviews(String restoId,
      {int limit = 10}) {
    return _db
        .collection('orders')
        .where('resto_id', isEqualTo: restoId)
        .where('sudah_direview', isEqualTo: true)
        .orderBy('reviewed_at', descending: true)
        .limit(limit)
        .snapshots();
  }
}
