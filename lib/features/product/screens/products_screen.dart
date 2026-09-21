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
              decoration: BoxDecoration(
                color: dark
                    ? AppColors.surfaceVariantDark
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(26),
              ),
              padding: const EdgeInsets.all(7),
              child: Material(
                color: surface,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: () => context.push('/products/lat'),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 190,
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: dark
                                ? AppColors.surfaceVariantDark
                                : AppColors.accentSoft,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/images/LAT.webp',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                'Lightweight Air Tester',
                                style:
                                    Theme.of(context).textTheme.headlineLarge,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward,
                              size: 20,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Monitor air quality in your environment with simple, local readings you can trust.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: secondary),
                        ),
                        const SizedBox(height: 16),
                        DetaHubButton(
                          label: 'View specifications & story',
                          outlined: true,
                          expand: true,
                          onPressed: () => context.push('/products/lat'),
                        ),
                        const SizedBox(height: 8),
                        DetaHubButton(
                          label: 'Connect this product',
                          icon: Icons.add,
                          expand: true,
                          onPressed: () => context.push('/add-device'),
                        ),
                      ],
                    ),
                  ),
                ),
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
