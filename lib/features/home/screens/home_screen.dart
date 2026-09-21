import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/daos/sector_dao.dart';
import '../../../core/database/app_database.dart' show Sector;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/connection_pill.dart';
import '../../../core/widgets/detahub_brand.dart';
import '../../../core/widgets/detahub_button.dart';
import '../../../core/widgets/detahub_section_header.dart';
import '../../device/providers/device_providers.dart';
import '../../sector/providers/sector_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int? _selectedLocation;
  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(watchAllDevicesWithLocationProvider);
    final locations = ref.watch(watchAllSectorsProvider);
    final secondary = Theme.of(context).brightness == Brightness.dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
    return Scaffold(
        body: SafeArea(
            bottom: false,
            child: devices.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                  child: Text('We couldn’t load your devices.\n$error',
                      textAlign: TextAlign.center)),
              data: (all) {
                final filtered = _selectedLocation == null
                    ? all
                    : all
                        .where((it) => it.sectorId == _selectedLocation)
                        .toList();
                final locationList = locations.valueOrNull ?? const <Sector>[];
                return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 116),
                    children: [
                      DetaHubHeader(
                          action: DetaHubIconButton(
                              icon: Icons.add,
                              tooltip: 'Add device',
                              onPressed: () => context.push('/add-device'))),
                      const SizedBox(height: 28),
                      Text('Good evening,',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(color: secondary)),
                      const SizedBox(height: 2),
                      Text('Adrian',
                          style: Theme.of(context).textTheme.displayMedium),
                      const SizedBox(height: 8),
                      Text("Here’s your connected devices",
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: secondary)),
                      const SizedBox(height: 20),
                      DetaHubButton(
                          label: 'Add device',
                          icon: Icons.add,
                          onPressed: () => context.push('/add-device')),
                      const SizedBox(height: 32),
                      if (locationList.length > 1) ...[
                        _LocationFilters(
                            locations: locationList,
                            selected: _selectedLocation,
                            onSelect: (id) =>
                                setState(() => _selectedLocation = id)),
                        const SizedBox(height: 26)
                      ],
                      DetaHubSectionHeader(
                          title: 'Connected devices',
                          trailing:
                              '${filtered.length} device${filtered.length == 1 ? '' : 's'}'),
                      const SizedBox(height: 14),
                      if (filtered.isEmpty)
                        _EmptyDevices(hasDevices: all.isNotEmpty)
                      else
                        ...filtered.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _DeviceCard(item: item))),
                      if (all.isNotEmpty &&
                          _selectedLocation == null &&
                          locationList.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _LocationSummary(locations: locationList)
                      ],
                    ]);
              },
            )));
  }
}

class _LocationFilters extends StatelessWidget {
  final List<Sector> locations;
  final int? selected;
  final ValueChanged<int?> onSelect;
  const _LocationFilters(
      {required this.locations,
      required this.selected,
      required this.onSelect});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        _filter(
            context, 'All locations', selected == null, () => onSelect(null)),
        ...locations.map((l) => Padding(
            padding: const EdgeInsets.only(left: 8),
            child: _filter(
                context, l.name, selected == l.id, () => onSelect(l.id))))
      ]));
  Widget _filter(
      BuildContext context, String label, bool active, VoidCallback tap) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
        color: active
            ? (dark ? AppColors.accentSoftDark : AppColors.accentSoft)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
            onTap: tap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                decoration: BoxDecoration(
                    border: Border.all(
                        color: active
                            ? (dark ? AppColors.accentDark : AppColors.accent)
                            : (dark ? AppColors.borderDark : AppColors.border)),
                    borderRadius: BorderRadius.circular(14)),
                child: Text(label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight:
                            active ? FontWeight.w700 : FontWeight.w500)))));
  }
}

class _DeviceCard extends ConsumerWidget {
  final DeviceWithLocation item;
  const _DeviceCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        dark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final muted = dark ? AppColors.textMutedDark : AppColors.textMuted;
    final device = item.device;

    final latest =
        ref.watch(watchLatestTelemetryRecordProvider(device.id)).valueOrNull;

    final isRecentlySeen = device.lastSeenAt != null &&
        DateTime.now().difference(device.lastSeenAt!).inSeconds < 15;
    final connectionStatus = device.lastSeenAt == null
        ? ConnectionStatus.unknown
        : (isRecentlySeen ? ConnectionStatus.online : ConnectionStatus.offline);

    final aqiStr = latest?.aqi?.toString() ?? '--';
    final aqiNote =
        latest?.aqi != null ? AppColors.labelForAqi(latest!.aqi!) : null;
    final tempStr = latest?.temperature != null
        ? '${latest!.temperature!.toStringAsFixed(1)} °C'
        : '-- °C';
    final humStr = latest?.humidity != null
        ? '${latest!.humidity!.toStringAsFixed(1)} %'
        : '-- %';

    return Material(
        color: dark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(kRadiusCard),
        child: InkWell(
            onTap: () => context.push('/devices/${device.id}'),
            borderRadius: BorderRadius.circular(kRadiusCard),
            child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                    border: Border.all(
                        color: dark
                            ? AppColors.borderDark
                            : AppColors.borderSubtle),
                    borderRadius: BorderRadius.circular(kRadiusCard),
                    boxShadow: [
                      BoxShadow(
                          color:
                              Colors.black.withValues(alpha: dark ? .12 : .025),
                          blurRadius: 18,
                          offset: const Offset(0, 7))
                    ]),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ProductPlaceholder(),
                            const SizedBox(width: 13),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(device.id.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTheme.monoStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: muted,
                                          letterSpacing: .2)),
                                  const SizedBox(height: 3),
                                  Text(device.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge),
                                  const SizedBox(height: 3),
                                  Text('Lightweight Air Tester',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: secondary)),
                                  const SizedBox(height: 7),
                                  Text(
                                      '${item.locationName} · ${item.areaName}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: secondary))
                                ])),
                            const SizedBox(width: 8),
                            ConnectionPill(status: connectionStatus),
                          ]),
                      const SizedBox(height: 20),
                      Row(children: [
                        _Metric(label: 'AQI', value: aqiStr, note: aqiNote),
                        _Metric(label: 'Temperature', value: tempStr),
                        _Metric(label: 'Humidity', value: humStr),
                      ]),
                      const SizedBox(height: 14),
                      Divider(
                        height: 1,
                        color: dark
                            ? AppColors.borderDark
                            : AppColors.borderSubtle,
                      ),
                      const SizedBox(height: 10),
                      Row(children: [
                        Text(
                          latest?.timestamp != null
                              ? 'Last update: ${_formatTime(latest!.timestamp)}'
                              : 'Waiting for first reading',
                          style: AppTheme.monoStyle(fontSize: 10, color: muted),
                        ),
                        const Spacer(),
                        Icon(Icons.arrow_forward, size: 14, color: muted),
                      ]),
                    ]))));
  }

  String _formatTime(DateTime timestamp) {
    final local = timestamp.toLocal();
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(local.hour)}:${twoDigits(local.minute)}:${twoDigits(local.second)}';
  }
}

class _ProductPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 54,
      height: 54,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: dark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Image.asset(
        'assets/images/LAT.webp',
        fit: BoxFit.contain,
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label, value;
  final String? note;
  const _Metric({required this.label, required this.value, this.note});
  @override
  Widget build(BuildContext c) {
    final secondary = Theme.of(c).brightness == Brightness.dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
    return Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: Theme.of(c).textTheme.labelSmall?.copyWith(color: secondary)),
      const SizedBox(height: 3),
      Text(value,
          style: AppTheme.monoStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      if (note != null)
        Text(note!,
            style: Theme.of(c).textTheme.labelSmall?.copyWith(
                color: AppColors.aqiGood, fontWeight: FontWeight.w700))
    ]));
  }
}

class _EmptyDevices extends StatelessWidget {
  final bool hasDevices;
  const _EmptyDevices({required this.hasDevices});
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        dark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
            color: dark ? AppColors.surfaceDark : AppColors.surface,
            borderRadius: BorderRadius.circular(kRadiusCard)),
        child: Column(children: [
          _ProductPlaceholder(),
          const SizedBox(height: 16),
          Text(
              hasDevices
                  ? 'No devices here yet'
                  : 'Your first device is waiting',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
              hasDevices
                  ? 'Choose another location or add a device to this one.'
                  : 'Bring your environment into view in a few simple steps.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: secondary)),
          const SizedBox(height: 18),
          DetaHubButton(
              label: 'Add device',
              icon: Icons.add,
              onPressed: () => context.push('/add-device'))
        ]));
  }
}

class _LocationSummary extends StatelessWidget {
  final List<Sector> locations;
  const _LocationSummary({required this.locations});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 16),
        const DetaHubSectionHeader(title: 'Your locations'),
        const SizedBox(height: 12),
        ...locations.map((location) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.surfaceDark
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    onTap: () => context.go('/locations'),
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(children: [
                          const Icon(Icons.location_on_outlined, size: 19),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(location.name,
                                  style:
                                      Theme.of(context).textTheme.titleMedium)),
                          const Icon(Icons.chevron_right, size: 18),
                        ])),
                  )),
            )),
      ]);
}
