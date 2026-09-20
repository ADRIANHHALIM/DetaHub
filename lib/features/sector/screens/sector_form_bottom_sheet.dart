// lib/features/sector/screens/sector_form_bottom_sheet.dart
//
// Reusable modal bottom sheet for adding a Sector or Sub-Sector.
// A single TextFormField with validation and Save/Cancel actions.

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// A bottom sheet form for naming a new Sector or Sub-Sector.
///
/// [title] — sheet header text ("Add Sector" / "Add Sub-Sector")
/// [hint]  — placeholder text in the input field
/// [onSave] — async callback with the validated name; sheet closes on completion
class SectorFormBottomSheet extends StatefulWidget {
  final String title;
  final String hint;
  final Future<void> Function(String name) onSave;

  const SectorFormBottomSheet({
    super.key,
    required this.title,
    required this.hint,
    required this.onSave,
  });

  @override
  State<SectorFormBottomSheet> createState() => _SectorFormBottomSheetState();
}

class _SectorFormBottomSheetState extends State<SectorFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(_controller.text.trim());
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Respect keyboard inset so the form stays above the keyboard.
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(widget.title,
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),

            // Name field
            TextFormField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              maxLength: 128,
              decoration: InputDecoration(
                hintText: widget.hint,
                counterText: '', // hide the default character counter
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Name cannot be empty.';
                }
                if (v.trim().length > 128) {
                  return 'Max 128 characters.';
                }
                return null;
              },
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 20),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
