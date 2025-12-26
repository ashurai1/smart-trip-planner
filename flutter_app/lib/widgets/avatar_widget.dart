import 'package:flutter/material.dart';
import '../models/models.dart';

class AvatarWidget extends StatelessWidget {
  final AvatarData avatar;
  final double size;
  final VoidCallback? onTap;

  const AvatarWidget({
    Key? key,
    required this.avatar,
    this.size = 40,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: getGradient(avatar.color),
          border: Border.all(
            color: Colors.white,
            width: size * 0.05, // 5% border width
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: size * 0.1,
              offset: Offset(0, size * 0.05),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            getIcon(avatar.icon),
            color: Colors.white,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }

  LinearGradient getGradient(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'green':
        return const LinearGradient(
          colors: [Color(0xFF00C853), Color(0xFF69F0AE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'orange':
        return const LinearGradient(
          colors: [Color(0xFFFF6D00), Color(0xFFFFAB40)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'red':
        return const LinearGradient(
          colors: [Color(0xFFD50000), Color(0xFFFF5252)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'purple':
        return const LinearGradient(
          colors: [Color(0xFFAA00FF), Color(0xFFE040FB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'black':
         return const LinearGradient(
          colors: [Color(0xFF212121), Color(0xFF424242)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'blue':
      default:
        return const LinearGradient(
          colors: [Color(0xFF2962FF), Color(0xFF448AFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  IconData getIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'plane':
        return Icons.flight;
      case 'mountain':
        return Icons.terrain;
      case 'beach':
        return Icons.beach_access;
      case 'city':
        return Icons.location_city;
      case 'food':
        return Icons.restaurant;
      case 'music':
        return Icons.music_note;
      case 'camera':
        return Icons.camera_alt;
      case 'person':
      default:
        return Icons.person;
    }
  }
}
