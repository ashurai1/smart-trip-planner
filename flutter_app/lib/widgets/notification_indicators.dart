import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A pulsing dot indicator for new notifications/messages
class PulsingDot extends StatelessWidget {
  final Color color;
  final double size;

  const PulsingDot({
    Key? key,
    this.color = Colors.red,
    this.size = 8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    )
    .animate(onPlay: (controller) => controller.repeat())
    .fadeIn(duration: 600.ms)
    .then()
    .fadeOut(duration: 600.ms);
  }
}

/// A "NEW" badge for newly added items
class NewBadge extends StatelessWidget {
  const NewBadge({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6A3D), Color(0xFFFF3D77)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6A3D).withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Text(
        'NEW',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    )
    .animate(onPlay: (controller) => controller.repeat(reverse: true))
    .scale(duration: 800.ms, begin: const Offset(1.0, 1.0), end: const Offset(1.05, 1.05));
  }
}
