import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carimakan/core/widgets/custom_back_button.dart';
import '../../data/cart_service.dart';
import 'payment_method_page.dart';
import '../../../promo/data/promo_model.dart';
import '../../../promo/data/promo_service.dart';

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

  @override
  void initState() {
    super.initState();
    _nomorMeja = widget.nomorMeja;
    if (_nomorMeja != null && _nomorMeja!.isNotEmpty) {
      _deliveryType = 'Dine In';
    }
  }

  void _showDeliveryTypeBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        String? localNomorMeja = _nomorMeja;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pilih Opsi Pengiriman',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(Icons.restaurant, color: Color(0xFFD33400)),
                    title: Text(
                      localNomorMeja != null && localNomorMeja!.isNotEmpty
                          ? 'Dine In (Meja $localNomorMeja)'
                          : 'Dine In',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    subtitle: localNomorMeja == null || localNomorMeja!.isEmpty
                        ? Text('Masukkan nomor meja Anda', style: GoogleFonts.poppins(fontSize: 12))
                        : null,
                    trailing: _deliveryType == 'Dine In' && localNomorMeja != null && localNomorMeja!.isNotEmpty
                        ? const Icon(Icons.check_circle, color: Color(0xFFD33400))
                        : null,
                    onTap: () async {
                      final nomor = await _showTableNumberDialog(localNomorMeja);
                      if (nomor != null && nomor.isNotEmpty) {
                        setModalState(() {
                          localNomorMeja = nomor;
                        });
                        setState(() {
                          _deliveryType = 'Dine In';
                          _nomorMeja = nomor;
                        });
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.shopping_bag_outlined, color: Color(0xFFD33400)),
                    title: Text(
                      'Takeaway',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    trailing: _deliveryType == 'Take Away'
                        ? const Icon(Icons.check_circle, color: Color(0xFFD33400))
                        : null,
                    onTap: () {
                      setState(() {
                        _deliveryType = 'Take Away';
                        _nomorMeja = null;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
    final double finalTotal = (totalPrice - discount) + ppn + biayaLain;

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delivery Type
            GestureDetector(
              onTap: _showDeliveryTypeBottomSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _deliveryType == 'Dine In'
                                ? Icons.restaurant
                                : Icons.shopping_bag_outlined,
                            color: const Color(0xFFD33400),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _deliveryType == 'Dine In'
                              ? (_nomorMeja != null && _nomorMeja!.isNotEmpty
                                  ? 'Dine In (Meja $_nomorMeja)'
                                  : 'Dine In')
                              : 'Takeaway',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFD33400)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Ganti',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFD33400),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                    'Jl. Setia Budi No.28, Ngesrep, Kec. Banyumanik, Kota Semarang, Jawa Tengah 50262',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFD33400)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.directions, color: Color(0xFFD33400), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Rute',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFD33400),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
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
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PaymentMethodPage(
                                            cartItems: widget.cartItems,
                                            totalPrice: finalTotal,
                                            restoId: widget.restoId,
                                            appliedPromo: _selectedPromo,
                                            discount: discount,
                                            subtotal: totalPrice,
                                            type: _deliveryType,
                                            tableOrPickupInfo: _deliveryType == 'Dine In'
                                                ? 'Meja ${_nomorMeja ?? "-"}'
                                                : 'Take Away',
                                          ),
                                        ),
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
