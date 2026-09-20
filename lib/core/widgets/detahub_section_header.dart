import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class DetaHubSectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;
  const DetaHubSectionHeader(
      {super.key, required this.title, this.trailing, this.onTrailingTap});
  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).brightness == Brightness.dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
    return Row(children: [
      Expanded(
          child:
              Text(title, style: Theme.of(context).textTheme.headlineMedium)),
      if (trailing != null)
        InkWell(
          onTap: onTrailingTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(trailing!,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: muted)),
          ),
        ),
    ]);
  }
}
