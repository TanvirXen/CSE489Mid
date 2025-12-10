import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../controllers/landmark_controller.dart';
import '../../models/landmark.dart';
import '../../utils/image_resizer.dart';
import '../../utils/location_helper.dart';

class EntryTab extends StatefulWidget {
  const EntryTab({super.key, required this.onCompleted});

  final VoidCallback onCompleted;

  @override
  State<EntryTab> createState() => _EntryTabState();
}

class _EntryTabState extends State<EntryTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  final _picker = ImagePicker();

  Uint8List? _image;
  bool _locating = false;

  @override
  void dispose() {
    _titleController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  void _hydrate(LandmarkDraft draft) {
    if (_titleController.text != draft.title) {
      _titleController.text = draft.title;
    }
    final latText = draft.lat?.toStringAsFixed(5) ?? '';
    if (_latController.text != latText) {
      _latController.text = latText;
    }
    final lonText = draft.lon?.toStringAsFixed(5) ?? '';
    if (_lonController.text != lonText) {
      _lonController.text = lonText;
    }
    if (draft.imageBytes != null && _image != draft.imageBytes) {
      _image = draft.imageBytes;
    } else if (draft.imageBytes == null &&
        draft.existingImageUrl == null &&
        _image != null) {
      _image = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LandmarkController>();
    final draft = controller.draft;
    _hydrate(draft);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  controller.isEditing ? 'Update landmark' : 'New landmark',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    controller.resetDraft();
                    _clearFormFields();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    signed: true,
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Latitude',
                                prefixIcon: Icon(Icons.my_location),
                              ),
                              validator: (value) =>
                                  _validateCoordinate(value, 'latitude'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _lonController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    signed: true,
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Longitude',
                                prefixIcon: Icon(Icons.explore_outlined),
                              ),
                              validator: (value) =>
                                  _validateCoordinate(value, 'longitude'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _locating
                                  ? null
                                  : () => _useCurrentLocation(),
                              icon: _locating
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.gps_fixed),
                              label: const Text('Use current location'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickImage(),
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Select image'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildPreview(context, draft),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: Icon(
                            controller.isEditing
                                ? Icons.save
                                : Icons.cloud_upload,
                          ),
                          label: Text(
                            controller.isEditing
                                ? 'Update record'
                                : 'Create record',
                          ),
                          onPressed: controller.isLoading
                              ? null
                              : () => _submit(controller),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context, LandmarkDraft draft) {
    Widget content;
    if (_image != null) {
      content = Image.memory(
        _image!,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else if ((draft.existingImageUrl ?? '').isNotEmpty) {
      content = Image.network(
        draft.existingImageUrl!,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholder(context),
      );
    } else {
      content = _placeholder(context);
    }
    return ClipRRect(borderRadius: BorderRadius.circular(16), child: content);
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      height: 180,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: const Text('No image selected'),
    );
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final resized = await resizeImage(bytes);
    if (resized == null || !mounted) return;
    setState(() {
      _image = resized;
    });
    context.read<LandmarkController>().updateDraftImage(
      resized,
      fileName: picked.name,
    );
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final position = await resolveCurrentPosition();
      if (!mounted) return;
      _latController.text = position.latitude.toStringAsFixed(5);
      _lonController.text = position.longitude.toStringAsFixed(5);
      context.read<LandmarkController>().updateDraft(
        lat: position.latitude,
        lon: position.longitude,
      );
    } catch (error) {
      if (mounted) {
        _showError(error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _locating = false);
      }
    }
  }

  Future<void> _submit(LandmarkController controller) async {
    if (_formKey.currentState?.validate() != true) return;
    final lat = double.tryParse(_latController.text.trim());
    final lon = double.tryParse(_lonController.text.trim());
    controller.updateDraft(
      title: _titleController.text.trim(),
      lat: lat,
      lon: lon,
    );
    final success = await controller.saveDraft();
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved successfully')));
      widget.onCompleted();
      _clearFormFields();
    } else if (controller.errorMessage != null) {
      _showError(controller.errorMessage!);
    }
  }

  void _clearFormFields() {
    setState(() {
      _image = null;
      _titleController.clear();
      _latController.clear();
      _lonController.clear();
    });
  }

  void _showError(String message) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Something went wrong'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String? _validateCoordinate(String? value, String label) {
    if (value == null || value.isEmpty) {
      return 'Enter $label';
    }
    final parsed = double.tryParse(value);
    if (parsed == null) {
      return 'Invalid $label';
    }
    return null;
  }
}
