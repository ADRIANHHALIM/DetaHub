// lib/features/home/screens/home_screen.dart
//
// Modern Technical Instrument Home Dashboard for DetaHub.
// Adheres strictly to Idea/Style.md (DetaDesign System):
// - Lab Instrument Aesthetic (Clean, precise, zero-cloud).
// - Exact Color Tokens: #F8F9FA canvas, #FFFFFF surface, #D0D7DE border.
// - JetBrains Mono for all numeric telemetries and status tags.
// - Inter typography with precise tracking.
// - Modular 10px radius for cards, 4px for badges/chips.

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/device_dao.dart';
import '../../../core/database/daos/sector_dao.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/aqi_badge.dart';
import '../../../core/widgets/connection_pill.dart';
import '../../../core/widgets/metric_card.dart';
import '../../device/providers/device_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(watchAllDevicesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final surfaceVariant = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMuted;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'DetaHub',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: surfaceVariant,
                borderRadius: BorderRadius.circular(kRadiusChip),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Text(
                'LOCAL INSTRUMENT',
                style: AppTheme.monoStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Subnet Status Pill
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.aqiGood.withValues(alpha: 0.1),
              border: Border.all(color: AppColors.aqiGood, width: 1),
              borderRadius: BorderRadius.circular(kRadiusChip),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.aqiGood,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'SUBNET ACTIVE',
                  style: AppTheme.monoStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.aqiGood,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: devicesAsync.when(
          loading: () => const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
          ),
          error: (err, _) => Center(
            child: Text('Database error: $err', style: const TextStyle(color: AppColors.aqiPoor)),
          ),
          data: (devices) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                // Section Title (Style.md 3: 18px · Bold · Sans-Serif · Tracking -0.02em)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SYSTEM OVERVIEW',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ZERO-CLOUD · LOCAL SQLITE TELEMETRY',
                          style: AppTheme.monoStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: textMuted,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/products'),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Node'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Hero Instrument Panel
                if (devices.isEmpty)
                  _buildEmptyHardwareShowcase(context, ref, isDark)
                else
                  _buildLiveSystemInstrument(context, devices, isDark),

                const SizedBox(height: 24),

                // Connected Nodes Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CONNECTED HARDWARE NODES',
                      style: AppTheme.monoStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      '${devices.length} NODE${devices.length == 1 ? '' : 'S'} REGISTERED',
                      style: AppTheme.monoStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Devices List
                if (devices.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(kRadiusCard),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: Center(
                      child: Text(
                        'No physical devices paired on subnet yet.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: textMuted),
                      ),
                    ),
                  )
                else
                  ...devices.map((device) => _buildDeviceNodeCard(context, ref, device, isDark)),

                const SizedBox(height: 24),

                // Industrial Architecture Footer Banner
                _buildArchitectureFooter(context, isDark),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Hardware Showcase & Quickstart (When No Devices Yet)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildEmptyHardwareShowcase(BuildContext context, WidgetRef ref, bool isDark) {
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final surfaceVariant = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMuted;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: surfaceVariant,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(kRadiusCard - 1)),
              border: Border(bottom: BorderSide(color: borderColor, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.memory, size: 16, color: AppColors.aqiGood),
                    const SizedBox(width: 8),
                    Text(
                      'HARDWARE PLATFORM · ESP32-H2',
                      style: AppTheme.monoStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.aqiGood.withValues(alpha: 0.15),
                    border: Border.all(color: AppColors.aqiGood, width: 1),
                    borderRadius: BorderRadius.circular(kRadiusChip),
                  ),
                  child: Text(
                    'LAT ENS160',
                    style: AppTheme.monoStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.aqiGood,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lightweight Air Tester (LAT)',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Connected physical instrument monitor. Streams live eCO₂, TVOC, temperature & relative humidity directly over local Wi-Fi / mDNS without internet.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: textSecondary,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 14),

                // Hardware Sensor Chips (Style.md 5: 4px radius)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildSpecChip('ENS160 MOX Gas', isDark),
                    _buildSpecChip('SHT40 Temp/RH', isDark),
                    _buildSpecChip('Local REST API', isDark),
                    _buildSpecChip('mDNS ZeroConf', isDark),
                    _buildSpecChip('Drift SQLite Store', isDark),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Sensor Readout Preview Strip (Scientific Air Quality Palette)
                Text(
                  'SCIENTIFIC TELEMETRY DISPLAY SPECIFICATION',
                  style: AppTheme.monoStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),

                // 4-Column Live Metric Grid with Style.md 4.5 Chart Colors
                const Row(
                  children: [
                    Expanded(
                      child: MetricCard(
                        label: 'eCO₂',
                        value: '480',
                        unit: 'PPM',
                        valueColor: AppColors.metricEco2,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: MetricCard(
                        label: 'TVOC',
                        value: '115',
                        unit: 'PPB',
                        valueColor: AppColors.metricTvoc,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Expanded(
                      child: MetricCard(
                        label: 'TEMP',
                        value: '24.8',
                        unit: '°C',
                        valueColor: AppColors.metricTemperature,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: MetricCard(
                        label: 'HUMIDITY',
                        value: '58.2',
                        unit: '%',
                        valueColor: AppColors.metricHumidity,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.go('/products'),
                        icon: const Icon(Icons.add_link, size: 16),
                        label: const Text('Pair LAT Device'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _seedSampleDevice(ref),
                        icon: const Icon(Icons.bolt, size: 16, color: AppColors.aqiGood),
                        label: const Text('Add Demo Node'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Live System Instrument (When Devices Exist)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildLiveSystemInstrument(BuildContext context, List<Device> devices, bool isDark) {
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final surfaceVariant = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: surfaceVariant,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(kRadiusCard - 1)),
              border: Border(bottom: BorderSide(color: borderColor, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AGGREGATE LAB TELEMETRY',
                  style: AppTheme.monoStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                const AqiBadge(aqi: 1),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Discrete AQI 5-Step Bar (Style.md 4.5)
                Row(
                  children: List.generate(5, (index) {
                    final level = index + 1;
                    final isActive = level == 1; // Good
                    final color = AppColors.forAqi(level);

                    return Expanded(
                      child: Container(
                        height: 6,
                        margin: EdgeInsets.only(right: index == 4 ? 0 : 4),
                        decoration: BoxDecoration(
                          color: isActive ? color : color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(
                            color: isActive ? color : color.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'LEVEL 1 · GOOD (ENS160)',
                      style: AppTheme.monoStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.aqiGood,
                      ),
                    ),
                    Text(
                      'TARGET: < 800 PPM eCO₂',
                      style: AppTheme.monoStyle(fontSize: 10, color: textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 4-Card Sensor Display
                const Row(
                  children: [
                    Expanded(
                      child: MetricCard(
                        label: 'eCO₂',
                        value: '495',
                        unit: 'PPM',
                        valueColor: AppColors.metricEco2,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: MetricCard(
                        label: 'TVOC',
                        value: '130',
                        unit: 'PPB',
                        valueColor: AppColors.metricTvoc,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Expanded(
                      child: MetricCard(
                        label: 'TEMP',
                        value: '25.2',
                        unit: '°C',
                        valueColor: AppColors.metricTemperature,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: MetricCard(
                        label: 'HUMIDITY',
                        value: '56.4',
                        unit: '%',
                        valueColor: AppColors.metricHumidity,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Registered Device Card
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDeviceNodeCard(BuildContext context, WidgetRef ref, Device device, bool isDark) {
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          // Device Icon Container
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(kRadiusChip),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: const Icon(Icons.router, size: 20, color: AppColors.aqiGood),
          ),
          const SizedBox(width: 12),

          // Device Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      device.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(width: 8),
                    const ConnectionPill(status: ConnectionStatus.online),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      device.id,
                      style: AppTheme.monoStyle(fontSize: 10, color: textMuted),
                    ),
                    Text(
                      ' · ${device.baseUrl}',
                      style: AppTheme.monoStyle(fontSize: 10, color: textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Navigate / Inspect
          IconButton(
            icon: Icon(Icons.arrow_forward, size: 16, color: textSecondary),
            onPressed: () => context.go('/products'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Specs Chip
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSpecChip(String text, bool isDark) {
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final surfaceVariant = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: surfaceVariant,
        borderRadius: BorderRadius.circular(kRadiusChip),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        text,
        style: AppTheme.monoStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Architecture & Privacy Footer
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildArchitectureFooter(BuildContext context, bool isDark) {
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final surfaceVariant = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: surfaceVariant,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, size: 18, color: AppColors.aqiGood),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '100% LOCAL-FIRST · ZERO CLOUD PRIVACY',
                  style: AppTheme.monoStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.aqiGood,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'All telemetry stored locally in SQLite via Drift. No telemetry leaves your local network.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: textMuted,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Instant Demo Node Seeder (for iOS simulator testing)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _seedSampleDevice(WidgetRef ref) async {
    final sectorDao = ref.read(sectorDaoProvider);
    final deviceDao = ref.read(deviceDaoProvider);

    // 1. Ensure Sector exists
    final sectors = await sectorDao.watchAllSectors().first;
    int sectorId;
    if (sectors.isEmpty) {
      sectorId = await sectorDao.insertSector(
        const SectorsCompanion(name: Value('Research Campus')),
      );
    } else {
      sectorId = sectors.first.id;
    }

    // 2. Ensure SubSector exists
    final subSectors = await sectorDao.watchSubSectorsForSector(sectorId).first;
    int subSectorId;
    if (subSectors.isEmpty) {
      subSectorId = await sectorDao.insertSubSector(
        SubSectorsCompanion(
          name: const Value('Main IoT Laboratory'),
          sectorId: Value(sectorId),
        ),
      );
    } else {
      subSectorId = subSectors.first.id;
    }

    // 3. Upsert Sample Device
    await deviceDao.upsertDevice(
      DevicesCompanion(
        id: const Value('lat-esp32h2-01'),
        subSectorId: Value(subSectorId),
        name: const Value('LAT Air Tester #01'),
        baseUrl: const Value('http://192.168.1.100'),
        productType: const Value('LAT_ENS160'),
        createdAt: Value(DateTime.now()),
        lastSeenAt: Value(DateTime.now()),
      ),
    );
  }
}
