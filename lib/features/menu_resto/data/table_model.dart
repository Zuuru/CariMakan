import 'package:cloud_firestore/cloud_firestore.dart';

/// Model data untuk meja makan resto.
/// Dokumen disimpan di bawah sub-koleksi `tables` milik restoran:
/// `/restaurants/{restoId}/tables/{tableId}`
class TableModel {
  final String id; // Format: {restoId}_meja_{nomorMeja}
  final String restoId;
  final String nomorMeja;
  final String qrData; // URL/Payload QR: https://carimakan.com/scan?restoId=xxx&tableId=yyy
  final String status; // 'Tersedia' atau 'Terisi'
  final DateTime? createdAt;

  TableModel({
    required this.id,
    required this.restoId,
    required this.nomorMeja,
    required this.qrData,
    this.status = 'Tersedia',
    this.createdAt,
  });

  /// Konversi dari document snapshot Firestore ke TableModel
  factory TableModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return TableModel(
      id: doc.id,
      restoId: data['resto_id'] ?? '',
      nomorMeja: data['nomor_meja'] ?? '',
      qrData: data['qr_data'] ?? '',
      status: data['status'] ?? 'Tersedia',
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }

  /// Konversi dari TableModel ke Map untuk disimpan di Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'resto_id': restoId,
      'nomor_meja': nomorMeja,
      'qr_data': qrData,
      'status': status,
      'created_at': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  /// Helper untuk menyalin model dengan property yang diubah
  TableModel copyWith({
    String? id,
    String? restoId,
    String? nomorMeja,
    String? qrData,
    String? status,
    DateTime? createdAt,
  }) {
    return TableModel(
      id: id ?? this.id,
      restoId: restoId ?? this.restoId,
      nomorMeja: nomorMeja ?? this.nomorMeja,
      qrData: qrData ?? this.qrData,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
