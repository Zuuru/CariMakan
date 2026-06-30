import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carimakan/core/widgets/custom_back_button.dart';
import 'package:carimakan/core/services/midtrans_service.dart';
import 'package:carimakan/features/order/midtrans_payment_page.dart';
import 'package:carimakan/core/services/notification_service.dart';
import 'package:carimakan/features/pesanan/data/pesanan_service.dart';
import 'package:carimakan/features/pesanan/presentation/pages/order_receipt_page.dart';
import 'tracker_dine_in_page.dart';
import 'tracker_takeaway_page.dart';
import '../../data/cart_service.dart';
import '../../../promo/data/promo_model.dart';
import '../../../promo/data/promo_service.dart';
import '../../data/poin_service.dart';

class PembayaranPage extends StatefulWidget {
  final List<CartItemModel> cartItems;
  final String restoId;
  final String? tableId;
  final String? nomorMeja;

  const PembayaranPage({
    Key? key,
    required this.cartItems,
    required this.restoId,
    this.tableId,
    this.nomorMeja,
  }) : super(key: key);

  @override
  State<PembayaranPage> createState() => _PembayaranPageState();
}

class _PembayaranPageState extends State<PembayaranPage> {
  PromoModel? _selectedPromo;
  String _deliveryType = 'Take Away';
  String? _nomorMeja;
  int _userPoin = 0;
  bool _pakaiPoin = false;
  String _selectedPaymentMethod = 'QRIS';
  bool _isProcessing = false;

  String _restoAlamat = 'Jl. Setia Budi No.28, Ngesrep, Kec. Banyumanik, Kota Semarang, Jawa Tengah 50262';
  double? _restoLat;
  double? _restoLng;

  @override
  void initState() {
    super.initState();
    _nomorMeja = widget.nomorMeja;
    if (_nomorMeja != null && _nomorMeja!.isNotEmpty) {
      _deliveryType = 'Dine In';
    }
    _loadPoin();
    _fetchRestoLocation();
  }

  Future<void> _fetchRestoLocation() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restoId)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            if (data['lokasi_alamat'] != null && data['lokasi_alamat'].toString().isNotEmpty) {
              _restoAlamat = data['lokasi_alamat'] as String;
            }
            if (data['lokasi'] is GeoPoint) {
              final geo = data['lokasi'] as GeoPoint;
              _restoLat = geo.latitude;
              _restoLng = geo.longitude;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching restaurant location: $e');
    }
  }



  Future<void> _processCheckout({
    required double finalTotal,
    required double totalPrice,
    required double discount,
    required int poinDigunakan,
    required int poinDidapat,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final itemName = widget.cartItems.isEmpty
        ? 'Makanan'
        : (widget.cartItems.length == 1
            ? widget.cartItems.first.menuName
            : '${widget.cartItems.first.menuName} dan ${widget.cartItems.length - 1} lainnya');

    if (_selectedPaymentMethod == 'Tunai') {
      setState(() {
        _isProcessing = true;
      });

      try {
        final tableOrPickupInfo = _deliveryType == 'Dine In'
            ? 'Meja ${_nomorMeja ?? "-"}'
            : 'Take Away';

        // 1. Create order in Firestore
        final orderId = await PesananService.createOrder(
          cartItems: widget.cartItems,
          totalPrice: finalTotal,
          paymentMethod: 'Tunai',
          restoId: widget.restoId,
          appliedPromo: _selectedPromo,
          discount: discount,
          subtotal: totalPrice,
          type: _deliveryType,
          tableOrPickupInfo: tableOrPickupInfo,
        );

        // Update the status of the order to 'pending_tunai' (since createOrder sets status to 'paid')
        await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
          'status': 'pending_tunai',
          'poin_earned': false,
        });

        // 2. Clear global cart
        CartService.instance.clearCart(widget.restoId);

        // 3. Redeem points if applicable
        if (poinDigunakan > 0 && user != null) {
          await PoinService.enqueueRedeem(
            orderId: orderId,
            userId: user.uid,
            poinDigunakan: poinDigunakan,
          );
        }

        // 4. Send notification
        if (user != null) {
          await NotificationService().sendNotification(
            userId: user.uid,
            title: 'Pesanan Tunai Dibuat ⏳',
            body: 'Silakan lakukan pembayaran tunai di kasir sebesar ${_formatRupiah(finalTotal)}.',
            type: 'order_status',
            additionalData: {
              'orderId': orderId,
              'orderType': _deliveryType,
            },
          );
        }

        if (!mounted) return;

        // 5. Navigate directly to Tracker Page
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => _deliveryType == 'Dine In'
                ? TrackerDineInPage(orderId: orderId)
                : TrackerTakeawayPage(orderId: orderId),
          ),
          (route) => route.isFirst,
        );
      } catch (e) {
        debugPrint('Error creating cash order: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal membuat pesanan: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    } else if (_selectedPaymentMethod == 'Bypass') {
      setState(() {
        _isProcessing = true;
      });
      try {
        final tableOrPickupInfo = _deliveryType == 'Dine In'
            ? 'Meja ${_nomorMeja ?? "-"}'
            : 'Take Away';

        final orderId = await PesananService.createOrder(
          cartItems: widget.cartItems,
          totalPrice: finalTotal,
          paymentMethod: 'QRIS (Bypass)',
          restoId: widget.restoId,
          appliedPromo: _selectedPromo,
          discount: discount,
          subtotal: totalPrice,
          type: _deliveryType,
          tableOrPickupInfo: tableOrPickupInfo,
        );

        CartService.instance.clearCart(widget.restoId);

        if (poinDigunakan > 0 && user != null) {
          await PoinService.enqueueRedeem(
            orderId: orderId,
            userId: user.uid,
            poinDigunakan: poinDigunakan,
          );
        }
        if (user != null) {
          await PoinService.enqueueEarn(
            orderId: orderId,
            userId: user.uid,
            totalAkhir: finalTotal,
          );
        }

        if (user != null) {
          await NotificationService().sendNotification(
            userId: user.uid,
            title: 'Nunggu acc dari resto ⏳',
            body: 'Pembayaran ${_formatRupiah(finalTotal)} untuk pesanan $itemName telah berhasil dikonfirmasi (Bypass).',
            type: 'order_status',
            additionalData: {
              'orderId': orderId,
              'orderType': _deliveryType,
            },
          );
        }

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderReceiptPage(
              orderId: orderId,
              menuName: itemName,
              totalPrice: finalTotal,
              isTakeaway: _deliveryType == 'Take Away',
              poinDidapat: poinDidapat,
            ),
          ),
        );
      } catch (e) {
        debugPrint('Error bypass order: $e');
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    } else {
      setState(() {
        _isProcessing = true;
      });
      try {
        final totalSemua = finalTotal.toInt();
        final totalHargaItem = (totalPrice - discount).toInt();
        final ppn = (totalHargaItem * 0.1).toInt();
        // Perbaikan: tambahkan poinDigunakan untuk mengimbangi pengurangan poin di totalSemua
        // agar biayaLainnya kembali menjadi nilai positif (ongkir/fee sesungguhnya)
        final biayaLainnya = totalSemua - totalHargaItem - ppn + poinDigunakan;

        final qrisResult = await MidtransService.createQrisCharge(
          grossAmount: totalSemua,
          itemName: itemName,
          itemPrice: totalHargaItem,
          itemQuantity: 1,
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

        if (paymentResult != null && paymentResult.status == MidtransPaymentStatus.success) {
          final tableOrPickupInfo = _deliveryType == 'Dine In'
              ? 'Meja ${_nomorMeja ?? "-"}'
              : 'Take Away';

          final orderId = await PesananService.createOrder(
            cartItems: widget.cartItems,
            totalPrice: finalTotal,
            paymentMethod: 'QRIS',
            restoId: widget.restoId,
            appliedPromo: _selectedPromo,
            discount: discount,
            subtotal: totalPrice,
            type: _deliveryType,
            tableOrPickupInfo: tableOrPickupInfo,
          );

          CartService.instance.clearCart(widget.restoId);

          if (poinDigunakan > 0 && user != null) {
            await PoinService.enqueueRedeem(
              orderId: orderId,
              userId: user.uid,
              poinDigunakan: poinDigunakan,
            );
          }
          if (user != null) {
            await PoinService.enqueueEarn(
              orderId: orderId,
              userId: user.uid,
              totalAkhir: finalTotal,
            );
          }

          if (user != null) {
            await NotificationService().sendNotification(
              userId: user.uid,
              title: 'Nunggu acc dari resto ⏳',
              body: 'Pembayaran ${_formatRupiah(finalTotal)} untuk pesanan $itemName telah berhasil dikonfirmasi.',
              type: 'order_status',
              additionalData: {
                'orderId': orderId,
                'orderType': _deliveryType,
              },
            );
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OrderReceiptPage(
                orderId: orderId,
                menuName: itemName,
                totalPrice: finalTotal,
                isTakeaway: _deliveryType == 'Take Away',
                poinDidapat: poinDidapat,
              ),
            ),
          );
        }
      } catch (e) {
        if (user != null) {
          await NotificationService().sendNotification(
            userId: user.uid,
            title: 'Pembayaran Gagal ❌',
            body: 'Pembayaran sebesar ${_formatRupiah(finalTotal)} gagal diproses: $e',
            type: 'order_status',
          );
        }
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Oops!', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              content: Text('Gagal memulai pembayaran: $e', style: GoogleFonts.poppins(fontSize: 13)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Tutup', style: GoogleFonts.poppins(color: const Color(0xFFD33400))),
                ),
              ],
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  Widget _buildPaymentMethodOption({
    required String method,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final bool isSelected = _selectedPaymentMethod == method;
    final bool isTakeaway = _deliveryType == 'Take Away';
    final bool isTunai = method == 'Tunai';
    final bool isDisabled = isTakeaway && isTunai;

    return Opacity(
      opacity: isDisabled ? 0.4 : 1.0,
      child: InkWell(
        onTap: isDisabled
            ? null
            : () {
                setState(() {
                  _selectedPaymentMethod = method;
                });
              },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? const Color(0xFFD33400) : Colors.grey, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? const Color(0xFFD33400) : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Radio<String>(
                value: method,
                groupValue: _selectedPaymentMethod,
                activeColor: const Color(0xFFD33400),
                onChanged: isDisabled
                    ? null
                    : (val) {
                        if (val != null) {
                          setState(() {
                            _selectedPaymentMethod = val;
                          });
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadPoin() async {
    final poin = await PoinService.getPoinUser();
    if (mounted) {
      setState(() {
        _userPoin = poin;
      });
    }
  }



  Future<String?> _showTableNumberDialog(String? currentNumber) async {
    final controller = TextEditingController(text: currentNumber);
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Nomor Meja',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Masukkan nomor meja (misal: 03)',
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFD33400)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, controller.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD33400),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Simpan',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatRupiah(double value) {
    final String valStr = value.toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final String formatted = valStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return 'Rp $formatted';
  }

  double _calculateDiscount(double totalPrice, PromoModel promo) {
    if (promo.isPercent) {
      double calculated = totalPrice * (promo.nilaiDiskon / 100.0);
      if (promo.maksDiskon != null) {
        if (calculated > promo.maksDiskon!) {
          return promo.maksDiskon!.toDouble();
        }
      }
      return calculated;
    } else {
      if (promo.nilaiDiskon > totalPrice) {
        return totalPrice;
      }
      return promo.nilaiDiskon.toDouble();
    }
  }

  void _showPromoBottomSheet(BuildContext context, double subtotal, int totalItems) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pilih Promo Resto',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<List<PromoModel>>(
                  stream: PromoService.getPromosByResto(widget.restoId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFFD33400)));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          'Tidak ada promo tersedia saat ini',
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      );
                    }

                    // Filter only active and current promos
                    final activePromos = snapshot.data!.where((promo) {
                      return promo.isActive && 
                             !promo.isExpired && 
                             !promo.isUpcoming;
                    }).toList();

                    if (activePromos.isEmpty) {
                      return Center(
                        child: Text(
                          'Tidak ada promo aktif',
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: activePromos.length,
                      itemBuilder: (context, index) {
                        final promo = activePromos[index];
                        final bool meetsMinBelanja = subtotal >= promo.minBelanja;
                        final bool meetsMinItem = totalItems >= promo.minItem;
                        final bool isEligible = meetsMinBelanja && meetsMinItem;

                        String ineligibilityReason = '';
                        if (!meetsMinBelanja && !meetsMinItem) {
                          ineligibilityReason = 'Belum memenuhi min. belanja ${widget.cartItems.isNotEmpty ? _formatRupiah(promo.minBelanja.toDouble()) : ''} & min. ${promo.minItem} item';
                        } else if (!meetsMinBelanja) {
                          ineligibilityReason = 'Belum memenuhi min. belanja ${_formatRupiah(promo.minBelanja.toDouble())}';
                        } else if (!meetsMinItem) {
                          ineligibilityReason = 'Belum memenuhi min. ${promo.minItem} item';
                        }

                        return Opacity(
                          opacity: isEligible ? 1.0 : 0.6,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isEligible ? const Color(0xFFFFF1F1) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _selectedPromo?.id == promo.id
                                    ? const Color(0xFFD33400)
                                    : (isEligible ? const Color(0xFFFFCDCD) : Colors.grey.shade300),
                                width: _selectedPromo?.id == promo.id ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        promo.nama,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isEligible ? Colors.black : Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      promo.diskonLabel,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: const Color(0xFFD33400),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  promo.deskripsi,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        isEligible ? 'Kode: ${promo.kode ?? "-"}' : ineligibilityReason,
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: isEligible ? Colors.black54 : Colors.red,
                                          fontWeight: isEligible ? FontWeight.normal : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if (isEligible)
                                      ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            _selectedPromo = promo;
                                          });
                                          Navigator.pop(context);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFD33400),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          _selectedPromo?.id == promo.id ? 'Terpasang' : 'Gunakan',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
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
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double totalPrice = widget.cartItems.fold(0.0, (sum, item) => sum + (item.totalPrice * item.quantity));
    final int totalItemsCount = widget.cartItems.fold(0, (sum, item) => sum + item.quantity);
    final double discount = _selectedPromo != null ? _calculateDiscount(totalPrice, _selectedPromo!) : 0.0;
    
    // Tax calculated after discount
    final double ppn = (totalPrice - discount) * 0.10;
    final double biayaLain = 1000.0;
    final double subtotalBeforePoin = (totalPrice - discount) + ppn + biayaLain;
    
    final int maksPotonganPoin = PoinService.hitungMaksPotongan(subtotalBeforePoin);
    final int poinDigunakan = _pakaiPoin ? PoinService.hitungPoinDigunakan(_userPoin, subtotalBeforePoin) : 0;
    
    final double finalTotal = subtotalBeforePoin - poinDigunakan;
    final int poinDidapat = (finalTotal * 0.5 / 100).floor();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 72,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: Center(child: CustomBackButton()),
        ),
        title: Text(
          'Pembayaran',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom Segmented Control for Delivery Type
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Stack(
                    children: [
                      // Animated background slider
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        alignment: _deliveryType == 'Dine In'
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: FractionallySizedBox(
                          widthFactor: 0.5,
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD33400),
                              borderRadius: BorderRadius.circular(21),
                            ),
                          ),
                        ),
                      ),
                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                if (_deliveryType != 'Dine In') {
                                  final nomor = await _showTableNumberDialog(_nomorMeja);
                                  setState(() {
                                    _deliveryType = 'Dine In';
                                    if (nomor != null && nomor.isNotEmpty) {
                                      _nomorMeja = nomor;
                                    }
                                  });
                                }
                              },
                              child: Container(
                                color: Colors.transparent,
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.restaurant,
                                      color: _deliveryType == 'Dine In' ? Colors.white : Colors.grey[600],
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _deliveryType == 'Dine In' && _nomorMeja != null && _nomorMeja!.isNotEmpty
                                          ? 'Dine In ($_nomorMeja)'
                                          : 'Dine In',
                                      style: GoogleFonts.poppins(
                                        color: _deliveryType == 'Dine In' ? Colors.white : Colors.grey[800],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _deliveryType = 'Take Away';
                                  _nomorMeja = null;
                                  if (_selectedPaymentMethod == 'Tunai') {
                                    _selectedPaymentMethod = 'QRIS';
                                  }
                                });
                              },
                              child: Container(
                                color: Colors.transparent,
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.shopping_bag_outlined,
                                      color: _deliveryType == 'Take Away' ? Colors.white : Colors.grey[600],
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Takeaway',
                                      style: GoogleFonts.poppins(
                                        color: _deliveryType == 'Take Away' ? Colors.white : Colors.grey[800],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_deliveryType == 'Dine In') ...[
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton.icon(
                      onPressed: () async {
                        final nomor = await _showTableNumberDialog(_nomorMeja);
                        if (nomor != null && nomor.isNotEmpty) {
                          setState(() {
                            _nomorMeja = nomor;
                          });
                        }
                      },
                      icon: const Icon(Icons.edit, size: 14, color: Color(0xFFD33400)),
                      label: Text(
                        _nomorMeja != null && _nomorMeja!.isNotEmpty
                            ? 'Ubah Nomor Meja (Meja $_nomorMeja)'
                            : 'Masukkan Nomor Meja',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFD33400),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
            const SizedBox(height: 16),

            // Lokasi Resto
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lokasi Resto',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _restoAlamat,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Items List
            Column(
              children: widget.cartItems.map((item) {
                // Compile variant text
                List<String> variantTexts = [];
                item.selectedVariants.forEach((groupName, opts) {
                  if (opts.isNotEmpty) {
                    final itemNames = opts.map((e) => e['nama']).join(', ');
                    variantTexts.add('$groupName: $itemNames');
                  }
                });
                String variantText = variantTexts.isEmpty ? 'Tidak ada kustomisasi' : variantTexts.join('\n');

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD33400),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.menuName,
                              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              variantText,
                              style: GoogleFonts.poppins(color: Colors.white, fontSize: 10),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatRupiah(item.totalPrice * item.quantity),
                              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: item.menuImage.startsWith('http')
                                  ? Image.network(item.menuImage, width: 80, height: 80, fit: BoxFit.cover)
                                  : Image.asset(item.menuImage, width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (ctx, err, trace) => Container(width: 80, height: 80, color: Colors.white24, child: const Icon(Icons.fastfood, color: Colors.white))),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                              child: Text('${item.quantity}x', style: GoogleFonts.poppins(color: const Color(0xFFD33400), fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Promo Resto Selector Widget
            GestureDetector(
              onTap: () => _showPromoBottomSheet(context, totalPrice, totalItemsCount),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFCDCD)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.confirmation_number_outlined, color: Color(0xFFD33400), size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedPromo != null ? _selectedPromo!.nama : 'Pakai Promo Resto',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  _selectedPromo != null 
                                      ? _selectedPromo!.deskripsi 
                                      : 'Makin hemat pakai promo dari resto ini',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.black54,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _selectedPromo != null
                        ? GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedPromo = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFD33400),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 14),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD33400),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Pilih',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Section Poin Reward
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
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
                    'Poin kamu: $_userPoin poin (= ${_formatRupiah(_userPoin.toDouble())})',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                  ),
                  if (_pakaiPoin) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Potongan: ${_formatRupiah(poinDigunakan.toDouble())}',
                      style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFFD33400), fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Maks pakai: ${_formatRupiah(maksPotonganPoin.toDouble())} (25% dari pesanan)',
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Pilih Metode Pembayaran
            Text(
              'Pilih Metode Pembayaran',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildPaymentMethodOption(
                    method: 'QRIS',
                    title: 'QRIS (Midtrans)',
                    subtitle: 'Bayar instan via GoPay, DANA, ShopeePay, dll',
                    icon: Icons.qr_code,
                  ),
                  if (_deliveryType != 'Take Away') ...[
                    const Divider(height: 1),
                    _buildPaymentMethodOption(
                      method: 'Tunai',
                      title: 'Tunai (Cash)',
                      subtitle: 'Bayar di kasir, scan QR untuk terima poin',
                      icon: Icons.money,
                    ),
                  ],
                  const Divider(height: 1),
                  _buildPaymentMethodOption(
                    method: 'Bypass',
                    title: 'Bypass QRIS (Testing)',
                    subtitle: 'Langsung sukses bayar tanpa lewat Midtrans',
                    icon: Icons.bolt,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Detail Pesanan
            Text(
              'Detail pesanan kamu nyakk',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFD33400),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildPriceRow('Harga', _formatRupiah(totalPrice)),
                  if (discount > 0) ...[
                    const SizedBox(height: 8),
                    _buildPriceRow('Potongan Promo', '- ${_formatRupiah(discount)}'),
                  ],
                  const SizedBox(height: 8),
                  _buildPriceRow('PPN', _formatRupiah(ppn)),
                  const SizedBox(height: 8),
                  _buildPriceRow('Biaya lainnya', _formatRupiah(biayaLain)),
                  if (poinDigunakan > 0) ...[
                    const SizedBox(height: 8),
                    _buildPriceRow('Potongan Poin', '- ${_formatRupiah(poinDigunakan.toDouble())}'),
                  ],
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white54, thickness: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _formatRupiah(finalTotal),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
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

            // Checkout Button
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return Dialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Kamu udah yakin ama pesenan kamu?',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            // Placeholder for character image
                            const Icon(Icons.person, size: 100, color: Colors.grey),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Color(0xFFD33400)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: Text(
                                        'Ntar',
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFFD33400),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context); // close dialog
                                      _processCheckout(
                                        finalTotal: finalTotal,
                                        totalPrice: totalPrice,
                                        discount: discount,
                                        poinDigunakan: poinDigunakan,
                                        poinDidapat: poinDidapat,
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFD33400),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      'Iyaa',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
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
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD33400),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                minimumSize: const Size(double.infinity, 54),
                elevation: 0,
              ),
              child: Text(
                'Gass Bayarr!!',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      if (_isProcessing)
        Container(
          color: Colors.black.withOpacity(0.3),
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFD33400),
            ),
          ),
        ),
    ],
  ),
);
}

  Widget _buildPriceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
