import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/detahub_brand.dart';
import '../../../core/widgets/detahub_button.dart';

/// The catalogue is intentionally separate from the user's connected devices.
class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        dark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final surface = dark ? AppColors.surfaceDark : AppColors.surface;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 116),
          children: [
            const DetaHubHeader(),
            const SizedBox(height: 32),
            Text('Products', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 6),
            Text('DetaLab devices designed for the spaces you care about.',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: secondary)),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color: dark
                      ? AppColors.surfaceVariantDark
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(26)),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                    color: surface, borderRadius: BorderRadius.circular(20)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 176,
                        width: double.infinity,
                        decoration: BoxDecoration(
                            color: dark
                                ? AppColors.surfaceVariantDark
                                : AppColors.accentSoft,
                            borderRadius: BorderRadius.circular(18)),
                        child: Center(
                            child: SizedBox(
                                width: 104,
                                height: 126,
                                child: CustomPaint(
                                    painter: _ProductIllustration(dark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimary)))),
                      ),
                      const SizedBox(height: 24),
                      Text('Lightweight Air Tester',
                          style: Theme.of(context).textTheme.headlineLarge),
                      const SizedBox(height: 8),
                      Text(
                          'Monitor air quality in your environment with simple, local readings you can trust.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: secondary)),
                      const SizedBox(height: 20),
                      DetaHubButton(
                          label: 'Connect this product',
                          icon: Icons.add,
                          onPressed: () => context.push('/add-device')),
                    ]),
              ),
            ),
            const SizedBox(height: 24),
            Text('More DetaLab products are on their way.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: secondary)),
          ],
        ),
      ),
    );
  }
}

class _ProductIllustration extends CustomPainter {
  final Color color;
  _ProductIllustration(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final outline = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final fill = Paint()..color = color.withValues(alpha: .08);
    final device = RRect.fromRectAndRadius(
        Rect.fromLTWH(20, 6, size.width - 40, size.height - 12),
        const Radius.circular(21));
    canvas.drawRRect(device, fill);
    canvas.drawRRect(device, outline);
    canvas.drawCircle(Offset(size.width / 2, 44), 10, outline);
    canvas.drawLine(const Offset(36, 82), Offset(size.width - 36, 82), outline);
    canvas.drawLine(
        const Offset(36, 96), Offset(size.width * .63, 96), outline);
  }

  @override
  bool shouldRepaint(_ProductIllustration old) => old.color != color;
}
