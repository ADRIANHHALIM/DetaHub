import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class DetaHubButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outlined;
  final bool expand;
  const DetaHubButton(
      {super.key,
      required this.label,
      this.onPressed,
      this.icon,
      this.outlined = false,
      this.expand = false});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fg = outlined
        ? (dark ? AppColors.textPrimaryDark : AppColors.textPrimary)
        : Colors.white;
    final bg = outlined
        ? (dark ? AppColors.surfaceDark : AppColors.surface)
        : (dark ? AppColors.accentDark : AppColors.accent);
    final textFg = !outlined && dark ? AppColors.backgroundDark : fg;
    return Semantics(
      button: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(17),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(17),
            child: Container(
              width: expand ? double.infinity : null,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                border: outlined
                    ? Border.all(
                        color: dark ? AppColors.borderDark : AppColors.border)
                    : null,
              ),
              child: Row(
                  mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: textFg),
                      const SizedBox(width: 8)
                    ],
                    Text(label,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: textFg, fontWeight: FontWeight.w700)),
                  ]),
            ),
          ),
        ),
      ),
    );
  }
}
