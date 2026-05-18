import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'status_pendaftaran_page.dart';

class LokasiOperasionalPage extends StatefulWidget {
  const LokasiOperasionalPage({Key? key}) : super(key: key);

  @override
  State<LokasiOperasionalPage> createState() => _LokasiOperasionalPageState();
}

class _LokasiOperasionalPageState extends State<LokasiOperasionalPage> {
  // State for days
  final List<Map<String, dynamic>> _operasionalDays = [
    {'day': 'Senin', 'isOpen': true, 'openTime': const TimeOfDay(hour: 8, minute: 0), 'closeTime': const TimeOfDay(hour: 22, minute: 0)},
    {'day': 'Selasa', 'isOpen': true, 'openTime': const TimeOfDay(hour: 8, minute: 0), 'closeTime': const TimeOfDay(hour: 22, minute: 0)},
    {'day': 'Rabu', 'isOpen': true, 'openTime': const TimeOfDay(hour: 8, minute: 0), 'closeTime': const TimeOfDay(hour: 22, minute: 0)},
    {'day': 'Kamis', 'isOpen': true, 'openTime': const TimeOfDay(hour: 8, minute: 0), 'closeTime': const TimeOfDay(hour: 22, minute: 0)},
    {'day': 'Jumat', 'isOpen': true, 'openTime': const TimeOfDay(hour: 8, minute: 0), 'closeTime': const TimeOfDay(hour: 22, minute: 0)},
    {'day': 'Sabtu', 'isOpen': true, 'openTime': const TimeOfDay(hour: 8, minute: 0), 'closeTime': const TimeOfDay(hour: 22, minute: 0)},
    {'day': 'Minggu', 'isOpen': true, 'openTime': const TimeOfDay(hour: 8, minute: 0), 'closeTime': const TimeOfDay(hour: 22, minute: 0)},
  ];

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}.$minute $period';
  }

  Future<void> _selectTime(BuildContext context, int index, bool isOpenTime) async {
    final Map<String, dynamic> dayData = _operasionalDays[index];
    if (!dayData['isOpen']) return; // Don't pick time if closed

    final TimeOfDay initialTime = isOpenTime ? dayData['openTime'] : dayData['closeTime'];
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFC21111), // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Colors.black, // body text color
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != initialTime) {
      setState(() {
        if (isOpenTime) {
          _operasionalDays[index]['openTime'] = picked;
        } else {
          _operasionalDays[index]['closeTime'] = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Pattern
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
                        _buildLokasiCard(),
                        const SizedBox(height: 16),
                        _buildOperasionalCard(),
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
                          // Handle Submit
                          // Navigate to Status Page
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StatusPendaftaranPage(
                                initialStatus: RegistrationStatus.pending,
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
                          'Kirim',
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
              'Lokasi & Operasional',
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

  Widget _buildLokasiCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lokasi Resto',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          
          // Map Placeholder
          Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFF1F1F1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/background/map_placeholder.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.map, size: 50, color: Colors.grey),
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Detail Alamat Title
          Text(
            'Detail Alamat',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFB65353),
            ),
          ),
          const SizedBox(height: 8),
          
          // Detail Alamat Input
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1F1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFEF96A1).withOpacity(0.5),
                width: 1,
              ),
            ),
            child: TextField(
              maxLines: 3,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              decoration: InputDecoration(
                hintText: 'Jl.Semarang aja',
                hintStyle: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperasionalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Waktu Operasional',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          
          // Days List
          ...List.generate(_operasionalDays.length, (index) {
            return _buildDayRow(index);
          }),
        ],
      ),
    );
  }

  Widget _buildDayRow(int index) {
    final Map<String, dynamic> dayData = _operasionalDays[index];
    final bool isOpen = dayData['isOpen'];
    final String dayName = dayData['day'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          // Custom Radio / Toggle
          GestureDetector(
            onTap: () {
              setState(() {
                _operasionalDays[index]['isOpen'] = !isOpen;
              });
            },
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOpen ? Colors.transparent : const Color(0xFFD9D9D9),
                border: Border.all(
                  color: isOpen ? const Color(0xFFC21111) : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isOpen
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFC21111),
                        ),
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          
          // Day Name
          SizedBox(
            width: 65,
            child: Text(
              dayName,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isOpen ? Colors.black : Colors.grey,
              ),
            ),
          ),
          
          const Spacer(),
          
          // Open Time
          GestureDetector(
            onTap: () => _selectTime(context, index, true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isOpen ? Colors.white : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isOpen ? const Color(0xFFEB5E5E) : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Text(
                _formatTime(dayData['openTime']),
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isOpen ? Colors.black : Colors.grey,
                ),
              ),
            ),
          ),
          
          // Separator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              '-',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isOpen ? Colors.black : Colors.grey,
              ),
            ),
          ),
          
          // Close Time
          GestureDetector(
            onTap: () => _selectTime(context, index, false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isOpen ? Colors.white : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isOpen ? const Color(0xFFEB5E5E) : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Text(
                _formatTime(dayData['closeTime']),
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isOpen ? Colors.black : Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
