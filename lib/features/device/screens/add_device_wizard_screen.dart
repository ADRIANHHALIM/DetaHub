// lib/features/device/screens/add_device_wizard_screen.dart
//
// User-Centric 5-Step Guided Setup Wizard (GitHub Issue #2).
// Flow:
// 1. What are you connecting?
// 2. Connect your device (search local network / enter address)
// 3. Device found!
// 4. Where should we put it? (Location, Area, Device Name)
// 5. You're all set!

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/device_dao.dart';
import '../../../core/network/models/device_manifest.dart';
import '../../../core/network/network_error.dart';
import '../../../core/network/providers/network_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/detahub_brand.dart';
import '../../../core/widgets/detahub_button.dart';
import '../../sector/providers/sector_providers.dart';
import 'device_form_screen.dart'; // for ResultX extension

enum WizardStep { selectProduct, connect, found, placement, completed }

class AddDeviceWizardScreen extends ConsumerStatefulWidget {
  const AddDeviceWizardScreen({super.key});

  @override
  ConsumerState<AddDeviceWizardScreen> createState() =>
      _AddDeviceWizardScreenState();
}

class _AddDeviceWizardScreenState extends ConsumerState<AddDeviceWizardScreen> {
  WizardStep _step = WizardStep.selectProduct;

  // Selected product
  String _productName = 'Lightweight Air Tester';
  String _productType = 'LAT_ENS160';

  // Connection
  final _addressController = TextEditingController();
  bool _searching = false;
  String? _connectError;
  DeviceManifest? _discoveredManifest;
  String _finalUrl = '';

  // Placement
  final _deviceNameController =
      TextEditingController(text: 'Lightweight Air Tester');
  int? _selectedSectorId;
  int? _selectedSubSectorId;
  bool _saving = false;
  String? _savedDeviceId;

  @override
  void dispose() {
    _addressController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Step 2: Connect logic
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _attemptConnection(String inputAddress) async {
    String address = inputAddress.trim();
    if (address.isEmpty) {
      setState(() => _connectError = 'Please enter a device address or IP.');
      return;
    }

    if (!address.startsWith('http://') && !address.startsWith('https://')) {
      address = 'http://$address';
    }

    setState(() {
      _searching = true;
      _connectError = null;
    });

    final api = ref.read(deviceApiServiceProvider);
    final result = await api.fetchManifest(address);

    if (!mounted) return;

    result.when(
      ok: (manifest) {
        setState(() {
          _discoveredManifest = manifest;
          _finalUrl = address;
          _productType = manifest.productType;
          _searching = false;
          _step = WizardStep.found;
        });
      },
      err: (err) {
        setState(() {
          _searching = false;
          _connectError = _readableError(err);
        });
      },
    );
  }

  String _readableError(NetworkError error) => switch (error) {
        TimeoutError() ||
        UnreachableError() =>
          'Device tidak dapat dihubungi. Pastikan ponsel dan perangkat berada di jaringan Wi-Fi yang sama.',
        NotFoundError() =>
          'Endpoint data perangkat tidak ditemukan. Periksa kembali alamat lokal perangkat.',
        ParseError() =>
          'Data dari perangkat tidak dapat dibaca. Format respons tidak sesuai.',
        UnknownNetworkError() =>
          'Koneksi ke perangkat gagal. Silakan periksa jaringan Wi-Fi dan coba lagi.',
      };

  // ─────────────────────────────────────────────────────────────────────────
  // Step 4: Save Device to Location & Area
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _saveDevice() async {
    final name = _deviceNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name for your device.')),
      );
      return;
    }

    if (_selectedSubSectorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an Area for your device.')),
      );
      return;
    }

    setState(() => _saving = true);

    final deviceDao = ref.read(deviceDaoProvider);
    final deviceId = _discoveredManifest?.deviceId ??
        'lat-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    _savedDeviceId = deviceId;

    await deviceDao.upsertDevice(
      DevicesCompanion.insert(
        id: deviceId,
        subSectorId: _selectedSubSectorId!,
        name: name,
        baseUrl: _finalUrl.isNotEmpty ? _finalUrl : 'http://192.168.1.50',
        productType: _productType,
        createdAt: Value(DateTime.now()),
        lastSeenAt: Value(DateTime.now()),
      ),
    );

    if (!mounted) return;
    setState(() {
      _saving = false;
      _step = WizardStep.completed;
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UI Builder
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 20, 0),
              child: Row(children: [
                DetaHubIconButton(
                    icon: Icons.close,
                    tooltip: 'Close',
                    onPressed: () => context.pop()),
                const SizedBox(width: 10),
                Expanded(
                    child: Text('Add a device',
                        style: Theme.of(context).textTheme.titleLarge)),
                Text('${_step.index + 1} of 5',
                    style: Theme.of(context).textTheme.labelMedium),
              ])),
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: LinearProgressIndicator(
                  value: (_step.index + 1) / 5,
                  minHeight: 3,
                  borderRadius: BorderRadius.circular(2))),
          Expanded(
              child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                    position: Tween<Offset>(
                            begin: const Offset(.04, 0), end: Offset.zero)
                        .animate(CurvedAnimation(
                            parent: animation,
                            curve: const Cubic(.2, .75, .25, 1))),
                    child: child)),
            child: switch (_step) {
              WizardStep.selectProduct => _buildStepSelectProduct(),
              WizardStep.connect => _buildStepConnect(),
              WizardStep.found => _buildStepFound(),
              WizardStep.placement => _buildStepPlacement(),
              WizardStep.completed => _buildStepCompleted(),
            },
          )),
        ]),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 1. What are you connecting?
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStepSelectProduct() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final surfaceVariant =
        isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'What are you connecting?',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'Choose the DetaLab device you’d like to bring into DetaHub.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: textSecondary),
        ),
        const SizedBox(height: 24),

        // Product Card: Lightweight Air Tester
        InkWell(
          onTap: () {
            setState(() {
              _productName = 'Lightweight Air Tester';
              _productType = 'LAT_ENS160';
              _step = WizardStep.connect;
            });
          },
          borderRadius: BorderRadius.circular(kRadiusCard),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(kRadiusCard),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: surfaceVariant,
                    borderRadius: BorderRadius.circular(kRadiusChip),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Image.asset(
                    'assets/images/LAT.webp',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lightweight Air Tester',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Air quality (eCO₂, TVOC), temperature & relative humidity monitor',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right,
                    size: 20, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. Connect your device
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStepConnect() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Connect your device',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'Make sure your $_productName is powered on and connected to your local Wi-Fi.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: textSecondary),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(kRadiusCard),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Device Address',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Enter the local address shown by the device.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: textSecondary),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  hintText: 'e.g. 192.168.4.1 or lat.local',
                ),
                keyboardType: TextInputType.url,
                autocorrect: false,
                onSubmitted: (_) {
                  if (!_searching) _attemptConnection(_addressController.text);
                },
              ),
              const SizedBox(height: 16),
              DetaHubButton(
                label: _searching ? 'Testing connection…' : 'Test connection',
                icon: Icons.sensors_outlined,
                expand: true,
                onPressed: _searching
                    ? null
                    : () => _attemptConnection(_addressController.text),
              ),
            ],
          ),
        ),
        if (_connectError != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.aqiPoor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(kRadiusChip),
              border: Border.all(color: AppColors.aqiPoor, width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    size: 18, color: AppColors.aqiPoor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _connectError!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.aqiPoor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. Device found!
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStepFound() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 20),
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.aqiGood.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.aqiGood, width: 2),
            ),
            child: const Icon(Icons.check, size: 36, color: AppColors.aqiGood),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            'Device found!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            'Successfully communicated with your $_productName.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: textSecondary),
          ),
        ),
        const SizedBox(height: 32),

        // Device Confirmation Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(kRadiusCard),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR DEVICE',
                style: AppTheme.monoStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              _infoRow('Model', _productName),
              _infoRow('ID', _discoveredManifest?.deviceId ?? '—'),
              _infoRow('Measures', 'Air quality, temperature, humidity'),
            ],
          ),
        ),

        const SizedBox(height: 32),
        DetaHubButton(
            label: 'Continue',
            expand: true,
            onPressed: () {
              setState(() {
                _deviceNameController.text = _productName;
                _step = WizardStep.placement;
              });
            }),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 4. Where should we put it?
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStepPlacement() {
    final hierarchyAsync = ref.watch(watchFullHierarchyProvider);
    final textSecondary = Theme.of(context).brightness == Brightness.dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    return hierarchyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading locations: $e')),
      data: (hierarchy) {
        // Auto-select first Sector & SubSector if not selected
        if (_selectedSectorId == null && hierarchy.isNotEmpty) {
          _selectedSectorId = hierarchy.first.sector.id;
          if (hierarchy.first.subSectors.isNotEmpty) {
            _selectedSubSectorId =
                hierarchy.first.subSectors.first.subSector.id;
          }
        }

        final selectedSector = hierarchy
            .where((s) => s.sector.id == _selectedSectorId)
            .firstOrNull;
        final availableSubSectors = selectedSector?.subSectors ?? [];

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Where should we put it?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Assign a friendly name and organization location for this device.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: textSecondary),
            ),
            const SizedBox(height: 24),

            // Device Name
            Text(
              'DEVICE NAME',
              style: AppTheme.monoStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _deviceNameController,
              decoration: const InputDecoration(
                hintText: 'e.g. Desk LAT, Lab IoT Front',
              ),
            ),
            const SizedBox(height: 24),

            // Location (Sector)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'LOCATION',
                  style: AppTheme.monoStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
                TextButton(
                  onPressed: () => _promptNewLocation(context),
                  child: const Text('+ New Location'),
                ),
              ],
            ),
            const SizedBox(height: 4),

            if (hierarchy.isEmpty)
              OutlinedButton.icon(
                onPressed: () => _promptNewLocation(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Location (e.g. Universitas Trisakti)'),
              )
            else
              DropdownButtonFormField<int>(
                value: _selectedSectorId,
                decoration: const InputDecoration(),
                items: hierarchy.map((item) {
                  return DropdownMenuItem<int>(
                    value: item.sector.id,
                    child: Text(item.sector.name),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedSectorId = val;
                    final s =
                        hierarchy.where((x) => x.sector.id == val).firstOrNull;
                    _selectedSubSectorId =
                        s?.subSectors.firstOrNull?.subSector.id;
                  });
                },
              ),

            const SizedBox(height: 20),

            // Area (SubSector)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AREA',
                  style: AppTheme.monoStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
                if (_selectedSectorId != null)
                  TextButton(
                    onPressed: () =>
                        _promptNewArea(context, _selectedSectorId!),
                    child: const Text('+ New Area'),
                  ),
              ],
            ),
            const SizedBox(height: 4),

            if (availableSubSectors.isEmpty)
              OutlinedButton.icon(
                onPressed: _selectedSectorId == null
                    ? null
                    : () => _promptNewArea(context, _selectedSectorId!),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Area (e.g. Lab IoT, Ruang Server)'),
              )
            else
              DropdownButtonFormField<int>(
                value: _selectedSubSectorId,
                decoration: const InputDecoration(),
                items: availableSubSectors.map((sub) {
                  return DropdownMenuItem<int>(
                    value: sub.subSector.id,
                    child: Text(sub.subSector.name),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedSubSectorId = val);
                },
              ),

            const SizedBox(height: 36),

            DetaHubButton(
                label: _saving ? 'Saving device…' : 'Save & finish',
                expand: true,
                onPressed: _saving ? null : _saveDevice),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 5. You're all set!
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStepCompleted() {
    final textSecondary = Theme.of(context).brightness == Brightness.dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.aqiGood.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.aqiGood, width: 2),
            ),
            child: const Icon(Icons.check, size: 40, color: AppColors.aqiGood),
          ),
          const SizedBox(height: 24),
          Text(
            "You're all set!",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Your device is paired and ready. Telemetry data is now being stored locally on your device.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textSecondary,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: DetaHubButton(
                label: 'View device',
                expand: true,
                onPressed: () {
                  final deviceId =
                      _savedDeviceId ?? _discoveredManifest?.deviceId;
                  if (deviceId != null) {
                    context.go('/devices/$deviceId');
                  } else {
                    context.go('/home');
                  }
                }),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: DetaHubButton(
                label: 'Done',
                outlined: true,
                expand: true,
                onPressed: () => context.go('/home')),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            value,
            style:
                AppTheme.monoStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // Quick prompt dialogs for on-the-fly Location/Area creation
  Future<void> _promptNewLocation(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Location'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
              hintText: 'e.g. Universitas Trisakti, Home'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      await ref.read(sectorMutationProvider.notifier).addSector(name);
    }
  }

  Future<void> _promptNewArea(BuildContext context, int sectorId) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Area'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
              hintText: 'e.g. Lab IoT, Ruang Server, Lt. 3'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      await ref
          .read(subSectorMutationProvider.notifier)
          .addSubSector(sectorId, name);
    }
  }
}
