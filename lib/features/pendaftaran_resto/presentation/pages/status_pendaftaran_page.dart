import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../features/home_resto/presentation/pages/home_resto_page.dart';

enum RegistrationStatus { pending, approved, rejected }

class StatusPendaftaranPage extends StatefulWidget {
  final RegistrationStatus initialStatus;

  const StatusPendaftaranPage({
    Key? key,
    this.initialStatus = RegistrationStatus.pending,
  }) : super(key: key);

  @override
  State<StatusPendaftaranPage> createState() => _StatusPendaftaranPageState();
}

class _StatusPendaftaranPageState extends State<StatusPendaftaranPage> {
  late RegistrationStatus _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.initialStatus;
  }

  // --- Helpers for Status Content ---

  String get _imagePath {
    switch (_currentStatus) {
      case RegistrationStatus.pending:
        return 'assets/images/status/pending.png';
      case RegistrationStatus.approved:
        return 'assets/images/status/approved.png';
      case RegistrationStatus.rejected:
        return 'assets/images/status/rejected.png';
    }
  }

  String get _title {
    switch (_currentStatus) {
      case RegistrationStatus.pending:
        return 'Menunggu Konfirmasi';
      case RegistrationStatus.approved:
        return 'Pendaftaran Berhasil!';
      case RegistrationStatus.rejected:
        return 'Pendaftaran Ditolak';
    }
  }

  String get _description {
    switch (_currentStatus) {
      case RegistrationStatus.pending:
        return 'Data restoran Anda sedang dalam proses peninjauan oleh admin. Mohon tunggu maksimal 2x24 jam untuk mendapatkan informasi lebih lanjut.';
      case RegistrationStatus.approved:
        return 'Selamat! Restoran Anda telah disetujui oleh admin dan kini berstatus aktif. Anda dapat mulai mengatur menu Anda sekarang.';
      case RegistrationStatus.rejected:
        return 'Mohon maaf, data pendaftaran restoran Anda tidak memenuhi kriteria kami saat ini. Silakan periksa kembali kelengkapan data Anda.';
    }
  }

  String get _buttonText {
    switch (_currentStatus) {
      case RegistrationStatus.pending:
        return 'Kembali ke Beranda';
      case RegistrationStatus.approved:
        return 'Masuk ke Dashboard Resto';
      case RegistrationStatus.rejected:
        return 'Ajukan Ulang Data';
    }
  }

  Color get _titleColor {
    switch (_currentStatus) {
      case RegistrationStatus.pending:
        return const Color(0xFFC21111); // Red theme
      case RegistrationStatus.approved:
        return const Color(0xFF4CAF50); // Green theme
      case RegistrationStatus.rejected:
        return const Color(0xFFD32F2F); // Dark Red theme
    }
  }

  // --- Secret Developer Action to toggle state for presentation ---
  void _cycleStatus() {
    setState(() {
      if (_currentStatus == RegistrationStatus.pending) {
        _currentStatus = RegistrationStatus.approved;
      } else if (_currentStatus == RegistrationStatus.approved) {
        _currentStatus = RegistrationStatus.rejected;
      } else {
        _currentStatus = RegistrationStatus.pending;
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Testing Mode: Berubah ke status ${_currentStatus.name}'),
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
              
              // Secret Tap on Image to cycle state
              GestureDetector(
                onDoubleTap: _cycleStatus,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child));
                  },
                  child: Image.asset(
                    _imagePath,
                    key: ValueKey<RegistrationStatus>(_currentStatus),
                    height: 250,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Title
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _title,
                  key: ValueKey<String>(_title),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: _titleColor,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Description
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _description,
                  key: ValueKey<String>(_description),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Bottom Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentStatus == RegistrationStatus.approved) {
                      Navigator.pushReplacement(
                        context, 
                        MaterialPageRoute(builder: (_) => const HomeRestoPage())
                      );
                    } else if (_currentStatus == RegistrationStatus.pending) {
                      // Back to root
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    } else if (_currentStatus == RegistrationStatus.rejected) {
                      // Pop back to edit
                      Navigator.pop(context);
                    }
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
                    _buttonText,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
      Positioned(
        top: 20,
        right: 20,
        child: SafeArea(
          child: IconButton(
            icon: const Icon(Icons.fast_forward, color: Colors.grey),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeRestoPage()),
              );
            },
            tooltip: 'Bypass to Home',
          ),
        ),
      ),
    ],
  ),
);
  }
}
