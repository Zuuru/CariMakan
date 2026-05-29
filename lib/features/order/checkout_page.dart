import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  // Fungsi pembantu untuk mengubah format rupiah string menjadi integer murni untuk kalkulasi matematika
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

  @override
  Widget build(BuildContext context) {
    // Perhitungan kalkulasi nota belanja secara dinamis
    int hargaSatuan = _parsePrice(widget.price);
    int totalHargaItem = hargaSatuan * _itemQuantity;
    int ppn = (totalHargaItem * 0.1).toInt(); // PPN 10%
    int biayaLainnya = 1000; // Sesuai figma kamu
    int totalSemua = totalHargaItem + ppn + biayaLainnya;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pembayaran',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
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
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.shopping_bag_outlined, color: Color(0xFFE30613), size: 35),
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
                      side: const BorderSide(color: Color(0xFFE30613)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    ),
                    child: Text('Ganti', style: GoogleFonts.poppins(color: const Color(0xFFE30613), fontSize: 12, fontWeight: FontWeight.bold)),
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
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE30613),
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

            // 3. Card Detail Pesanan Merah
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE30613),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Detail Kustomisasi Data Produk
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
                        // Tombol Edit
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            minimumSize: const Size(60, 25),
                          ),
                          child: Text('Edit', style: GoogleFonts.poppins(color: const Color(0xFFE30613), fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  // Gambar & Counter Item
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.asset(
                          widget.imagePath,
                          width: 85,
                          height: 85,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Counter Jumlah Item Kanan Atas
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
                                if (_itemQuantity > 1) {
                                  setState(() => _itemQuantity--);
                                }
                              },
                              child: const Icon(Icons.remove, size: 16, color: Color(0xFFE30613)),
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
                              child: const Icon(Icons.add, size: 16, color: Color(0xFFE30613)),
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

            // 4. Tambah Menu Lain Banner
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mau nambah yang lain?',
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
                ),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE30613)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  ),
                  child: Text('Tambah', style: GoogleFonts.poppins(color: const Color(0xFFE30613), fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
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
                color: const Color(0xFFE30613),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _buildNotaRow('Harga', _formatRupiah(totalHargaItem)),
                  const SizedBox(height: 8),
                  _buildNotaRow('PPN', _formatRupiah(ppn)),
                  const SizedBox(height: 8),
                  _buildNotaRow('Biaya lainnya', _formatRupiah(biayaLainnya)),
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
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 6. Tombol Utama Gass Bayarr!!
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // MEMANGGIL FUNGSI DIALOG KONFIRMASI KETIKA DIKLIK
                  _showKonfirmasiDialog(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE30613),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Gass Bayarr!!',
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Fungsi untuk menampilkan Custom Dialog Pop-Up Konfirmasi
  void _showKonfirmasiDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // User wajib pilih salah satu tombol
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0), // Sudut melengkung halus
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Menyesuaikan tinggi dengan konten
              children: [
                Text(
                  'Kamu udah yakin ama\npesenan kamu?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Karakter Ilustrasi (SUDAH DIPERBAIKI MENJADI BoxFit.contain)
                Image.asset(
                  'assets/images/character_confirm/character_confirm.jpg', 
                  height: 180,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),
                
                // Baris Tombol Aksi
                Row(
                  children: [
                    // Tombol Ntar
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context); // Menutup dialog dan kembali ke halaman pembayaran
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE30613), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Ntar',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFE30613),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Tombol Iyaa
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Tutup dialog konfirmasi dulu
                          
                          // TODO: Arahkan ke halaman pembayaran sukses / e-wallet milik timmu
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE30613),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: Text(
                          'Iyaa',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
  }

  // Fungsi pembantu baris list rincian nota
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