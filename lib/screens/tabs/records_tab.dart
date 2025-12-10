import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/landmark_controller.dart';
import '../../models/landmark.dart';
import '../../widgets/landmark_card.dart';

class RecordsTab extends StatelessWidget {
  const RecordsTab({super.key, required this.onEdit, required this.onAddNew});

  final ValueChanged<Landmark> onEdit;
  final VoidCallback onAddNew;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LandmarkController>();
    if (controller.isLoading && controller.landmarks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.landmarks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No landmarks yet'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onAddNew,
              icon: const Icon(Icons.add),
              label: const Text('Add your first landmark'),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: controller.fetchLandmarks,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: controller.landmarks.length,
        itemBuilder: (context, index) {
          final landmark = controller.landmarks[index];
          return Dismissible(
            key: ValueKey(landmark.id),
            background: _swipeBackground(
              context,
              icon: Icons.edit,
              color: Colors.blueGrey,
              alignment: Alignment.centerLeft,
            ),
            secondaryBackground: _swipeBackground(
              context,
              icon: Icons.delete,
              color: Colors.redAccent,
              alignment: Alignment.centerRight,
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                onEdit(landmark);
                return false;
              } else {
                await _confirmDelete(context, landmark);
                return false;
              }
            },
            child: LandmarkCard(
              landmark: landmark,
              onEdit: () => onEdit(landmark),
              onDelete: () {
                _confirmDelete(context, landmark);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _swipeBackground(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required Alignment alignment,
  }) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: color.withValues(alpha: 0.2),
      child: Icon(icon, color: color),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, Landmark landmark) async {
    final controller = context.read<LandmarkController>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete landmark'),
        content: Text('Remove ${landmark.title}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!context.mounted) return false;
    if (confirm != true) return false;
    final success = await controller.removeLandmark(landmark.id);
    if (!context.mounted) {
      return success;
    }
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.errorMessage ?? 'Unable to delete ${landmark.title}',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Deleted ${landmark.title}')));
    }
    return success;
  }
}
