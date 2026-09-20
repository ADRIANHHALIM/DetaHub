import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A small geometric mark used throughout DetaHub. It deliberately avoids
/// familiar network imagery: it is a quiet signature for a local product.
class DetaHubMark extends StatelessWidget {
  final double size;
  const DetaHubMark({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: dark ? AppColors.surfaceVariantDark : AppColors.accentSoft,
        borderRadius: BorderRadius.circular(size * .32),
      ),
      child: CustomPaint(painter: _DetaHubMarkPainter(ink)),
    );
  }
}

class _DetaHubMarkPainter extends CustomPainter {
  final Color color;
  const _DetaHubMarkPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = size.width * .09
      ..strokeCap = StrokeCap.round;
    final r = size.width * .11;
    canvas.drawLine(Offset(size.width * .29, size.height * .31),
        Offset(size.width * .29, size.height * .69), p);
    canvas.drawLine(Offset(size.width * .29, size.height * .5),
        Offset(size.width * .69, size.height * .5), p);
    canvas.drawCircle(Offset(size.width * .7, size.height * .3), r, p);
    canvas.drawCircle(Offset(size.width * .7, size.height * .7), r, p);
  }

  @override
  bool shouldRepaint(covariant _DetaHubMarkPainter old) => old.color != color;
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
