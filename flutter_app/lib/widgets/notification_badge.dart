import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class NotificationBadge extends StatelessWidget {
  final int count;
  final Widget? child;
  final Color? color;
  final double size;

  const NotificationBadge({
    Key? key,
    required this.count,
    this.child,
    this.color,
    this.size = 20,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // If wrapping a child (like an Icon)
    if (child != null) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          child!,
          if (count > 0)
            Positioned(
              right: -6,
              top: -6,
              child: _buildBadge(context),
            ),
        ],
      );
    }
    
    // Standalone
    if (count == 0) return const SizedBox.shrink();
    return _buildBadge(context);
  }

  Widget _buildBadge(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? Colors.red,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ]
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : count.toString(),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.55,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    )
    .animate(key: ValueKey(count)) // Animate when count changes
    .scale(duration: 300.ms, curve: Curves.elasticOut)
    .fadeIn(duration: 200.ms);
  }
}
