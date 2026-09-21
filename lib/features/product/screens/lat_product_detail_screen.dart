// lib/features/product/screens/lat_product_detail_screen.dart
//
// Technical specification & product story for LAT (Lightweight Air Tester).
// Designed with Technical Elegance / Lab Instrument Aesthetic (Idea/Style.md).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/detahub_button.dart';

class LatProductDetailScreen extends StatelessWidget {
  const LatProductDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? AppColors.backgroundDark : AppColors.background;
    final surface = dark ? AppColors.surfaceDark : AppColors.surface;
    final surfaceVariant =
        dark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;
    final border = dark ? AppColors.borderDark : AppColors.border;
    final textPrimary =
        dark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSecondary =
        dark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final textMuted = dark ? AppColors.textMutedDark : AppColors.textMuted;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 20, color: textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'LAT / SPECS & STORY',
          style: AppTheme.monoStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ).copyWith(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => context.push('/add-device'),
            child: Text(
              'Connect',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: dark ? AppColors.accentDark : AppColors.accent,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
          children: [
            // ─────────────────────────────────────────────────────────────
            // Hero / Identity Banner
            // ─────────────────────────────────────────────────────────────
            Row(
              children: [
                _buildTagChip('LAT / LIGHTWEIGHT AIR TESTER', surfaceVariant,
                    border, textSecondary),
                const SizedBox(width: 8),
                _buildTagChip(
                    'JAKARTA · 2026', surfaceVariant, border, textSecondary),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'BREATHE.\nKNOW WHAT\'S IN IT.',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    height: 1.1,
                    letterSpacing: -1.0,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'A low-cost, open-source indoor air quality monitor built on the ESP32-H2 Mini with the ScioSense ENS160 and ENS210 sensors. Measures eCO₂, TVOC, AQI, temperature, and humidity — for under USD 20.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: textSecondary,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 20),

            // Hero Key Metrics Strip
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(kRadiusCard),
                border: Border.all(color: border, width: kBorderWidth),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LIVE AQI',
                            style: AppTheme.monoStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6,
                            ).copyWith(color: textMuted),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.aqiUnhealthy,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '4 · UNHEALTHY',
                                style: AppTheme.monoStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ).copyWith(color: AppColors.aqiUnhealthy),
                              ),
                            ],
                          ),
                        ],
                      ),
                      _buildHeroStat(
                          '03 / COST', 'USD 19.05', textMuted, textPrimary),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildHeroStat('01 / MCU', 'ESP32-H2 Mini · RISC-V',
                          textMuted, textPrimary),
                      _buildHeroStat('02 / SENSORS', 'ENS160 + ENS210',
                          textMuted, textPrimary),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Hero Assembled Hardware Photo
            Container(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(kRadiusCard),
                border: Border.all(color: border, width: kBorderWidth),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 220,
                    width: double.infinity,
                    color: surfaceVariant,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Image.asset(
                          'assets/images/LAT.webp',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'LAT — Lightweight Air Tester final assembled product',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: textSecondary,
                                    ),
                          ),
                        ),
                        Text(
                          'DetaLab',
                          style: AppTheme.monoStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ).copyWith(color: textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),

            // ─────────────────────────────────────────────────────────────
            // / 00 — WHY LAT
            // ─────────────────────────────────────────────────────────────
            _buildSectionHeader('/ 00 — WHY LAT', textMuted),
            const SizedBox(height: 8),
            Text(
              'CLEAN AIR\nSHOULDN\'T COST\nA FORTUNE.',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            _buildContentCard(
              surface: surface,
              border: border,
              child: Text(
                'Indoor air quality has a direct impact on human health — yet commercial IAQ monitors typically cost USD 30–200, keeping them out of reach for most households. LAT closes that gap with off-the-shelf parts, open-source firmware, and real-time visual feedback for USD 19.05.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: textSecondary,
                      height: 1.5,
                    ),
              ),
            ),

            const SizedBox(height: 36),

            // ─────────────────────────────────────────────────────────────
            // / 00b — THE DEVICE
            // ─────────────────────────────────────────────────────────────
            _buildSectionHeader('/ 00b — THE DEVICE', textMuted),
            const SizedBox(height: 8),
            Text(
              'SIX PARTS.\nONE BOARD.',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            _buildContentCard(
              surface: surface,
              border: border,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Designed in EasyEDA, built from off-the-shelf components. No proprietary connectors, no exotic parts — just a clean I²C bus and a single MCU.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: textSecondary,
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTagChip('FIG. 03 — ASSEMBLED HARDWARE',
                          surfaceVariant, border, textPrimary),
                      _buildTagChip('FIG. 02 — 3D PCB DESIGN (EASYEDA)',
                          surfaceVariant, border, textPrimary),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),

            // ─────────────────────────────────────────────────────────────
            // / 01 — WHAT IT DOES
            // ─────────────────────────────────────────────────────────────
            _buildSectionHeader('/ 01 — WHAT IT DOES', textMuted),
            const SizedBox(height: 8),
            Text(
              'FIVE SENSES.\nONE TINY BOARD.',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Every measurement is processed on-device, stored locally, and served through a built-in web dashboard. No cloud account required.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textSecondary,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 14),

            _buildFeatureStepCard(
              index: '/ 01',
              title: 'Reads the air.',
              description:
                  'ENS160 MOX sensor outputs eCO₂, TVOC, and a 1–5 AQI. Four independent heating and doping profiles deliver superior selectivity over single-element sensors.',
              badgeColor: AppColors.metricEco2,
              surface: surface,
              border: border,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 10),
            _buildFeatureStepCard(
              index: '/ 02',
              title: 'Compensates itself.',
              description:
                  'ENS210 provides ±0.15 °C temperature and ±2.0 % RH humidity accuracy — fed into the ENS160 for on-chip environmental compensation.',
              badgeColor: AppColors.metricTemperature,
              surface: surface,
              border: border,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 10),
            _buildFeatureStepCard(
              index: '/ 03',
              title: 'Shows you instantly.',
              description:
                  'An SK6805-EC15 addressable RGB LED changes color with AQI — from light green (Good) to dark red (Very Unhealthy). Glanceable, no screen required.',
              badgeColor: AppColors.aqiGood,
              surface: surface,
              border: border,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),

            const SizedBox(height: 36),

            // ─────────────────────────────────────────────────────────────
            // / 02 — HOW IT WORKS
            // ─────────────────────────────────────────────────────────────
            _buildSectionHeader('/ 02 — HOW IT WORKS', textMuted),
            const SizedBox(height: 8),
            Text(
              'BUILT TO\nREPLICATE.',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 14),

            // Hardware Column
            _buildDualFlowCard(
              category: 'HARDWARE / OPEN-SOURCE PCB',
              headline: 'Two I²C sensors. One MCU.',
              summary:
                  'The ENS160 and ENS210 share a single I²C bus on the ESP32-H2 Mini. No proprietary 1-Wire protocols, no wiring spaghetti — just standard, well-documented parts. Designed in EasyEDA, fully open.',
              steps: const [
                ('1.0', 'Order PCB + components'),
                ('2.0', 'Solder 6 parts'),
                ('3.0', 'Flash firmware via Arduino IDE'),
              ],
              surface: surface,
              border: border,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              textMuted: textMuted,
            ),
            const SizedBox(height: 12),

            // Software Column
            _buildDualFlowCard(
              category: 'SOFTWARE / LOCAL-FIRST',
              headline: 'No cloud. No account.',
              summary:
                  'Data is logged as CSV to SPIFFS with automatic daily file rollover. An async web server on the ESP32-H2 serves a live dashboard, JSON endpoints, and CSV export over local Wi-Fi.',
              steps: const [
                ('1.0', 'Connect to device Wi-Fi'),
                ('2.0', 'Open dashboard in browser'),
                ('3.0', 'Export CSV for analysis'),
              ],
              surface: surface,
              border: border,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              textMuted: textMuted,
            ),

            const SizedBox(height: 36),

            // ─────────────────────────────────────────────────────────────
            // / 03 — SIGNAL PATH
            // ─────────────────────────────────────────────────────────────
            _buildSectionHeader('/ 03 — SIGNAL PATH', textMuted),
            const SizedBox(height: 8),
            Text(
              'SMALL BOARD.\nSERIOUS SENSING.',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 14),

            _buildSpecTableCard(
              surface: surface,
              border: border,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              textMuted: textMuted,
              specs: const [
                (
                  '01',
                  'Microcontroller',
                  'ESP32-H2 Mini · RISC-V · 320 KB SRAM · Wi-Fi 6 + BLE 5.0'
                ),
                (
                  '02',
                  'Air Quality',
                  'ENS160 MOX · eCO₂ 400–65,000 ppm · TVOC 0–65,000 ppb · AQI 1–5'
                ),
                (
                  '03',
                  'Temp / Humidity',
                  'ENS210 · ±0.15 °C · ±2.0 % RH · −40 to 125 °C · 40 nA standby'
                ),
                (
                  '04',
                  'Visual Indicator',
                  'SK6805-EC15 addressable RGB · 5-level AQI color mapping'
                ),
                (
                  '05',
                  'Storage',
                  'SPIFFS · CSV · daily rollover · data_YYYY-MM-DD.csv'
                ),
                (
                  '06',
                  'Interface',
                  'Async web dashboard · JSON API · CSV export · NTP sync'
                ),
              ],
            ),

            const SizedBox(height: 36),

            // ─────────────────────────────────────────────────────────────
            // / 04 — FIELD RESULTS
            // ─────────────────────────────────────────────────────────────
            _buildSectionHeader('/ 04 — FIELD RESULTS', textMuted),
            const SizedBox(height: 8),
            Text(
              'FIVE DAYS.\n5,657 SAMPLES.',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Validated in a bedroom environment in Petojo, Jakarta from August 30 to September 3, 2026. Continuous 1-minute sampling.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textSecondary,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 16),

            // 5 Sensor Metrics Grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    label: 'Temperature',
                    value: '35.3°C',
                    range: 'Range 31.9 – 38.3 °C',
                    color: AppColors.metricTemperature,
                    surface: surface,
                    border: border,
                    textMuted: textMuted,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    label: 'Humidity',
                    value: '54.2%',
                    range: 'Range 39.9 – 62.4 %',
                    color: AppColors.metricHumidity,
                    surface: surface,
                    border: border,
                    textMuted: textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    label: 'eCO₂',
                    value: '720ppm',
                    range: 'Range 400 – 2,573 ppm',
                    color: AppColors.metricEco2,
                    surface: surface,
                    border: border,
                    textMuted: textMuted,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    label: 'TVOC',
                    value: '248ppb',
                    range: 'Range 0 – 7,433 ppb',
                    color: AppColors.metricTvoc,
                    surface: surface,
                    border: border,
                    textMuted: textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildMetricTile(
              label: 'AQI (mean)',
              value: '2.3',
              range: 'Scale 1 – 5',
              color: AppColors.aqiModerate,
              surface: surface,
              border: border,
              textMuted: textMuted,
            ),

            const SizedBox(height: 20),

            // AQI Distribution Table
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(kRadiusCard),
                border: Border.all(color: border, width: kBorderWidth),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AQI Distribution Across 5 Days',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 14),
                  _buildAqiDistributionRow(
                      'AQI 1', 'Good', '22.1 %', AppColors.aqiGood, textMuted),
                  const Divider(height: 16),
                  _buildAqiDistributionRow('AQI 2', 'Moderate', '31.2 %',
                      AppColors.aqiModerate, textMuted),
                  const Divider(height: 16),
                  _buildAqiDistributionRow(
                      'AQI 3',
                      'Unhealthy for Sensitive Groups',
                      '37.1 %',
                      AppColors.aqiSensitive,
                      textMuted),
                  const Divider(height: 16),
                  _buildAqiDistributionRow('AQI 4', 'Unhealthy', '7.7 %',
                      AppColors.aqiUnhealthy, textMuted),
                  const Divider(height: 16),
                  _buildAqiDistributionRow('AQI 5', 'Very Unhealthy', '1.9 %',
                      AppColors.aqiVeryUnhealthy, textMuted),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildTagChip('FIG. 03B — FIELD DEPLOYMENT',
                        surfaceVariant, border, textMuted),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),

            // ─────────────────────────────────────────────────────────────
            // / 05 — POLLUTION EVENTS
            // ─────────────────────────────────────────────────────────────
            _buildSectionHeader('/ 05 — POLLUTION EVENTS', textMuted),
            const SizedBox(height: 8),
            Text(
              'THE AIR\nHAS A STORY.',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Five notable IAQ events were captured during the monitoring campaign — each tied to human occupancy, personal care products, or daily activity.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textSecondary,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 14),

            _buildPollutionEventCard(
              tag: 'EVENT 01 · AUG 31 · 08:18',
              title: 'Morning Spike',
              description:
                  'TVOC peaked at 5,849 ppb with eCO₂ at 1,989 ppm. Temperature 33.7 °C, humidity 60.0 %.',
              badge: 'AQI 5 · VERY UNHEALTHY',
              surface: surface,
              border: border,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 10),
            _buildPollutionEventCard(
              tag: 'EVENT 02 · SEP 01 · 17:07',
              title: 'Evening Activity',
              description:
                  'TVOC peaked at 4,728 ppb with eCO₂ at 1,657 ppm. Temperature 37.7 °C, humidity 50.4 %.',
              badge: 'AQI 5 · VERY UNHEALTHY',
              surface: surface,
              border: border,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 10),
            _buildPollutionEventCard(
              tag: 'EVENT 03 · SEP 02 · 19:21',
              title: 'Major Pollution Event',
              description:
                  'Highest readings of the entire campaign: TVOC 7,433 ppb and eCO₂ 2,573 ppm. Temperature 36.5 °C.',
              badge: 'AQI 5 · VERY UNHEALTHY',
              surface: surface,
              border: border,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 10),
            _buildPollutionEventCard(
              tag: 'EVENT 04 · SEP 02 · 21:00',
              title: 'Late Evening',
              description:
                  'TVOC 2,538 ppb with eCO₂ at 1,316 ppm. Temperature 36.2 °C, humidity stable.',
              badge: 'AQI 5 · VERY UNHEALTHY',
              surface: surface,
              border: border,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 10),
            _buildPollutionEventCard(
              tag: 'EVENT 05 · SEP 03 · 06:33',
              title: 'Dawn Air Change',
              description:
                  'TVOC 4,811 ppb with eCO₂ at 1,669 ppm. Temperature 32.6 °C, humidity 60.0 %.',
              badge: 'AQI 5 · VERY UNHEALTHY',
              surface: surface,
              border: border,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),

            const SizedBox(height: 36),

            // ─────────────────────────────────────────────────────────────
            // / 06 — VS COMMERCIAL
            // ─────────────────────────────────────────────────────────────
            _buildSectionHeader('/ 06 — VS COMMERCIAL', textMuted),
            const SizedBox(height: 8),
            Text(
              'OPEN BEATS\nCLOSED.',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'LAT trades a color TFT screen, cloud integration, and a battery for openness, cost, and full data ownership. For most indoor monitoring needs, that\'s the right trade.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textSecondary,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 14),

            _buildComparisonCard(
              surface: surface,
              border: border,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              textMuted: textMuted,
              rows: const [
                ('Price (USD)', '19.05', '30 – 50'),
                ('Microcontroller', 'ESP32-H2 Mini', 'Custom ASIC'),
                ('Sensors', 'ENS160 + ENS210', 'Multiple integrated'),
                ('eCO₂', '400 – 65,000 ppm', '0 – 5,000 ppm'),
                ('TVOC', '0 – 65,000 ppb', '0 – 9,999 mg/m³'),
                ('AQI', '1 – 5', '0 – 500'),
                ('PM2.5 / PM10', 'No', 'Yes'),
                ('HCHO / CO', 'No', 'Yes'),
                ('Output', 'Web Dashboard + RGB LED', '2.8" TFT + Buzzer'),
                ('Data Storage', 'SPIFFS (CSV, local)', 'Internal memory'),
                ('Cloud', 'None (local-first)', 'Tuya / SmartLife'),
                ('Open Hardware', 'Yes', 'No'),
                ('Open Firmware', 'Yes', 'No'),
                ('Easy to Recreate', 'Yes', 'No'),
                ('Customizable', 'Yes', 'No'),
              ],
            ),

            const SizedBox(height: 48),

            // ─────────────────────────────────────────────────────────────
            // Bottom Call-to-Action
            // ─────────────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(kRadiusCard),
                border: Border.all(color: border, width: kBorderWidth),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YOUR NEXT BUILD / 00:00:01',
                    style: AppTheme.monoStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ).copyWith(color: textMuted),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'DON\'T GUESS\nWHAT YOU BREATHE.',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                  ),
                  const SizedBox(height: 16),
                  DetaHubButton(
                    label: 'Connect this product',
                    icon: Icons.add,
                    expand: true,
                    onPressed: () => context.push('/add-device'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helper Widgets
  // ─────────────────────────────────────────────────────────────────────────

  static Widget _buildSectionHeader(String tag, Color color) {
    return Text(
      tag,
      style: AppTheme.monoStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ).copyWith(color: color),
    );
  }

  static Widget _buildTagChip(
      String label, Color bg, Color border, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(kRadiusChip),
        border: Border.all(color: border, width: kBorderWidth),
      ),
      child: Text(
        label,
        style: AppTheme.monoStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ).copyWith(color: text),
      ),
    );
  }

  static Widget _buildHeroStat(
      String label, String value, Color labelColor, Color valColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.monoStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ).copyWith(color: labelColor),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: AppTheme.monoStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ).copyWith(color: valColor),
        ),
      ],
    );
  }

  static Widget _buildContentCard({
    required Color surface,
    required Color border,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: border, width: kBorderWidth),
      ),
      child: child,
    );
  }

  static Widget _buildFeatureStepCard({
    required String index,
    required String title,
    required String description,
    required Color badgeColor,
    required Color surface,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: border, width: kBorderWidth),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(kRadiusChip),
              border: Border.all(
                  color: badgeColor.withValues(alpha: 0.3), width: 1),
            ),
            child: Text(
              index,
              style: AppTheme.monoStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ).copyWith(color: badgeColor),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildDualFlowCard({
    required String category,
    required String headline,
    required String summary,
    required List<(String, String)> steps,
    required Color surface,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: border, width: kBorderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category,
            style: AppTheme.monoStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ).copyWith(color: textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            headline,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            summary,
            style: TextStyle(
              fontSize: 13,
              color: textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ...steps.map((step) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      step.$1,
                      style: AppTheme.monoStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ).copyWith(color: textMuted),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      step.$2,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static Widget _buildSpecTableCard({
    required Color surface,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
    required List<(String, String, String)> specs,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: border, width: kBorderWidth),
      ),
      child: Column(
        children: specs.asMap().entries.map((entry) {
          final index = entry.key;
          final spec = entry.value;
          final isLast = index == specs.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spec.$1,
                      style: AppTheme.monoStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ).copyWith(color: textMuted),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            spec.$2,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            spec.$3,
                            style: AppTheme.monoStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ).copyWith(color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast) const Divider(height: 12),
            ],
          );
        }).toList(),
      ),
    );
  }

  static Widget _buildMetricTile({
    required String label,
    required String value,
    required String range,
    required Color color,
    required Color surface,
    required Color border,
    required Color textMuted,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: border, width: kBorderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTheme.monoStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ).copyWith(color: textMuted),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTheme.monoStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ).copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(
            range,
            style: AppTheme.monoStyle(
              fontSize: 10,
              fontWeight: FontWeight.w400,
            ).copyWith(color: textMuted),
          ),
        ],
      ),
    );
  }

  static Widget _buildAqiDistributionRow(String aqi, String status,
      String share, Color dotColor, Color textMuted) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          aqi,
          style: AppTheme.monoStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            status,
            style: TextStyle(
              fontSize: 12,
              color: textMuted,
            ),
          ),
        ),
        Text(
          share,
          style: AppTheme.monoStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ).copyWith(color: dotColor),
        ),
      ],
    );
  }

  static Widget _buildPollutionEventCard({
    required String tag,
    required String title,
    required String description,
    required String badge,
    required Color surface,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: border, width: kBorderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tag,
                style: AppTheme.monoStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ).copyWith(color: AppColors.aqiUnhealthy),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.aqiVeryUnhealthy.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(kRadiusChip),
                ),
                child: Text(
                  badge,
                  style: AppTheme.monoStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ).copyWith(color: AppColors.aqiVeryUnhealthy),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildComparisonCard({
    required Color surface,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
    required List<(String, String, String)> rows,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(color: border, width: kBorderWidth),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: textMuted.withValues(alpha: 0.08),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    'Feature',
                    style: AppTheme.monoStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ).copyWith(color: textMuted),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Text(
                    'LAT (Proposed)',
                    style: AppTheme.monoStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ).copyWith(color: AppColors.aqiGood),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    'Commercial',
                    style: AppTheme.monoStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ).copyWith(color: textMuted),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Table Rows
          ...rows.asMap().entries.map((entry) {
            final idx = entry.key;
            final row = entry.value;
            final isLast = idx == rows.length - 1;

            return Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Text(
                          row.$1,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: Text(
                          row.$2,
                          style: AppTheme.monoStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ).copyWith(
                            color: row.$2 == 'Yes'
                                ? AppColors.aqiGood
                                : textPrimary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          row.$3,
                          style: AppTheme.monoStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ).copyWith(
                            color: row.$3 == 'No' ? textMuted : textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast) const Divider(height: 1),
              ],
            );
          }),
        ],
      ),
    );
  }
}
