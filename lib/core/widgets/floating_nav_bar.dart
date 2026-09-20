import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<FloatingNavDestination> destinations;

  const FloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final activeBg = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;
    final activeText = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final inactiveText = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(kRadiusCard),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: List.generate(destinations.length, (index) {
            final dest = destinations[index];
            final isSelected = selectedIndex == index;

            return Expanded(
              child: InkWell(
                onTap: () => onDestinationSelected(index),
                borderRadius: BorderRadius.circular(kRadiusButton),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? activeBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(kRadiusButton),
                    border: isSelected
                        ? Border.all(color: borderColor, width: 1)
                        : Border.all(color: Colors.transparent, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSelected ? dest.selectedIcon : dest.icon,
                        color: isSelected ? activeText : inactiveText,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dest.label,
                        style: GoogleFonts.inter(
                          color: isSelected ? activeText : inactiveText,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class FloatingNavDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const FloatingNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

