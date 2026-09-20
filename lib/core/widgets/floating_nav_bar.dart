import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A deliberately non-Material tab bar: selected destinations grow into a
/// compact living island while inactive items remain icon-only.
class FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<FloatingNavDestination> destinations;
  const FloatingNavBar(
      {super.key,
      required this.selectedIndex,
      required this.onDestinationSelected,
      required this.destinations});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? AppColors.surfaceDark : AppColors.surface;
    final border = dark ? AppColors.borderDark : AppColors.borderSubtle;
    return SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
              color: surface,
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: dark ? .22 : .07),
                    blurRadius: 24,
                    offset: const Offset(0, 10))
              ]),
          child: Row(
              children: List.generate(destinations.length, (index) {
            final item = destinations[index];
            final selected = selectedIndex == index;
            final accent = dark ? AppColors.accentDark : AppColors.accent;
            final inactive =
                dark ? AppColors.textSecondaryDark : AppColors.textSecondary;
            return Expanded(
                child: Semantics(
                    button: true,
                    selected: selected,
                    label: item.label,
                    child: InkWell(
                      onTap: () => onDestinationSelected(index),
                      borderRadius: BorderRadius.circular(25),
                      child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: const Cubic(.2, .75, .25, 1),
                          height: 48,
                          decoration: BoxDecoration(
                              color: selected
                                  ? (dark
                                      ? AppColors.accentSoftDark
                                      : AppColors.accentSoft)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(25)),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedScale(
                                    scale: selected ? 1 : .92,
                                    duration: const Duration(milliseconds: 200),
                                    curve: const Cubic(.2, .75, .25, 1),
                                    child: Icon(
                                        selected
                                            ? item.selectedIcon
                                            : item.icon,
                                        size: 20,
                                        color: selected ? accent : inactive)),
                                AnimatedSize(
                                    duration: const Duration(milliseconds: 200),
                                    curve: const Cubic(.2, .75, .25, 1),
                                    child: selected
                                        ? Padding(
                                            padding:
                                                const EdgeInsets.only(left: 7),
                                            child: Text(item.label,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelMedium
                                                    ?.copyWith(
                                                        color: accent,
                                                        fontWeight:
                                                            FontWeight.w700)))
                                        : const SizedBox.shrink()),
                              ])),
                    )));
          })),
        ));
  }
}

class FloatingNavDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const FloatingNavDestination(
      {required this.icon, required this.selectedIcon, required this.label});
}
