import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TrackerTakeawayPage extends StatefulWidget {
  const TrackerTakeawayPage({Key? key}) : super(key: key);

  @override
  State<TrackerTakeawayPage> createState() => _TrackerTakeawayPageState();
}

class _TrackerTakeawayPageState extends State<TrackerTakeawayPage> {
  // Mock current step (0 = pending, 1 = preparing, 2 = ready)
  int currentStep = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // Red Cloche Image placeholder
          Expanded(
            flex: 2,
            child: Center(
              child: Image.asset(
                'assets/images/icon_pesanan/takeaway_cover.png',
                errorBuilder: (context, error, stackTrace) {
                  return Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      const Icon(
                        Icons.room_service,
                        size: 200,
                        color: Color(0xFFED001E),
                      ),
                      Positioned(
                        top: 40,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFED001E), width: 2),
                          ),
                          child: const Icon(
                            Icons.access_time,
                            color: Color(0xFFED001E),
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  );
                },
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
      leading: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black,
              size: 16,
            ),
          ),
        ),
      ),
      title: Column(
        children: [
          Text(
            'Ideologist Coffee And',
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Social Space',
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
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
            child: Image.asset(
              'assets/images/menu/kopi_susu.jpg', // Replace with actual image
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
                  'Pesananlu lagi disiapin nih',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Order at 19.00',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '1x Butterscotch Sea Salt',
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
                color: isActive ? const Color(0xFFED001E) : Colors.grey[400],
              ),
            if (isFirst) const SizedBox(height: 25), // Padding for alignment
            
            // Step Indicator
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted 
                    ? const Color(0xFFED001E)
                    : (isActive ? Colors.white : Colors.grey[400]),
                border: isActive && !isCompleted 
                    ? Border.all(color: const Color(0xFFED001E), width: 4)
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
                              color: Color(0xFFED001E),
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
                color: isCompleted ? const Color(0xFFED001E) : Colors.grey[400],
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
              color: Color(0xFFED001E),
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFED001E), width: 1.5),
            ),
            child: const Icon(
              Icons.chat_bubble,
              color: Color(0xFFED001E),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
