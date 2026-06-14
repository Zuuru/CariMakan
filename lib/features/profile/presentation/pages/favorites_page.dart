import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_back_button.dart';
import '../../../../core/widgets/favorite_service.dart';
import '../../../home/presentation/widgets/card_resto.dart';
import '../../../home/presentation/pages/resto_page.dart';
import '../../../../core/widgets/favorite_button.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 72,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: Center(child: CustomBackButton()),
        ),
        title: Text(
          'Favorites',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Resto'),
            Tab(text: 'Menu'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRestoFavorites(),
          _buildMenuFavorites(),
        ],
      ),
    );
  }

  Widget _buildRestoFavorites() {
    return ListenableBuilder(
      listenable: FavoriteService.instance,
      builder: (context, child) {
        final favIds = FavoriteService.instance.favoriteRestos.toList();
        if (favIds.isEmpty) {
          return Center(child: Text('Belum ada resto favorit', style: GoogleFonts.poppins(color: Colors.grey)));
        }

        return FutureBuilder<List<DocumentSnapshot>>(
          future: Future.wait(favIds.map((id) => FirebaseFirestore.instance.collection('restaurants').doc(id).get())),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
               return Center(child: Text('Belum ada resto favorit', style: GoogleFonts.poppins(color: Colors.grey)));
            }

            final validDocs = snapshot.data!.where((doc) => doc.exists).toList();

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: validDocs.length,
              itemBuilder: (context, index) {
                final doc = validDocs[index];
                final data = doc.data() as Map<String, dynamic>;
                return CardResto(
                  id: doc.id,
                  imageUrl: data['imageUrl'] ?? data['foto_profil'] ?? '',
                  name: data['nama'] ?? data['name'] ?? 'Unknown Resto',
                  distance: data['lokasi_alamat'] ?? data['distance'] ?? '-',
                  queueCount: data['queueCount'] ?? data['total_review'] ?? 0,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RestoPage(
                          name: data['nama'] ?? data['name'] ?? 'Unknown Resto',
                          imageUrl: data['imageUrl'] ?? data['foto_profil'] ?? '',
                          distance: data['lokasi_alamat'] ?? data['distance'] ?? '-',
                          queueCount: data['queueCount'] ?? data['total_review'] ?? 0,
                          restoId: doc.id,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMenuFavorites() {
    return ListenableBuilder(
      listenable: FavoriteService.instance,
      builder: (context, child) {
        final favIds = FavoriteService.instance.favoriteMenus.toList();
        if (favIds.isEmpty) {
          return Center(child: Text('Belum ada menu favorit', style: GoogleFonts.poppins(color: Colors.grey)));
        }

        return FutureBuilder<List<DocumentSnapshot>>(
          future: Future.wait(favIds.map((id) => FirebaseFirestore.instance.collection('menus').doc(id).get())),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
               return Center(child: Text('Belum ada menu favorit', style: GoogleFonts.poppins(color: Colors.grey)));
            }

            final validDocs = snapshot.data!.where((doc) => doc.exists).toList();

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: validDocs.length,
              itemBuilder: (context, index) {
                final doc = validDocs[index];
                final data = doc.data() as Map<String, dynamic>;
                
                final rawPrice = (data['harga'] ?? 0).toDouble();
                final String valStr = rawPrice.toInt().toString();
                final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
                final String formatted = valStr.replaceAllMapped(reg, (Match m) => '${m[1]}.');
                final priceStr = 'Rp $formatted';
                final imageUrl = data['image_url'] ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: imageUrl.isEmpty
                            ? Container(
                                height: 80,
                                width: 80,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.fastfood, color: Colors.grey),
                              )
                            : imageUrl.startsWith('http')
                                ? Image.network(
                                    imageUrl,
                                    height: 80,
                                    width: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) => Container(
                                      height: 80,
                                      width: 80,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.fastfood, color: Colors.grey),
                                    ),
                                  )
                                : Image.asset(
                                    imageUrl,
                                    height: 80,
                                    width: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) => Container(
                                      height: 80,
                                      width: 80,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.fastfood, color: Colors.grey),
                                    ),
                                  ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['nama'] ?? 'Unknown',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              priceStr,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FavoriteButton(
                        itemId: doc.id,
                        isResto: false,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
