import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carimakan/core/theme/app_colors.dart';

class IconMakanan extends StatefulWidget {
  const IconMakanan({super.key});

  @override
  State<IconMakanan> createState() => _IconMakananState();
}

class _IconMakananState extends State<IconMakanan> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> categories = [
    {'name': 'Aneka Nasi', 'image': 'assets/images/icon_makanan/aneka nasi.png'},
    {'name': 'Sate', 'image': 'assets/images/icon_makanan/sate.png'},
    {'name': 'Geprek', 'image': 'assets/images/icon_makanan/geprek.png'},
    {'name': 'Bakso', 'image': 'assets/images/icon_makanan/bakso.png'},
    {'name': 'Pizza', 'image': 'assets/images/icon_makanan/pizza.png'},
    {'name': 'Cepat Saji', 'image': 'assets/images/icon_makanan/Cepat saji.png'},
    {'name': 'Dessert', 'image': 'assets/images/icon_makanan/dessert.png'},
    {'name': 'Minuman', 'image': 'assets/images/icon_makanan/minuman.png'},
    {'name': 'Ayam', 'image': 'assets/images/icon_makanan/ayam.png'},
    {'name': 'Bakmi', 'image': 'assets/images/icon_makanan/bakmi.png'},
    {'name': 'Bubur', 'image': 'assets/images/icon_makanan/bubur.png'},
    {'name': 'Jajanan', 'image': 'assets/images/icon_makanan/jajanan.png'},
    {'name': 'Jepang', 'image': 'assets/images/icon_makanan/jepang.png'},
    {'name': 'Kopi', 'image': 'assets/images/icon_makanan/kopi.png'},
    {'name': 'Korea', 'image': 'assets/images/icon_makanan/korea.png'},
    {'name': 'Seafood', 'image': 'assets/images/icon_makanan/seafood.png'},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kuliner favorit kamu nihh',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 250, // Sedikit ditambah agar lebih aman dari overflow
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: (categories.length / 8).ceil(),
            itemBuilder: (context, pageIndex) {
              final startIndex = pageIndex * 8;
              final endIndex = (startIndex + 8) > categories.length 
                  ? categories.length 
                  : startIndex + 8;
              final pageItems = categories.sublist(startIndex, endIndex);

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 0,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.65,
                ),
                itemCount: pageItems.length,
                itemBuilder: (context, index) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 75,
                        width: 75,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            pageItems[index]['image']!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.fastfood, color: Colors.grey),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pageItems[index]['name']!,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMain,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            (categories.length / 8).ceil(),
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _currentPage == index 
                    ? AppColors.primary 
                    : Colors.grey[300],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
