// lib/features/home/screens/home_screen.dart
//
// "Your devices" Home Dashboard (GitHub Issue #2).
// Centered around the user mental model:
// "I have a device, where is it located, and what is its data?"
// Neutral by default; color communicates status only.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/daos/sector_dao.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/aqi_badge.dart';
import '../../sector/providers/sector_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int? _selectedLocationId; // null = All Locations

  @override
  Widget build(BuildContext context) {
    final devicesWithLocAsync = ref.watch(watchAllDevicesWithLocationProvider);
    final sectorsAsync = ref.watch(watchAllSectorsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMuted;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DetaHub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 22),
            tooltip: 'Add Device',
            onPressed: () => context.push('/add-device'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: devicesWithLocAsync.when(
          loading: () => const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
          ),
          error: (err, _) => Center(child: Text('Error loading devices: $err')),
          data: (allDevices) {
            // Filter devices by location if selected
            final filteredDevices = _selectedLocationId == null
                ? allDevices
                : allDevices.where((d) => d.sectorId == _selectedLocationId).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                // Header: "Your devices" (Issue #2)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your devices',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Monitor your DetaLab devices',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: textSecondary,
                              ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/add-device'),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add device'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Location Filter Chips
                sectorsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (sectors) {
                    if (sectors.isEmpty) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _filterChip(
                              label: 'All Locations',
                              isSelected: _selectedLocationId == null,
                              onTap: () => setState(() => _selectedLocationId = null),
                              isDark: isDark,
                            ),
                            const SizedBox(width: 8),
                            ...sectors.map((sector) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _filterChip(
                                  label: sector.name,
                                  isSelected: _selectedLocationId == sector.id,
                                  onTap: () => setState(() => _selectedLocationId = sector.id),
                                  isDark: isDark,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Device Cards List
                if (filteredDevices.isEmpty)
                  _buildFriendlyEmptyState(context, isDark, allDevices.isEmpty)
                else
                  ...filteredDevices.map(
                    (item) => _buildDeviceCard(context, item, isDark, surfaceColor, borderColor, textSecondary, textMuted),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Location Filter Chip
  // ─────────────────────────────────────────────────────────────────────────
  Widget _filterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final activeBg = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;
    final activeColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final inactiveColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kRadiusChip),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(kRadiusChip),
          border: Border.all(
            color: isSelected ? activeColor : borderColor,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Device Card (Directly following Issue #2 mockup)
  // ┌─────────────────────────────────────┐
  // │ Lightweight Air Tester              │
  // │ Lab IoT · Universitas Trisakti      │
  // │                                     │
  // │ Air quality                         │
  // │ 42 (or Good)                        │
  // │                                     │
  // │ Temperature       Humidity          │
  // │ 27.4 °C           61 %              │
  // │                                     │
  // │ ● Connected                         │
  // │ Updated 12 sec ago                  │
  // └─────────────────────────────────────┘
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDeviceCard(
    BuildContext context,
    DeviceWithLocation item,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color textSecondary,
    Color textMuted,
  ) {
    final device = item.device;
    const aqi = 1; // Default/latest AQI

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => context.push('/devices/${device.id}'),
        borderRadius: BorderRadius.circular(kRadiusCard),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Device Name & Subtitle (Area · Location)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${item.areaName} · ${item.locationName}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
                ],
              ),

              const SizedBox(height: 16),

              // Air Quality Reading
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Air quality',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: textSecondary,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '42',
                            style: AppTheme.monoStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'AQI',
                            style: AppTheme.monoStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const AqiBadge(aqi: aqi),
                ],
              ),

              const SizedBox(height: 16),
              Divider(height: 1, color: borderColor),
              const SizedBox(height: 14),

              // Secondary Metrics: Temperature & Humidity (Neutral by default)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Temperature',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: textSecondary,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '27.4 °C',
                          style: AppTheme.monoStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Humidity',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: textSecondary,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '61 %',
                          style: AppTheme.monoStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Divider(height: 1, color: borderColor),
              const SizedBox(height: 12),

              // Footer: Connection status & Last updated timestamp
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.aqiGood,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Connected',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.aqiGood,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                  Text(
                    'Updated recently',
                    style: AppTheme.monoStyle(
                      fontSize: 11,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Friendly Empty State
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFriendlyEmptyState(BuildContext context, bool isDark, bool noDevicesAtAll) {
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        children: [
          Icon(Icons.air_outlined, size: 48, color: textMuted),
          const SizedBox(height: 16),
          Text(
            noDevicesAtAll ? 'No devices connected yet' : 'No devices in this location',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            noDevicesAtAll
                ? 'Connect your Lightweight Air Tester to start monitoring air quality, temperature, and humidity locally.'
                : 'Select another location or tap below to add a device here.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textSecondary,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/add-device'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add device'),
          ),
        ],
      ),
    );
  }
}
