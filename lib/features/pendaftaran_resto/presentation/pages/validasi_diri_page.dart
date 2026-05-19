import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carimakan/core/theme/app_colors.dart';
import '../widgets/custom_registration_field.dart';
import 'profil_resto_page.dart';

class ValidasiDiriPage extends StatefulWidget {
  const ValidasiDiriPage({super.key});

  @override
  State<ValidasiDiriPage> createState() => _ValidasiDiriPageState();
}

class _ValidasiDiriPageState extends State<ValidasiDiriPage> {
  final TextEditingController _namaPemilikController = TextEditingController();
  final TextEditingController _nomorHpController = TextEditingController();
  final TextEditingController _namaKtpController = TextEditingController();
  final TextEditingController _nikController = TextEditingController();

  @override
  void dispose() {
    _namaPemilikController.dispose();
    _nomorHpController.dispose();
    _namaKtpController.dispose();
    _nikController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/background/bg 2.png',
              fit: BoxFit.cover,
            ),
          ),
          
          SafeArea(
            child: Stack(
              children: [
                // Scrollable Content
                Positioned(
                  top: 74, // Starts strictly below the App Bar
                  left: 0,
                  right: 0,
                  bottom: 0, // Goes all the way to the bottom under the button
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 10,
                      bottom: 100, // Space for the fixed bottom button
                    ),
                    child: Column(
                      children: [
                        _buildFormCard(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                
                // Fixed App Bar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.transparent,
                    child: _buildAppBar(context),
                  ),
                ),
                
                // Fixed Bottom Button with fade gradient background
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 16,
                      bottom: 24,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_namaPemilikController.text.isEmpty ||
                              _nomorHpController.text.isEmpty ||
                              _namaKtpController.text.isEmpty ||
                              _nikController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Harap isi semua data diri!')),
                            );
                            return;
                          }

                          final registrationData = {
                            'owner_name': _namaPemilikController.text.trim(),
                            'owner_phone': _nomorHpController.text.trim(),
                            'ktp_name': _namaKtpController.text.trim(),
                            'ktp_nik': _nikController.text.trim(),
                          };

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfilRestoPage(
                                registrationData: registrationData,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC21111),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Selanjutnya',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF99BDD5).withOpacity(0.5), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: const Color(0xFF99BDD5).withOpacity(0.5), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              'Daftarkan Restomu',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 44), // To balance the row
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Dirimu',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          
          CustomRegistrationField(
            label: 'Nama Pemilik',
            hintText: 'Masukkan nama pemilik',
            controller: _namaPemilikController,
          ),
          const SizedBox(height: 16),
          
          CustomRegistrationField(
            label: 'Nomor HP',
            hintText: 'Masukkan nomor HP',
            controller: _nomorHpController,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          
          Text(
            'Foto KTP',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFC21111),
            ),
          ),
          const SizedBox(height: 4),
          
          // Bagian KTP (Nama, NIK, Upload Foto)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F1F1),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: const Color(0xFFC21111).withOpacity(0.5), width: 1),
                      ),
                      child: TextFormField(
                        controller: _namaKtpController,
                        style: GoogleFonts.outfit(fontSize: 14, color: Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Nama KTP',
                          hintStyle: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F1F1),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: const Color(0xFFC21111).withOpacity(0.5), width: 1),
                      ),
                      child: TextFormField(
                        controller: _nikController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.outfit(fontSize: 14, color: Colors.black),
                        decoration: InputDecoration(
                          hintText: 'NIK KTP',
                          hintStyle: GoogleFonts.outfit(fontSize: 14, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () {
                    // TODO: Implement image picker
                  },
                  child: Container(
                    height: 106, // Menyesuaikan tinggi 2 textfield + spacer
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F1F1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFC21111), width: 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_a_photo, color: Color(0xFFC21111), size: 28),
                        const SizedBox(height: 8),
                        Text(
                          'Upload Foto',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFC21111),
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
    );
  }
}
