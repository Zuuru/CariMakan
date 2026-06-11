import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carimakan/core/widgets/custom_back_button.dart';

class TrackerDineInPage extends StatefulWidget {
  const TrackerDineInPage({Key? key}) : super(key: key);

  @override
  State<TrackerDineInPage> createState() => _TrackerDineInPageState();
}

class _TrackerDineInPageState extends State<TrackerDineInPage> {
  // Mock current step (0 = pending, 1 = preparing, 2 = ready, 3 = completed)
  int currentStep = 3;

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
              'assets/images/menu/makanan/Chicken Cordon Bleu.jpg', // Replace with actual image
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
                  'Pesananlu udah selesai nih',
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
            '67',
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
