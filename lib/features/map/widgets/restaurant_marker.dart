import 'package:flutter/material.dart';
import 'package:carimakan/core/theme/app_colors.dart';

class RestaurantMarkerWidget extends StatelessWidget {
  final String category;
  final VoidCallback onTap;

  const RestaurantMarkerWidget({
    super.key,
    required this.category,
    required this.onTap,
  });

  IconData _getIconForCategory() {
    switch (category.toLowerCase()) {
      case 'cafe':
      case 'minuman':
        return Icons.local_cafe;
      case 'makanan berat':
      case 'ayam':
      case 'bakso':
      case 'seafood':
        return Icons.restaurant;
      case 'fastfood':
        return Icons.fastfood;
      case 'dessert':
        return Icons.icecream;
      default:
        return Icons.storefront;
    }
  }

  Color _getColorForCategory() {
    switch (category.toLowerCase()) {
      case 'cafe':
      case 'minuman':
        return Colors.brown[600] ?? Colors.brown;
      case 'makanan berat':
      case 'ayam':
      case 'bakso':
      case 'seafood':
        return AppColors.primary;
      case 'fastfood':
        return Colors.orange[800] ?? Colors.orange;
      case 'dessert':
        return Colors.pink[400] ?? Colors.pink;
      default:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final markerColor = _getColorForCategory();
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 0,
            child: Container(
              width: 12,
              height: 4,
              decoration: const BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.all(Radius.circular(6)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: markerColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: markerColor.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _getIconForCategory(),
                  color: Colors.white,
                  size: 18,
                ),
              ),
              CustomPaint(
                size: const Size(10, 6),
                painter: _TrianglePainter(color: markerColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class UserLocationMarkerWidget extends StatelessWidget {
  const UserLocationMarkerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
