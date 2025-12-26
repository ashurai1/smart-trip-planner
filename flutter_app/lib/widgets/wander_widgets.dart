import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/wander_flow_theme.dart';

// --- BUTTONS ---
class WanderButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;

  const WanderButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
  }) : super(key: key);

  @override
  State<WanderButton> createState() => _WanderButtonState();
}

class _WanderButtonState extends State<WanderButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: widget.isSecondary ? null : WanderFlowTheme.primaryGradient,
            color: widget.isSecondary ? Colors.white : null,
            borderRadius: BorderRadius.circular(16),
            border: widget.isSecondary ? Border.all(color: Colors.grey.shade300) : null,
            boxShadow: [
               if (!widget.isSecondary && widget.onPressed != null)
                 BoxShadow(color: WanderFlowTheme.primaryStart.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))
            ],
          ),
          child: Center(
            child: widget.isLoading 
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    widget.text,
                    style: GoogleFonts.poppins(
                      fontSize: 16, 
                      fontWeight: FontWeight.w600, 
                      color: widget.isSecondary ? WanderFlowTheme.textPrimary : Colors.white
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// --- CARD ---
class WanderCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  const WanderCard({
    Key? key, 
    required this.child, 
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
             onTap: onTap,
             splashColor: WanderFlowTheme.primaryStart.withOpacity(0.1),
             child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
    
    // Float animation on load
    return card.animate().slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOut).fadeIn();
  }
}

// --- TEXT FIELD ---
class WanderTextField extends StatelessWidget {
  final String hint;
  final String label;
  final IconData? icon;
  final bool isPassword;
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  const WanderTextField({
    Key? key,
    required this.hint,
    required this.label,
    this.icon,
    this.isPassword = false,
    this.controller,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          validator: validator,
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon, color: Colors.grey[400]) : null,
          ),
        ),
      ],
    );
  }
}
