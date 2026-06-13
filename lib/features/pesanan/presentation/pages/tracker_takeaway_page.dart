import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carimakan/core/widgets/custom_back_button.dart';
import 'chat_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../widgets/review_bottom_sheet.dart';

class TrackerTakeawayPage extends StatefulWidget {
  final String? orderId;
  const TrackerTakeawayPage({Key? key, this.orderId}) : super(key: key);

  @override
  State<TrackerTakeawayPage> createState() => _TrackerTakeawayPageState();
}

class _TrackerTakeawayPageState extends State<TrackerTakeawayPage> {
  int currentStep = 1;
  String _restoName = 'Loading resto...';
  String _itemName = '';
  String _orderTime = '';
  bool _isLoading = true;
  Map<String, dynamic>? _orderData;
  bool _sudahDireview = false;


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
        _sudahDireview = data['sudah_direview'] == true;
        
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
                    if (currentStep >= 2 && currentStep < 4) ...[
                      const SizedBox(height: 32),
                      _buildPickupQrCard(),
                    ],
                    if (currentStep >= 3) ...[
                      const SizedBox(height: 32),
                      _buildReviewSection(),
                    ],
                    const SizedBox(height: 32),
                    _buildRestoContactCard(),
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

  Widget _buildPickupQrCard() {
    final orderId = widget.orderId ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFD33400).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFD33400).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.qr_code_2_rounded,
                  color: Color(0xFFD33400),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QR Pickup Kamu',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1C1C1C),
                    ),
                  ),
                  Text(
                    'Tunjukkan ke karyawan untuk ambil pesanan',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFF3F4F6),
                width: 1.5,
              ),
            ),
            child: QrImageView(
              data: orderId,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF1C1C1C),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF1C1C1C),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Order ID display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Order ID: ${orderId.length > 12 ? orderId.substring(0, 12).toUpperCase() + '...' : orderId.toUpperCase()}',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Info chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: Color(0xFFD33400),
                ),
                const SizedBox(width: 6),
                Text(
                  'Makanan kamu sudah siap diambil!',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFD33400),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestoContactCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
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
          CircleAvatar(
            radius: 20,
            backgroundImage: const AssetImage('assets/images/profile.png'),
            backgroundColor: Colors.grey[200],
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SOXZY',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Text(
                'Resto',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Call Button
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFD33400),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.phone,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Chat Button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChatPage(
                    restoName: 'SOXZY luv cedar',
                    restoImage: 'assets/images/profile.png',
                  ),
                ),
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD33400), width: 1.5),
              ),
              child: const Icon(
                Icons.chat_bubble,
                color: Color(0xFFD33400),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection() {
    final orderId = widget.orderId ?? '';
    final restoId = _orderData?['resto_id'] ?? '';
    final orderSummary = '${_itemName.isNotEmpty ? _itemName : 'Pesanan'} · $_orderTime';

    if (_sudahDireview) {
      return GestureDetector(
        onTap: () {
          ReviewBottomSheet.show(
            context,
            orderId: orderId,
            restoId: restoId,
            restoName: _restoName,
            orderSummary: orderSummary,
            existingReview: _orderData,
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ulasan sudah dikirim ✅',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    Row(
                      children: List.generate(5, (i) {
                        final total = (_orderData?['rating_total'] as num?)?.toDouble() ?? 0;
                        return Icon(
                          i < total.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: Colors.amber,
                          size: 14,
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Text(
                'Lihat',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Color(0xFF10B981), size: 18),
            ],
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: () async {
        final result = await ReviewBottomSheet.show(
          context,
          orderId: orderId,
          restoId: restoId,
          restoName: _restoName,
          orderSummary: orderSummary,
        );
        if (result == true) {
          setState(() => _sudahDireview = true);
        }
      },
      icon: const Icon(Icons.star_rate_rounded, size: 20),
      label: Text(
        'Beri Ulasan',
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black87,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
      ),
    );
  }
}
