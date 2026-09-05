import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum SnackBarType { success, error, info, warning }

class CustomSnackBar {
  static void show(
      BuildContext context, {
        required String message,
        bool fromTop = true,
        SnackBarType type = SnackBarType.info,
        Duration duration = const Duration(seconds: 3),
      }) {
    Color bgColor;
    IconData icon;

    switch (type) {
      case SnackBarType.success:
        bgColor = Colors.green.shade500;
        icon = Icons.check_circle_rounded;
        break;
      case SnackBarType.error:
        bgColor = Colors.red.shade600;
        icon = Icons.error_rounded;
        break;
      case SnackBarType.warning:
        bgColor = Colors.orange.shade700;
        icon = Icons.warning_amber_rounded;
        break;
      default:
        bgColor = Colors.blue.shade600;
        icon = Icons.info_rounded;
    }

    ScaffoldMessenger.of(context).clearSnackBars();

    final overlay = Overlay.of(context);

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _SlideSnackBar(
        message: message,
        bgColor: bgColor,
        icon: icon,
        duration: duration,
        fromTop: fromTop,
        onDismissed: () => overlayEntry.remove(),
      ),
    );

    overlay.insert(overlayEntry);
  }
}

class _SlideSnackBar extends StatefulWidget {
  final String message;
  final Color bgColor;
  final IconData icon;
  final Duration duration;
  final bool fromTop;
  final VoidCallback onDismissed;

  const _SlideSnackBar({
    required this.message,
    required this.bgColor,
    required this.icon,
    required this.duration,
    this.fromTop = true,
    required this.onDismissed,
  });

  @override
  State<_SlideSnackBar> createState() => _SlideSnackBarState();
}

class _SlideSnackBarState extends State<_SlideSnackBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Slide from top or bottom
    _offsetAnimation = Tween<Offset>(
      begin: widget.fromTop ? const Offset(0, -1) : const Offset(0, 1),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    Future.delayed(widget.duration, () async {
      await _controller.reverse();
      widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.fromTop ? 56 : null,
      bottom: widget.fromTop ? null : 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.bgColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                      widget.message,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      )
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
