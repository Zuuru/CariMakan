import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carimakan/core/services/midtrans_service.dart';
import 'package:carimakan/features/order/midtrans_payment_page.dart';
import 'package:carimakan/features/pesanan/data/poin_service.dart';
import 'cart_summary_bar.dart'; // File tempat globalCartQuantity & globalSubtotal berada

class PembayaranPage extends StatefulWidget {
  final String name;
  final String price;
  final String imagePath;
  final String sugar;
  final String ice;
  final List<String> addOns;

  const PembayaranPage({
    super.key,
    required this.name,
    required this.price,
    required this.imagePath,
    required this.sugar,
    required this.ice,
    required this.addOns,
  });

  @override
  State<PembayaranPage> createState() => _PembayaranPageState();
}

class _PembayaranPageState extends State<PembayaranPage> {
  int _itemQuantity = 1;
  bool _isProcessingPayment = false;
  int _userPoin = 0;
  bool _pakaiPoin = false;

  @override
  void initState() {
    super.initState();
    _loadPoin();
  }

  Future<void> _loadPoin() async {
    final poin = await PoinService.getPoinUser();
    if (mounted) {
      setState(() {
        _userPoin = poin;
      });
    }
  }

  // Fungsi pembantu untuk mengubah format rupiah string menjadi integer murni
  int _parsePrice(String priceString) {
    String cleaned = priceString.replaceAll('.', '').replaceAll('Rp', '').trim();
    return int.tryParse(cleaned) ?? 0;
  }

  // Fungsi format kembali ke mata uang rupiah standard teks
  String _formatRupiah(int amount) {
    String str = amount.toString();
    String result = '';
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      result = str[i] + result;
      count++;
      if (count == 3 && i != 0) {
        result = '.$result';
        count = 0;
      }
    }
    return 'Rp $result';
  }

  // Fungsi untuk kembali dengan membawa data kuantitas terbaru
  void _kembaliDenganData() {
    Navigator.pop(context, _itemQuantity);
  }

  @override
  Widget build(BuildContext context) {
    int hargaSatuan = _parsePrice(widget.price);
    int totalHargaItem = hargaSatuan * _itemQuantity;
    
    int ppn = _itemQuantity > 0 ? (totalHargaItem * 0.1).toInt() : 0; 
    int biayaLainnya = _itemQuantity > 0 ? 1000 : 0; 
    
    int subtotal = totalHargaItem + ppn + biayaLainnya;
    int maksPotonganPoin = _itemQuantity > 0 ? PoinService.hitungMaksPotongan(subtotal.toDouble()) : 0;
    int poinDigunakan = (_pakaiPoin && _itemQuantity > 0) ? PoinService.hitungPoinDigunakan(_userPoin, subtotal.toDouble()) : 0;
    
    int totalSemua = subtotal - poinDigunakan;
    int poinDidapat = (totalSemua * 0.5 / 100).floor();

    // Sinkronisasi nilai totalSemua ke globalSubtotal tanpa merusak siklus build Flutter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      globalSubtotal.value = totalSemua;
      globalCartQuantity.value = _itemQuantity;
    });

    // PopScope digunakan agar ketika user menekan tombol back bawaan HP, data kuantitas tetap terkirim balik
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _kembaliDenganData();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            onPressed: _kembaliDenganData,
          ),
          title: const Text(
            'Pembayaran',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Card Opsi Pengiriman (Takeaway)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/takeaway_icon.png', 
                      width: 40,
                      height: 40,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.shopping_bag_outlined, color: Color(0xFFD33400), size: 35),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Takeaway',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                    ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD33400)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      ),
                      child: Text('Ganti', style: GoogleFonts.poppins(color: const Color(0xFFD33400), fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
  
              // 2. Card Lokasi Resto
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lokasi Resto',
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Jl. Setia Budi No.28, Ngesrep, Kec. Banyumanik, Kota Semarang, Jawa Tengah 50262',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final Uri url = Uri.parse(
                            'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent('Jl. Setia Budi No.28, Ngesrep, Kec. Banyumanik, Kota Semarang, Jawa Tengah 50262')}'
                          );
                          final bool launched = await launchUrl(url, mode: LaunchMode.externalApplication);
                          if (!launched) {
                            await launchUrl(url);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD33400),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        ),
                        icon: const Icon(Icons.navigation, size: 14, color: Colors.white),
                        label: Text('Rute', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 20),
  
              // 3. Logika Kondisional Card Produk
              if (_itemQuantity > 0) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD33400),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.name,
                              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text('Gula : ${widget.sugar}', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11)),
                            Text('Es : ${widget.ice}', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11)),
                            Text('Add On : ${widget.addOns.join(', ')}', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11)),
                            const SizedBox(height: 12),
                            Text(
                              _formatRupiah(totalHargaItem),
                              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _kembaliDenganData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                minimumSize: const Size(60, 25),
                              ),
                              child: Text('Edit', style: GoogleFonts.poppins(color: const Color(0xFFD33400), fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.asset(
                              widget.imagePath,
                              width: 85,
                              height: 85,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(width: 85, height: 85, color: Colors.grey),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (_itemQuantity > 0) {
                                      setState(() => _itemQuantity--);
                                    }
                                  },
                                  child: const Icon(Icons.remove, size: 16, color: Color(0xFFD33400)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(
                                    '$_itemQuantity',
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 13),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() => _itemQuantity++);
                                  },
                                  child: const Icon(Icons.add, size: 16, color: Color(0xFFD33400)),
                                ),
                              ],
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
  
              // 4. Tambah Menu Lain Banner
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mau nambah yang lain?',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
                  ),
                  OutlinedButton(
                    onPressed: _kembaliDenganData,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFD33400)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    ),
                    child: Text('Tambah', style: GoogleFonts.poppins(color: const Color(0xFFD33400), fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // 4.5. Section Poin Reward
              Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('💰', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Reward Poin',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          Switch(
                            value: _pakaiPoin,
                            activeColor: const Color(0xFFD33400),
                            onChanged: _userPoin > 0 ? (value) {
                              setState(() {
                                _pakaiPoin = value;
                              });
                            } : null,
                          ),
                        ],
                      ),
                      Text(
                        'Poin kamu: $_userPoin poin (= ${_formatRupiah(_userPoin)})',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                      ),
                      if (_pakaiPoin) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Potongan: ${_formatRupiah(poinDigunakan)}',
                          style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFFD33400), fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Maks pakai: ${_formatRupiah(maksPotonganPoin)} (25% dari pesanan)',
                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
  
              // 5. Section Detail Nota Pembayaran Ringkasan
              Text(
                'Detail pesanan kamu nyakk',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFD33400),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _buildNotaRow('Harga', _formatRupiah(totalHargaItem)),
                    const SizedBox(height: 8),
                    _buildNotaRow('PPN', _formatRupiah(ppn)),
                    const SizedBox(height: 8),
                    _buildNotaRow('Biaya lainnya', _formatRupiah(biayaLainnya)),
                    if (poinDigunakan > 0) ...[
                      const SizedBox(height: 8),
                      _buildNotaRow('Potongan Poin', '-${_formatRupiah(poinDigunakan)}'),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(color: Colors.white, thickness: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(_formatRupiah(totalSemua), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    if (poinDidapat > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Poin didapatkan', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11)),
                          Text('+$poinDidapat poin', style: GoogleFonts.poppins(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
  
              // 6. Tombol Utama
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _itemQuantity > 0 && !_isProcessingPayment
                      ? () => _showKonfirmasiDialog(context, totalSemua, totalHargaItem, ppn, biayaLainnya, poinDigunakan)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD33400),
                    disabledBackgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isProcessingPayment
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Gass Bayarr!!',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Dialog 1: Konfirmasi Pesanan
  void _showKonfirmasiDialog(
    BuildContext context,
    int totalSemua,
    int totalHargaItem,
    int ppn,
    int biayaLainnya,
    int poinDigunakan,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Kamu udah yakin ama\npesenan kamu?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                const SizedBox(height: 16),
                Image.asset(
                  'assets/images/character_confirm/character_confirm.jpg', 
                  height: 180,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.check_circle_outline, size: 80, color: Color(0xFFD33400)),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFD33400), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text('Ntar', style: GoogleFonts.poppins(color: const Color(0xFFD33400), fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                            _startMidtransPayment(
                              totalSemua: totalSemua,
                              totalHargaItem: totalHargaItem,
                              ppn: ppn,
                              biayaLainnya: biayaLainnya,
                              poinDigunakan: poinDigunakan,
                            );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD33400),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: Text('Iyaa', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _startMidtransPayment({
    required int totalSemua,
    required int totalHargaItem,
    required int ppn,
    required int biayaLainnya,
    required int poinDigunakan,
  }) async {
    setState(() => _isProcessingPayment = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final qrisResult = await MidtransService.createQrisCharge(
        grossAmount: totalSemua,
        itemName: widget.name,
        itemPrice: totalHargaItem ~/ _itemQuantity,
        itemQuantity: _itemQuantity,
        ppn: ppn,
        otherFee: biayaLainnya,
        poinDiscount: poinDigunakan,
        customerName: user?.displayName ?? 'Pelanggan CariMakan',
        customerEmail: user?.email ?? 'customer@carimakan.app',
      );

      if (!mounted) return;

      final paymentResult = await Navigator.push<MidtransPaymentResult>(
        context,
        MaterialPageRoute(
          builder: (context) => MidtransQrisPage(qrisResult: qrisResult),
        ),
      );

      if (!mounted) return;

      if (paymentResult != null) {
        if (paymentResult.status == MidtransPaymentStatus.success) {
          if (poinDigunakan > 0 && user != null) {
            await PoinService.enqueueRedeem(
              orderId: paymentResult.orderId ?? '',
              userId: user.uid,
              poinDigunakan: poinDigunakan,
            );
          }
          if (user != null) {
            await PoinService.enqueueEarn(
              orderId: paymentResult.orderId ?? '',
              userId: user.uid,
              totalAkhir: totalSemua.toDouble(),
            );
          }
        }
        _showPaymentResultDialog(paymentResult, totalSemua);
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Gagal memulai pembayaran: $e');
    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }

  void _showPaymentResultDialog(MidtransPaymentResult result, int totalAmount) {
    final isSuccess = result.status == MidtransPaymentStatus.success;
    final isPending = result.status == MidtransPaymentStatus.pending;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSuccess
                      ? Icons.check_circle
                      : isPending
                          ? Icons.schedule
                          : Icons.error_outline,
                  size: 64,
                  color: isSuccess
                      ? Colors.green
                      : isPending
                          ? Colors.orange
                          : const Color(0xFFD33400),
                ),
                const SizedBox(height: 16),
                Text(
                  isSuccess
                      ? 'Pembayaran Berhasil!'
                      : isPending
                          ? 'Menunggu Pembayaran'
                          : 'Pembayaran Gagal',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  result.message ?? '',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
                ),
                if (result.orderId != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Order ID: ${result.orderId}',
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  _formatRupiah(totalAmount),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFD33400),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD33400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'OK',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Oops!',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tutup',
              style: GoogleFonts.poppins(color: const Color(0xFFD33400)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
        Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}