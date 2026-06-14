import 'package:flutter/material.dart';
import 'favorite_service.dart';

class FavoriteButton extends StatelessWidget {
  final String itemId;
  final bool isResto;
  final double iconSize;
  final Color iconColor;
  final Color favoriteColor;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;
  final BoxBorder? border;
  final VoidCallback? onTap;

  const FavoriteButton({
    super.key,
    required this.itemId,
    this.isResto = true,
    this.iconSize = 18.0,
    this.iconColor = Colors.black54,
    this.favoriteColor = Colors.red,
    this.backgroundColor = Colors.white,
    this.padding = const EdgeInsets.all(6.0),
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FavoriteService.instance,
      builder: (context, child) {
        final isFavorite = FavoriteService.instance.isFavorite(itemId, isResto);

        return GestureDetector(
          onTap: () {
            FavoriteService.instance.toggleFavorite(itemId, isResto);
            if (onTap != null) {
              onTap!();
            }
          },
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              border: border,
            ),
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              size: iconSize,
              color: isFavorite ? favoriteColor : iconColor,
            ),
          ),
        );
      },
    );
  }
}
