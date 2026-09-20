import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The official DetaHub brand mark rendered from logo.png.
class DetaHubMark extends StatelessWidget {
  final double size;
  final double? borderRadius;
  const DetaHubMark({super.key, this.size = 40, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? (size * .24);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.35 : 0.06),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          'assets/images/logo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class DetaHubHeader extends StatelessWidget {
  final Widget? action;
  final EdgeInsets padding;
  const DetaHubHeader(
      {super.key,
      this.action,
      this.padding = const EdgeInsets.fromLTRB(20, 18, 20, 8)});

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).brightness == Brightness.dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
    return Padding(
      padding: padding,
      child: Row(children: [
        const DetaHubMark(),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('DetaHub',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 1),
          Text('Local IoT Companion',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: secondary)),
        ])),
        if (action != null) action!,
      ]),
    );
  }
}

class DetaHubIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  const DetaHubIconButton(
      {super.key, required this.icon, required this.tooltip, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: tooltip,
      child: Material(
        color: dark ? AppColors.surfaceVariantDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(width: 44, height: 44, child: Icon(icon, size: 19)),
        ),
      ),
    );
  }
}
