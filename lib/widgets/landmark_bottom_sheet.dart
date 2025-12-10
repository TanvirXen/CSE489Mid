import 'package:flutter/material.dart';

import '../models/landmark.dart';

class LandmarkBottomSheet extends StatelessWidget {
  const LandmarkBottomSheet({
    super.key,
    required this.landmark,
    this.onEdit,
    this.onDelete,
  });

  final Landmark landmark;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  landmark.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: landmark.imageUrl.isNotEmpty
                ? Image.network(
                    landmark.imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _sheetPlaceholder(context),
                  )
                : _sheetPlaceholder(context),
          ),
          const SizedBox(height: 12),
          Text(
            'Location',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(letterSpacing: 1.1),
          ),
          const SizedBox(height: 4),
          Text(landmark.latLonLabel),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  onPressed: onEdit,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                  onPressed: onDelete,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sheetPlaceholder(BuildContext context) {
    return Container(
      height: 180,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: const Icon(Icons.landscape_outlined, size: 48),
    );
  }
}
