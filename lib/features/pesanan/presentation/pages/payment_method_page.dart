import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carimakan/core/widgets/custom_back_button.dart';
import 'package:carimakan/core/services/midtrans_service.dart';
import 'package:carimakan/features/order/midtrans_payment_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/cart_service.dart';
import '../../data/pesanan_service.dart';
import '../../../promo/data/promo_model.dart';
import 'order_receipt_page.dart';
import '../../data/poin_service.dart';
import 'package:carimakan/core/services/notification_service.dart';

class PaymentMethodPage extends StatefulWidget {
  final List<CartItemModel> cartItems;
  final double totalPrice;
  final String restoId;
  final PromoModel? appliedPromo;
  final double discount;
  final double subtotal;
  final String type;
  final String tableOrPickupInfo;
  final int poinDigunakan;
  final int poinDidapat;

  const PaymentMethodPage({
    Key? key,
    required this.cartItems,
    required this.totalPrice,
    required this.restoId,
    this.appliedPromo,
    this.discount = 0.0,
    required this.subtotal,
    required this.type,
    required this.tableOrPickupInfo,
    this.poinDigunakan = 0,
    this.poinDidapat = 0,
  }) : super(key: key);

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  bool _isProcessingPayment = false;

  String _formatRupiah(double value) {
    final String valStr = value.toInt().toString();
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final String formatted = valStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
    return 'Rp $formatted';
  }

  Future<void> _startMidtransPayment() async {
    setState(() => _isProcessingPayment = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      final totalSemua = widget.totalPrice.toInt();
      final totalHargaItem = (widget.subtotal - widget.discount).toInt();
      final ppn = (totalHargaItem * 0.1).toInt();
      final biayaLainnya = totalSemua - totalHargaItem - ppn;

      final itemName = widget.cartItems.isEmpty 
          ? 'Makanan' 
          : (widget.cartItems.length == 1 
              ? widget.cartItems.first.menuName 
              : '${widget.cartItems.first.menuName} dan ${widget.cartItems.length - 1} lainnya');

      final qrisResult = await MidtransService.createQrisCharge(
        grossAmount: totalSemua,
        itemName: itemName,
        itemPrice: totalHargaItem,
        itemQuantity: 1,
        ppn: ppn,
        otherFee: biayaLainnya,
        poinDiscount: widget.poinDigunakan,
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
        // Write order to Firestore first, before clearing the cart reference!
        final orderId = await PesananService.createOrder(
          cartItems: widget.cartItems,
          totalPrice: widget.totalPrice,
          paymentMethod: 'QRIS',
          restoId: widget.restoId,
          appliedPromo: widget.appliedPromo,
          discount: widget.discount,
          subtotal: widget.subtotal,
          type: widget.type,
          tableOrPickupInfo: widget.tableOrPickupInfo,
        );

        // Clear global cart after successful order creation
        CartService.instance.clearCart(widget.restoId);

        if (widget.poinDigunakan > 0 && user != null) {
          await PoinService.enqueueRedeem(
            orderId: orderId,
            userId: user.uid,
            poinDigunakan: widget.poinDigunakan,
          );
        }
        if (user != null) {
          await PoinService.enqueueEarn(
            orderId: orderId,
            userId: user.uid,
            totalAkhir: widget.totalPrice,
          );
        }

        if (user != null) {
          await NotificationService().sendNotification(
            userId: user.uid,
            title: 'Pembayaran Berhasil! 💳',
            body: 'Pembayaran ${_formatRupiah(widget.totalPrice)} untuk pesanan $itemName telah berhasil dikonfirmasi.',
            type: 'order_status',
            additionalData: {
              'orderId': orderId,
              'orderType': widget.type,
            },
          );
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderReceiptPage(
              orderId: orderId,
              menuName: itemName,
              totalPrice: widget.totalPrice,
              isTakeaway: widget.type == 'Take Away',
              poinDidapat: widget.poinDidapat,
            ),
          ),
        );
      }
    } catch (e) {
      if (user != null) {
        await NotificationService().sendNotification(
          userId: user.uid,
          title: 'Pembayaran Gagal ❌',
          body: 'Pembayaran sebesar ${_formatRupiah(widget.totalPrice)} gagal diproses: $e',
          type: 'order_status',
        );
      }
      if (!mounted) return;
      _showErrorDialog('Gagal memulai pembayaran: $e');
    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }

  Future<void> _bypassPayment() async {
    setState(() => _isProcessingPayment = true);

    try {
      final itemName = widget.cartItems.isEmpty 
          ? 'Makanan' 
          : (widget.cartItems.length == 1 
              ? widget.cartItems.first.menuName 
              : '${widget.cartItems.first.menuName} dan ${widget.cartItems.length - 1} lainnya');

      // Write order to Firestore first, before clearing the cart reference!
      final orderId = await PesananService.createOrder(
        cartItems: widget.cartItems,
        totalPrice: widget.totalPrice,
        paymentMethod: 'QRIS (Bypass)',
        restoId: widget.restoId,
        appliedPromo: widget.appliedPromo,
        discount: widget.discount,
        subtotal: widget.subtotal,
        type: widget.type,
        tableOrPickupInfo: widget.tableOrPickupInfo,
      );

      // Clear global cart after successful order creation
      CartService.instance.clearCart(widget.restoId);

      final user = FirebaseAuth.instance.currentUser;
      if (widget.poinDigunakan > 0 && user != null) {
        await PoinService.enqueueRedeem(
          orderId: orderId,
          userId: user.uid,
          poinDigunakan: widget.poinDigunakan,
        );
      }
      if (user != null) {
        await PoinService.enqueueEarn(
          orderId: orderId,
          userId: user.uid,
          totalAkhir: widget.totalPrice,
        );
      }

      if (user != null) {
        await NotificationService().sendNotification(
          userId: user.uid,
          title: 'Pembayaran Berhasil! 💳',
          body: 'Pembayaran ${_formatRupiah(widget.totalPrice)} untuk pesanan $itemName telah berhasil dikonfirmasi (Bypass).',
          type: 'order_status',
          additionalData: {
            'orderId': orderId,
            'orderType': widget.type,
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
            totalPrice: widget.totalPrice,
            isTakeaway: widget.type == 'Take Away',
            poinDidapat: widget.poinDidapat,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Gagal memproses bypass: $e');
    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
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

  @override
  Widget build(BuildContext context) {
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
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Pembayaran',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Silakan pilih metode pembayaran QRIS Midtrans di bawah ini untuk melanjutkan pembayaran secara dinamis sesuai pesanan.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),

                // Metode Pembayaran Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pilih Metode Pembayaran',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '2 Metode Tersedia',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // QRIS Method Item
                _buildMethodItem(
                  imagePath: 'assets/images/Icon/qris.png',
                  title: 'QRIS (Midtrans)',
                  subtitle: 'Bayar instan via GoPay, ShopeePay, DANA, OVO, dll',
                  onTap: _isProcessingPayment ? () {} : _startMidtransPayment,
                ),
                const SizedBox(height: 16),

                // Bypass Method Item
                _buildMethodItem(
                  imagePath: 'assets/images/Icon/qris.png',
                  title: 'Bypass QRIS (Testing)',
                  subtitle: 'Langsung sukses bayar tanpa lewat Midtrans',
                  onTap: _isProcessingPayment ? () {} : _bypassPayment,
                ),
                const SizedBox(height: 32),

                // Total Ringkasan Mini
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Pembayaran',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _formatRupiah(widget.totalPrice),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFD33400),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          if (_isProcessingPayment)
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

  Widget _buildMethodItem({
    required String imagePath,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFD33400), width: 1.5),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD33400).withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Image.asset(imagePath, height: 28, errorBuilder: (context, error, stackTrace) => const Icon(Icons.qr_code, color: Color(0xFFD33400))),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFD33400)),
          ],
        ),
      ),
    );
  }
}
