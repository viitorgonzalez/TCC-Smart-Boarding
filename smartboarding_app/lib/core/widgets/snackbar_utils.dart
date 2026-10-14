import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

OverlayEntry? _activeBanner;

void showErrorSnackBar(BuildContext context, String message) {
  _showTopBanner(
    context,
    message,
    background: AppColors.dangerBg,
    foreground: AppColors.danger,
    icon: Icons.error_outline,
  );
}

void showSuccessSnackBar(BuildContext context, String message) {
  _showTopBanner(
    context,
    message,
    background: AppColors.positiveBg,
    foreground: AppColors.positiveFg,
    icon: Icons.check_circle_outline,
  );
}

void _showTopBanner(
  BuildContext context,
  String message, {
  required Color background,
  required Color foreground,
  required IconData icon,
}) {
  _activeBanner?.remove();
  _activeBanner = null;

  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _TopBanner(
      message: message,
      background: background,
      foreground: foreground,
      icon: icon,
      onDismissed: () {
        if (identical(_activeBanner, entry)) _activeBanner = null;
        entry.remove();
      },
    ),
  );
  _activeBanner = entry;
  overlay.insert(entry);
}

class _TopBanner extends StatefulWidget {
  final String message;
  final Color background;
  final Color foreground;
  final IconData icon;
  final VoidCallback onDismissed;

  const _TopBanner({
    required this.message,
    required this.background,
    required this.foreground,
    required this.icon,
    required this.onDismissed,
  });

  @override
  State<_TopBanner> createState() => _TopBannerState();
}

class _TopBannerState extends State<_TopBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offset;
  Timer? _autoDismiss;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _offset = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    _autoDismiss = Timer(const Duration(seconds: 4), _dismiss);
  }

  Future<void> _dismiss() async {
    if (_dismissing) return;
    _dismissing = true;
    _autoDismiss?.cancel();
    if (mounted) await _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _autoDismiss?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: SlideTransition(
          position: _offset,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _dismiss,
            onVerticalDragEnd: (details) {
              if ((details.primaryVelocity ?? 0) < 0) _dismiss();
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: widget.background,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                  boxShadow: AppShadow.floating,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(widget.icon, color: widget.foreground),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          color: widget.foreground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
