import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carimakan/core/widgets/custom_back_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class TrackerDineInPage extends StatefulWidget {
  final String? orderId;
  const TrackerDineInPage({Key? key, this.orderId}) : super(key: key);

  @override
  State<TrackerDineInPage> createState() => _TrackerDineInPageState();
}

class _TrackerDineInPageState extends State<TrackerDineInPage> {
  int currentStep = 3;
  String _restoName = 'Loading resto...';
  String _itemName = '';
  String _orderTime = '';
  String _queueNumber = '';
  Map<String, dynamic>? _orderData;
  Timer? _autoCompleteTimer;

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  void _checkAutoComplete(Map<String, dynamic> data) {
    final statusRaw = data['status'] ?? 'paid';
    if (statusRaw == 'Siap') {
      final Timestamp? readyAt = data['readyAt'] as Timestamp?;
      if (readyAt != null) {
        final readyDateTime = readyAt.toDate().toLocal();
        final now = DateTime.now();
        final diff = now.difference(readyDateTime);
        
        if (diff.inMinutes >= 10) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _completeOrderSilently();
          });
        } else {
          final remainingSeconds = 600 - diff.inSeconds;
          _startAutoCompleteTimer(remainingSeconds);
        }
      }
    } else {
      _cancelTimer();
    }
  }

  void _completeOrderSilently() {
    FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .update({'status': 'Selesai'}).catchError((e) {
      // ignore
    });
  }

  void _startAutoCompleteTimer(int seconds) {
    _cancelTimer();
    if (seconds <= 0) return;
    _autoCompleteTimer = Timer(Duration(seconds: seconds), () {
      _completeOrderSilently();
    });
  }

  void _cancelTimer() {
    _autoCompleteTimer?.cancel();
    _autoCompleteTimer = null;
  }

  Future<void> _completeOrder() async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({'status': 'Selesai'});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pesanan selesai! Terima kasih.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menyelesaikan pesanan: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    if (widget.orderId == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: const CustomBackButton(),
        ),
        body: const Center(
          child: Text('Invalid Order ID', style: TextStyle(color: Colors.black)),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').doc(widget.orderId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFFD33400))),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('Pesanan tidak ditemukan')),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        _orderData = data;
        _checkAutoComplete(data);
        
        final statusRaw = data['status'] ?? 'paid';
        if (statusRaw == 'Diproses') {
          currentStep = 1;
        } else if (statusRaw == 'Siap') {
          currentStep = 2;
        } else if (statusRaw == 'Selesai') {
          currentStep = 3;
        } else {
          currentStep = 0; // paid / pending
        }

        _itemName = data['menuName'] ?? '';
        _queueNumber = data['queueNumber']?.toString().replaceAll('#', '') ?? '';
        final Timestamp? ts = data['orderDate'] as Timestamp?;
        if (ts != null) {
          _orderTime = DateFormat('HH.mm').format(ts.toDate().toLocal());
        } else {
          _orderTime = '';
        }

        final restoId = data['resto_id'] ?? '';

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('restaurants').doc(restoId).get(),
          builder: (context, restoSnapshot) {
            if (restoSnapshot.hasData && restoSnapshot.data!.exists) {
              final restoData = restoSnapshot.data!.data() as Map<String, dynamic>;
              _restoName = restoData['nama'] ?? restoData['name'] ?? 'Resto';
            } else {
              _restoName = 'Loading Resto...';
            }
            return _buildMainLayout();
          },
        );
      },
    );
  }

  Widget _buildMainLayout() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // Red Cloche Image placeholder
          Expanded(
            flex: 2,
            child: Center(
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  const Icon(
                    Icons.room_service,
                    size: 200,
                    color: Color(0xFFD33400),
                  ),
                  Positioned(
                    top: 40,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFD33400), width: 2),
                      ),
                      child: const Icon(
                        Icons.access_time,
                        color: Color(0xFFD33400),
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Details Section
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0F0), // Light pink background
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    _buildOrderSummaryCard(),
                    const SizedBox(height: 32),
                    _buildTrackerTimeline(),
                    const SizedBox(height: 32),
                    _buildQueueNumberCard(),
                    if (currentStep == 2) ...[
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _completeOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD33400),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'Pesanan Sudah Diambil',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leadingWidth: 72,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: const Center(child: CustomBackButton()),
      ),
      title: Text(
        _restoName,
        style: GoogleFonts.poppins(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 2,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    String summaryTitle = 'Pesananlu lagi disiapin nih';
    if (currentStep == 0) {
      summaryTitle = 'Nunggu acc dari resto';
    } else if (currentStep == 2) {
      summaryTitle = 'Makananlu dah jadi nih, buruan ambil';
    } else if (currentStep >= 3) {
      summaryTitle = 'Pesananlu udah selesai';
    }

    // Try to get first item image if available
    String? menuImage;
    if (_orderData != null) {
      final items = _orderData!['items'] as List?;
      if (items != null && items.isNotEmpty) {
        menuImage = items.first['menuImage'] as String?;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: menuImage != null && menuImage.isNotEmpty
                ? (menuImage.startsWith('http')
                    ? Image.network(
                        menuImage,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 70,
                          height: 70,
                          color: Colors.grey[300],
                          child: const Icon(Icons.fastfood, color: Colors.grey),
                        ),
                      )
                    : Image.asset(
                        menuImage,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 70,
                          height: 70,
                          color: Colors.grey[300],
                          child: const Icon(Icons.fastfood, color: Colors.grey),
                        ),
                      ))
                : Image.asset(
                    'assets/images/menu/makanan/Chicken Cordon Bleu.jpg', // Default fallback
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey[300],
                        child: const Icon(Icons.fastfood, color: Colors.grey),
                      );
                    },
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summaryTitle,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (_orderTime.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Order at $_orderTime',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  _itemName,
                  style: GoogleFonts.poppins(
                    color: Colors.black87,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackerTimeline() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          _buildTimelineStep(
            title: 'Nunggu acc dari resto',
            isActive: currentStep >= 0,
            isCompleted: currentStep > 0,
            isFirst: true,
          ),
          _buildTimelineStep(
            title: 'Resto lagi bikinin makanan lu',
            isActive: currentStep >= 1,
            isCompleted: currentStep > 1,
          ),
          _buildTimelineStep(
            title: 'Makananlu dah jadi nih, buruan ambil',
            isActive: currentStep >= 2,
            isCompleted: currentStep > 2,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required bool isActive,
    required bool isCompleted,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            // Top connecting line
            if (!isFirst)
              Container(
                width: 2,
                height: 25,
                color: isActive ? const Color(0xFFD33400) : Colors.grey[400],
              ),
            if (isFirst) const SizedBox(height: 25), // Padding for alignment
            
            // Step Indicator
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted 
                    ? const Color(0xFFD33400)
                    : (isActive ? Colors.white : Colors.grey[400]),
                border: isActive && !isCompleted 
                    ? Border.all(color: const Color(0xFFD33400), width: 4)
                    : null,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : (isActive && !isCompleted 
                      ? Center(
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD33400),
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null),
            ),
            
            // Bottom connecting line
            if (!isLast)
              Container(
                width: 2,
                height: 25,
                color: isCompleted ? const Color(0xFFD33400) : Colors.grey[400],
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Step Title
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 25.0),
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
                color: isActive ? Colors.black : Colors.grey[600],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQueueNumberCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Nomor Antrean',
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _queueNumber.isNotEmpty ? _queueNumber : '-',
            style: GoogleFonts.poppins(
              color: const Color(0xFFD33400),
              fontSize: 48,
              fontWeight: FontWeight.bold,
              height: 1, // Minimize line height padding
            ),
          ),
        ],
      ),
    );
  }
}
