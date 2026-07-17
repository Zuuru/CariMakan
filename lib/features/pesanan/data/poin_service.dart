import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service untuk sistem Reward Poin — Pola Pending Action Queue.
///
/// Flutter TIDAK mengubah `users.poin_reward` secara langsung.
/// Cukup tulis "niat" ke koleksi `poin_queue` dengan status 'pending'.
/// Node.js akan mem-listen dan memprosesnya secara atomic.
class PoinService {
  static final _db = FirebaseFirestore.instance;

  // ── Helpers ────────────────────────────────────────────────────────

  /// Stream poin real-time milik user yang sedang login.
  static Stream<int> streamPoinUser() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(0);

    return _db.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return 0;
      return (snap.data()?['poin_reward'] as num?)?.toInt() ?? 0;
    });
  }

  /// Ambil poin user sekali (future).
  static Future<int> getPoinUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 0;
    final snap = await _db.collection('users').doc(uid).get();
    return (snap.data()?['poin_reward'] as num?)?.toInt() ?? 0;
  }

  // ── Kalkulasi (client-side, untuk preview UI) ───────────────────────

  /// Hitung maks poin yang bisa dipakai (25% dari subtotal, dibulatkan ke bawah).
  static int hitungMaksPotongan(double subtotalSetelahDiskon) {
    return (subtotalSetelahDiskon * 25 / 100).floor();
  }

  /// Hitung poin yang benar-benar akan dipakai.
  static int hitungPoinDigunakan(int poinDimiliki, double subtotalSetelahDiskon) {
    final maks = hitungMaksPotongan(subtotalSetelahDiskon);
    return poinDimiliki < maks ? poinDimiliki : maks;
  }

  // ── Enqueue Actions ──────────────────────────────────────────────────

  /// Antrekan EARN poin (dipanggil saat order status berubah ke 'Selesai').
  /// [totalAkhir] adalah total yang benar-benar dibayar (setelah semua potongan).
  static Future<void> enqueueEarn({
    required String orderId,
    required String userId,
    required double totalAkhir,
  }) async {
    await _db.collection('poin_queue').add({
      'user_id': userId,
      'order_id': orderId,
      'tipe': 'earn',
      'jumlah': null,
      'total_akhir': totalAkhir,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  /// Antrekan REDEEM poin (dipanggil setelah pembayaran & order berhasil dibuat).
  /// [poinDigunakan] adalah jumlah poin yang dikurangi (positif).
  static Future<void> enqueueRedeem({
    required String orderId,
    required String userId,
    required int poinDigunakan,
  }) async {
    if (poinDigunakan <= 0) return;
    await _db.collection('poin_queue').add({
      'user_id': userId,
      'order_id': orderId,
      'tipe': 'redeem',
      'jumlah': poinDigunakan,
      'total_akhir': null,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  /// Antrekan ROLLBACK poin (dipanggil jika payment/order gagal setelah redeem).
  static Future<void> enqueueRollback({
    required String orderId,
    required String userId,
    required int poinDigunakan,
  }) async {
    if (poinDigunakan <= 0) return;
    await _db.collection('poin_queue').add({
      'user_id': userId,
      'order_id': orderId,
      'tipe': 'rollback',
      'jumlah': poinDigunakan,
      'total_akhir': null,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // ── Stream Riwayat Poin ──────────────────────────────────────────────

  /// Stream riwayat poin user (earn + redeem), diurutkan terbaru.
  static Stream<QuerySnapshot> streamRiwayatPoin(String userId) {
    return _db
        .collection('reward_poin')
        .where('user_id', isEqualTo: userId)
        .snapshots();
  }
}
