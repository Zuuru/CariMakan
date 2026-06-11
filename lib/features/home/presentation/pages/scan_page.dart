import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carimakan/core/widgets/custom_back_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'resto_page.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  Barcode? barcode;
  bool isScanning = true;

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not launch URL')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Scan Barcode',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: Center(child: CustomBackButton()),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) async {
              if (!isScanning) return;

              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final String? code = barcode.rawValue;
                if (code != null) {
                  setState(() => isScanning = false);
                  debugPrint('Barcode found! $code');

                  // Deteksi apakah ini QR Meja CariMakan (mengandung restoId dan tableId)
                  bool isTableQR =
                      code.contains('restoId=') && code.contains('tableId=');

                  if (isTableQR) {
                    // Tampilkan loading dialog
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFED001E),
                        ),
                      ),
                    );

                    try {
                      final uri = Uri.parse(code);
                      final restoId = uri.queryParameters['restoId'];
                      final tableId = uri.queryParameters['tableId'];

                      if (restoId != null && tableId != null) {
                        // Ambil detail resto dari Firestore
                        final restoDoc = await FirebaseFirestore.instance
                            .collection('restaurants')
                            .doc(restoId)
                            .get();

                        if (restoDoc.exists && mounted) {
                          final data = restoDoc.data()!;
                          final name = data['nama'] ?? data['name'] ?? 'Resto';
                          final imageUrl =
                              data['gambar'] ??
                              data['imageUrl'] ??
                              'assets/images/placeholder.jpg';

                          // Ambil detail nomor meja
                          String nomorMeja = '';
                          final tableDoc = await FirebaseFirestore.instance
                              .collection('restaurants')
                              .doc(restoId)
                              .collection('tables')
                              .doc(tableId)
                              .get();

                          if (tableDoc.exists) {
                            nomorMeja = tableDoc.data()?['nomor_meja'] ?? '';
                          }

                          if (!mounted) return;

                          // Pop loading dialog
                          Navigator.pop(context);

                          // Redirect langsung ke RestoPage dengan info meja terkunci
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RestoPage(
                                name: name,
                                imageUrl: imageUrl,
                                distance: '0.1 km',
                                queueCount: data['queueCount'] ?? 0,
                                tableId: tableId,
                                nomorMeja: nomorMeja,
                              ),
                            ),
                          );
                          return;
                        }
                      }
                    } catch (e) {
                      debugPrint('Error parsing table QR: $e');
                    }

                    // Jika gagal memuat, pop loading dan biarkan mengalir ke launcher default
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  }

                  // Default Fallback
                  if (code.startsWith('http')) {
                    await _launchURL(code);
                  } else {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Scanned: $code')));
                  }

                  if (mounted) Navigator.pop(context);
                  break;
                }
              }
            },
          ),
          // Overlay to show the scan area
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Arahkan kamera ke barcode',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  backgroundColor: Colors.black54,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
