import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carimakan/features/order/checkout_page.dart';

// 1. Variabel global diletakkan di sini
final ValueNotifier<int> globalCartQuantity = ValueNotifier<int>(1);
final ValueNotifier<int> globalSubtotal = ValueNotifier<int>(0);
CartSummaryBar? globalCart;

class CartSummaryBar extends StatelessWidget {
  final String name;
  final String price;
  final String imagePath;
  final String sugar;
  final String ice;
  final List<String> addOns;

  const CartSummaryBar({
    super.key,
    required this.name,
    required this.price,
    required this.imagePath,
    required this.sugar,
    required this.ice,
    required this.addOns,
  });

  @override
  Widget build(BuildContext context) {
    // 2. Bungkus dengan ValueListenableBuilder
    return ValueListenableBuilder<int>(
      valueListenable: globalCartQuantity,
      builder: (context, quantity, child) {
        // JIKA KUANTITAS 0, SEMBUNYIKAN WIDGET SECARA KESELURUHAN
        if (quantity <= 0) {
          return const SizedBox.shrink(); 
        }

        // JIKA LEBIH DARI 0, TAMPILKAN CARD SEPERTI BIASA
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PembayaranPage(
                      name: name,
                      price: price,
                      imagePath: imagePath,
                      sugar: sugar,
                      ice: ice,
                      addOns: addOns.isEmpty ? ['Tidak ada'] : addOns,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFD33400),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$quantity item', // Teks ini sekarang dinamis mengikuti variabel global
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          price,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.shopping_cart, color: Colors.white, size: 22),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}