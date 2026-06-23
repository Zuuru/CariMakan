import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/pesanan/data/cart_service.dart';
import '../../features/promo/data/promo_model.dart';
import 'midtrans_service.dart';

/// Data class representing a pending (unfinished) QRIS Midtrans payment.
class PendingPayment {
  final String midtransOrderId;
  final String qrString;
  final int grossAmount;
  final String restoId;
  final List<CartItemModel> cartItems;
  final String deliveryType;
  final String? nomorMeja;
  final String? tableId;
  final PromoModel? appliedPromo;
  final double discount;
  final double subtotal;
  final double finalTotal;
  final int poinDigunakan;
  final bool pakaiPoin;
  final DateTime createdAt;

  const PendingPayment({
    required this.midtransOrderId,
    required this.qrString,
    required this.grossAmount,
    required this.restoId,
    required this.cartItems,
    required this.deliveryType,
    this.nomorMeja,
    this.tableId,
    required this.appliedPromo,
    required this.discount,
    required this.subtotal,
    required this.finalTotal,
    required this.poinDigunakan,
    required this.pakaiPoin,
    required this.createdAt,
  });

  /// Returns true if this pending payment's cart matches [newItems] for [restoId].
  bool isSameOrder(List<CartItemModel> newItems, String newRestoId) {
    if (restoId != newRestoId) return false;
    if (cartItems.length != newItems.length) return false;

    final sortedExisting = [...cartItems]..sort((a, b) => a.menuId.compareTo(b.menuId));
    final sortedNew = [...newItems]..sort((a, b) => a.menuId.compareTo(b.menuId));

    for (int i = 0; i < sortedExisting.length; i++) {
      final e = sortedExisting[i];
      final n = sortedNew[i];
      if (!e.isSameAs(n) || e.quantity != n.quantity) return false;
    }
    return true;
  }

  /// Reconstruct from Firestore document data.
  factory PendingPayment.fromMap(Map<String, dynamic> data) {
    final itemsList = (data['cartItems'] as List<dynamic>? ?? [])
        .map((e) => CartItemModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    PromoModel? promo;
    final promoData = data['appliedPromo'];
    if (promoData != null && promoData is Map) {
      promo = PromoModel.fromMap(
        Map<String, dynamic>.from(promoData),
        promoData['id'] as String? ?? '',
      );
    }

    return PendingPayment(
      midtransOrderId: data['midtransOrderId'] as String? ?? '',
      qrString: data['qrString'] as String? ?? '',
      grossAmount: (data['grossAmount'] as num?)?.toInt() ?? 0,
      restoId: data['restoId'] as String? ?? '',
      cartItems: itemsList,
      deliveryType: data['deliveryType'] as String? ?? 'Take Away',
      nomorMeja: data['nomorMeja'] as String?,
      tableId: data['tableId'] as String?,
      appliedPromo: promo,
      discount: (data['discount'] as num?)?.toDouble() ?? 0.0,
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0.0,
      finalTotal: (data['finalTotal'] as num?)?.toDouble() ?? 0.0,
      poinDigunakan: (data['poinDigunakan'] as num?)?.toInt() ?? 0,
      pakaiPoin: data['pakaiPoin'] as bool? ?? false,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic>? promoMap;
    if (appliedPromo != null) {
      promoMap = appliedPromo!.toFirestore();
      promoMap['id'] = appliedPromo!.id;
    }

    return {
      'midtransOrderId': midtransOrderId,
      'qrString': qrString,
      'grossAmount': grossAmount,
      'restoId': restoId,
      'cartItems': cartItems.map((e) => e.toMap()).toList(),
      'deliveryType': deliveryType,
      'nomorMeja': nomorMeja,
      'tableId': tableId,
      'appliedPromo': promoMap,
      'discount': discount,
      'subtotal': subtotal,
      'finalTotal': finalTotal,
      'poinDigunakan': poinDigunakan,
      'pakaiPoin': pakaiPoin,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

/// Result returned by [PendingPaymentService.checkAndHandlePendingPayment].
enum PendingCheckAction {
  /// No pending payment — proceed normally to PembayaranPage.
  proceed,

  /// Same order found and still pending — restore the QRIS screen.
  restoreSameOrder,

  /// Different order found — user was warned and navigation was handled.
  differentOrderBlocked,
}

class PendingCheckResult {
  final PendingCheckAction action;
  final PendingPayment? pendingPayment;

  const PendingCheckResult({required this.action, this.pendingPayment});
}

class PendingPaymentService {
  static final _db = FirebaseFirestore.instance;

  static String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  static DocumentReference? _docRef() {
    final uid = _userId;
    if (uid == null) return null;
    return _db.collection('pending_payments').doc(uid);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Public API
  // ────────────────────────────────────────────────────────────────────────────

  /// Save [payment] to Firestore so it survives navigation changes.
  static Future<void> savePendingPayment(PendingPayment payment) async {
    final ref = _docRef();
    if (ref == null) return;
    try {
      await ref.set(payment.toMap());
    } catch (e) {
      debugPrint('PendingPaymentService: failed to save – $e');
    }
  }

  /// Delete the pending payment record for the current user.
  static Future<void> clearPendingPayment() async {
    final ref = _docRef();
    if (ref == null) return;
    try {
      await ref.delete();
    } catch (e) {
      debugPrint('PendingPaymentService: failed to clear – $e');
    }
  }

  /// Fetch the current pending payment, if any.
  static Future<PendingPayment?> getPendingPayment() async {
    final ref = _docRef();
    if (ref == null) return null;
    try {
      final doc = await ref.get();
      if (!doc.exists || doc.data() == null) return null;
      return PendingPayment.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      debugPrint('PendingPaymentService: failed to get – $e');
      return null;
    }
  }

  /// Called when user taps "Checkout / Pesan" in [RestoPage].
  ///
  /// Checks Firestore for a pending payment and:
  /// - If none → returns [PendingCheckAction.proceed].
  /// - If same order → returns [PendingCheckAction.restoreSameOrder] with data
  ///   so the caller can push PembayaranPage with restored state.
  /// - If different order → shows a dialog. Returns
  ///   [PendingCheckAction.differentOrderBlocked] so the caller does nothing
  ///   further (the dialog already handles navigation).
  static Future<PendingCheckResult> checkAndHandlePendingPayment({
    required BuildContext context,
    required List<CartItemModel> newCartItems,
    required String newRestoId,
  }) async {
    final pending = await getPendingPayment();
    if (pending == null) {
      return const PendingCheckResult(action: PendingCheckAction.proceed);
    }

    // Check Midtrans to see if payment has expired / was actually paid
    try {
      final status = await MidtransService.getTransactionStatus(pending.midtransOrderId);
      if (MidtransService.isPaymentSuccess(status)) {
        // Already paid in Midtrans but record wasn't cleaned — clear and proceed
        await clearPendingPayment();
        return const PendingCheckResult(action: PendingCheckAction.proceed);
      }
      if (status == 'expire' || status == 'cancel' || status == 'deny') {
        await clearPendingPayment();
        return const PendingCheckResult(action: PendingCheckAction.proceed);
      }
    } catch (_) {
      // If we can't reach Midtrans, still show the pending warning
    }

    if (pending.isSameOrder(newCartItems, newRestoId)) {
      // Same order — restore
      return PendingCheckResult(
        action: PendingCheckAction.restoreSameOrder,
        pendingPayment: pending,
      );
    }

    // Different order — warn the user
    if (context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Ada Pembayaran yang Belum Selesai ⚠️',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          content: Text(
            'Kamu masih punya tagihan QRIS yang belum dibayar dari pesanan sebelumnya.\n\n'
            'Selesaikan dulu pembayaran tersebut sebelum membuat pesanan baru.',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Nanti',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                // Navigate to the pending payment page
                // The caller will push PembayaranPage with restored data after we return
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD33400),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Bayar Sekarang',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    return PendingCheckResult(
      action: PendingCheckAction.differentOrderBlocked,
      pendingPayment: pending,
    );
  }
}
