// lib/core/widgets/connection_pill.dart
//
// Compact connection status badge for Device cards.
// Three states: online (green), offline (stone), checking (blinking).

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum ConnectionStatus { online, offline, checking }

/// A small pill badge indicating a device's connection status.
///
/// Usage:
/// ```dart
/// ConnectionPill(status: ConnectionStatus.online)
/// ConnectionPill(status: ConnectionStatus.checking)
/// ```
class ConnectionPill extends StatefulWidget {
  final ConnectionStatus status;

  const ConnectionPill({super.key, required this.status});

  @override
  State<ConnectionPill> createState() => _ConnectionPillState();
}

class _ConnectionPillState extends State<ConnectionPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    // Blink animation for "checking" state: opacity 1.0 → 0.3 → 1.0.
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _opacity = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _blink, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (bg, border, label) = switch (widget.status) {
      ConnectionStatus.online => (
          AppColors.aqiExcellent.withValues(alpha: 0.12),
          AppColors.aqiExcellent,
          'Connected',
        ),
      ConnectionStatus.offline => (
          AppColors.aqiPoor.withValues(alpha: 0.12),
          AppColors.aqiPoor,
          'Offline',
        ),
      ConnectionStatus.checking => (
          AppColors.aqiModerate.withValues(alpha: 0.12),
          AppColors.aqiModerate,
          'Checking',
        ),
    };

    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: border, fontWeight: FontWeight.w700),
      ),
    );

    // Wrap in AnimatedBuilder only when checking — avoids unnecessary
    // animation overhead for the two static states.
    if (widget.status == ConnectionStatus.checking) {
      return AnimatedBuilder(
        animation: _opacity,
        builder: (_, __) => Opacity(opacity: _opacity.value, child: pill),
      );
    }

    return pill;
  }
}
