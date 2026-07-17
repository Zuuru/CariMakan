import 'package:cloud_firestore/cloud_firestore.dart';
import 'table_model.dart';

/// Service untuk memfasilitasi operasi CRUD Meja ke Firestore.
/// Disimpan di sub-koleksi `tables` milik dokumen restaurant terkait:
/// `/restaurants/{restoId}/tables/{tableId}`
class TableService {
  static final _db = FirebaseFirestore.instance;

  /// Mendapatkan reference koleksi tables untuk restaurant tertentu
  static CollectionReference _getCollectionRef(String restoId) {
    return _db.collection('restaurants').doc(restoId).collection('tables');
  }

  /// Stream real-time daftar meja makan milik sebuah resto
  static Stream<List<TableModel>> getTablesStream(String restoId) {
    return _getCollectionRef(restoId)
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TableModel.fromFirestore(doc))
            .toList());
  }

  /// Memeriksa apakah nomor meja tertentu sudah terdaftar di resto tersebut
  static Future<bool> checkTableExists(String restoId, String nomorMeja) async {
    // Bersihkan spasi depan/belakang untuk perbandingan yang akurat
    final cleanedNomor = nomorMeja.trim();
    final docId = '${restoId}_meja_$cleanedNomor';
    
    final docSnapshot = await _getCollectionRef(restoId).doc(docId).get();
    return docSnapshot.exists;
  }

  /// Menambahkan meja baru ke Firestore
  static Future<void> tambahMeja(String restoId, String nomorMeja) async {
    final cleanedNomor = nomorMeja.trim();
    final docId = '${restoId}_meja_$cleanedNomor';
    
    // Format URL Scan: https://carimakan.com/scan?restoId=restoId&tableId=tableId
    final qrData = 'https://carimakan.com/scan?restoId=$restoId&tableId=$docId';

    final table = TableModel(
      id: docId,
      restoId: restoId,
      nomorMeja: cleanedNomor,
      qrData: qrData,
      status: 'Tersedia',
    );

    await _getCollectionRef(restoId).doc(docId).set(table.toFirestore());
  }

  /// Menghapus meja dari Firestore
  static Future<void> hapusMeja(String restoId, String tableId) async {
    await _getCollectionRef(restoId).doc(tableId).delete();
  }

  /// Mengubah status meja (Tersedia / Terisi)
  static Future<void> updateTableStatus(
    String restoId,
    String tableId,
    String status,
  ) async {
    await _getCollectionRef(restoId).doc(tableId).update({
      'status': status,
    });
  }
}
