// lib/features/device/screens/device_form_screen.dart
//
// Form screen for registering a new Device Node.
// User enters a local address → taps "Test Connection".
// On success the Device ID and product type are auto-filled from the manifest.
// Tapping "Save" calls DeviceDao.upsertDevice().

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/network/network_error.dart';
import '../../../core/network/models/device_manifest.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/device_providers.dart';

class DeviceFormScreen extends ConsumerStatefulWidget {
  final int subSectorId;

  const DeviceFormScreen({super.key, required this.subSectorId});

  @override
  ConsumerState<DeviceFormScreen> createState() => _DeviceFormScreenState();
}

class _DeviceFormScreenState extends ConsumerState<DeviceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController(text: 'http://');
  final _nameController = TextEditingController();

  // Populated after a successful handshake
  DeviceManifest? _manifest;
  String? _handshakeError;
  bool _testing = false;
  bool _saving = false;

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Test Connection — `/api/manifest`, then `/data` for LAT test firmware.
  // ---------------------------------------------------------------------------

  Future<void> _testConnection() async {
    final url = _urlController.text.trim();
    if (url.isEmpty || url == 'http://') {
      setState(() => _handshakeError = 'Enter a valid device URL first.');
      return;
    }

    setState(() {
      _testing = true;
      _handshakeError = null;
      _manifest = null;
    });

    // Invalidate cached provider to force a fresh request.
    ref.invalidate(deviceHandshakeProvider(url));
    final result = await ref.read(deviceHandshakeProvider(url).future);

    if (!mounted) return;

    result.when(
      ok: (manifest) {
        setState(() {
          _manifest = manifest;
          // Auto-fill display name if empty
          if (_nameController.text.isEmpty) {
            _nameController.text = manifest.deviceId;
          }
        });
      },
      err: (error) {
        setState(() {
          _handshakeError = _errorMessage(error);
        });
      },
    );

    setState(() => _testing = false);
  }

  String _errorMessage(NetworkError error) => switch (error) {
        TimeoutError() =>
          'No response within 5s. Check the device URL and Wi-Fi network.',
        UnreachableError() =>
          'Cannot reach device. Verify the IP address and that the device is powered on.',
        NotFoundError() =>
          'Device data was not found. Check the local address and Wi-Fi network.',
        ParseError(:final detail) => 'Unexpected response format: $detail',
        UnknownNetworkError(:final cause) => 'Error: $cause',
      };

  // ---------------------------------------------------------------------------
  // Save — upsert device into DB
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_manifest == null) {
      setState(() => _handshakeError = 'Test connection first.');
      return;
    }

    setState(() => _saving = true);

    await ref.read(deviceMutationProvider.notifier).upsertDevice(
          DevicesCompanion.insert(
            id: _manifest!.deviceId,
            name: _nameController.text.trim(),
            baseUrl: _urlController.text.trim(),
            productType: _manifest!.productType,
            subSectorId: widget.subSectorId,
            lastSeenAt: Value(DateTime.now()),
          ),
        );

    if (mounted) {
      setState(() => _saving = false);
      context.pop();
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.textMutedDark : AppColors.textMuted;
    final textTheme = Theme.of(context).textTheme;

    final canSave = _manifest != null && !_saving && !_testing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Device'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: canSave ? _save : null,
            child: const Text('Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // --- Section: Connection ---
            const _SectionHeader(label: 'CONNECTION'),
            const SizedBox(height: 10),

            TextFormField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Device Address',
                hintText: 'http://192.168.1.50',
                helperText: 'Enter the local address shown by the device.',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty || v.trim() == 'http://') {
                  return 'Enter the device IP address.';
                }
                return null;
              },
            ),

            const SizedBox(height: 12),

            // Test Connection button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _testing ? null : _testConnection,
                child: _testing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: mutedColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Testing...'),
                        ],
                      )
                    : const Text('Test Connection'),
              ),
            ),

            // Error message
            if (_handshakeError != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.aqiPoor.withValues(alpha: 0.08),
                  border: Border.all(color: AppColors.aqiPoor, width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _handshakeError!,
                  style:
                      textTheme.bodySmall?.copyWith(color: AppColors.aqiPoor),
                ),
              ),
            ],

            // Manifest success block
            if (_manifest != null) ...[
              const SizedBox(height: 12),
              _ManifestPreview(manifest: _manifest!),
            ],

            const SizedBox(height: 28),

            // --- Section: Display ---
            const _SectionHeader(label: 'DISPLAY'),
            const SizedBox(height: 10),

            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                hintText: 'e.g. LAT Lab IoT Lt.3',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Name cannot be empty.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Supporting widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.textMutedDark : AppColors.textMuted;

    return Text(
      label,
      style: AppTheme.monoStyle(fontSize: 10, fontWeight: FontWeight.w600)
          .copyWith(color: mutedColor, letterSpacing: 1.5),
    );
  }
}

class _ManifestPreview extends StatelessWidget {
  final DeviceManifest manifest;

  const _ManifestPreview({required this.manifest});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.aqiExcellent.withValues(alpha: 0.06),
        border: Border.all(color: AppColors.aqiExcellent, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DEVICE FOUND',
            style: AppTheme.monoStyle(fontSize: 9, fontWeight: FontWeight.w700)
                .copyWith(color: AppColors.aqiExcellent, letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
          _ManifestRow(label: 'ID', value: manifest.deviceId),
          _ManifestRow(label: 'Type', value: manifest.productType),
          _ManifestRow(label: 'Firmware', value: manifest.firmwareVersion),
          _ManifestRow(label: 'Metrics', value: manifest.metrics.join(', ')),
        ],
      ),
    );
  }
}

class _ManifestRow extends StatelessWidget {
  final String label;
  final String value;

  const _ManifestRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.textMutedDark : AppColors.textMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: mutedColor),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.monoStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Result extension for cleaner pattern matching
// ---------------------------------------------------------------------------

extension ResultX<T, E> on Result<T, E> {
  void when({
    required void Function(T value) ok,
    required void Function(E error) err,
  }) {
    if (this is Ok<T, E>) {
      ok((this as Ok<T, E>).value);
    } else {
      err((this as Err<T, E>).error);
    }
  }
}
