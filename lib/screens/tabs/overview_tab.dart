import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../controllers/landmark_controller.dart';
import '../../models/landmark.dart';
import '../../widgets/landmark_bottom_sheet.dart';

class OverviewTab extends StatefulWidget {
  const OverviewTab({super.key, required this.onEdit});

  final ValueChanged<Landmark> onEdit;

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  final MapController _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LandmarkController>();
    if (controller.isLoading && controller.landmarks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (controller.errorMessage != null && controller.landmarks.isEmpty) {
      return Center(
        child: Text(
          controller.errorMessage!,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(23.6850, 90.3563),
            initialZoom: 6.4,
            backgroundColor: Colors.transparent,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'mid23141010',
            ),
            MarkerLayer(
              markers: [
                for (final landmark in controller.landmarks)
                  Marker(
                    point: LatLng(landmark.lat, landmark.lon),
                    width: 120,
                    height: 90,
                    child: GestureDetector(
                      onTap: () => _showDetails(
                        context,
                        controller,
                        landmark,
                        widget.onEdit,
                      ),
                      child: _MapMarker(title: landmark.title),
                    ),
                  ),
              ],
            ),
          ],
        ),
        Positioned(
          right: 16,
          top: 16,
          child: ElevatedButton.icon(
            onPressed: () => controller.fetchLandmarks(),
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 32,
          child: Column(
            children: [
              _ZoomButton(
                icon: Icons.add,
                tooltip: 'Zoom in',
                onPressed: () => _zoomBy(1),
              ),
              const SizedBox(height: 12),
              _ZoomButton(
                icon: Icons.remove,
                tooltip: 'Zoom out',
                onPressed: () => _zoomBy(-1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _zoomBy(double delta) {
    final camera = _mapController.camera;
    final targetZoom = (camera.zoom + delta).clamp(3.0, 18.0);
    _mapController.move(camera.center, targetZoom);
  }

  Future<void> _showDetails(
    BuildContext context,
    LandmarkController controller,
    Landmark landmark,
    ValueChanged<Landmark> onEdit,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => LandmarkBottomSheet(
        landmark: landmark,
        onEdit: () {
          Navigator.of(context).pop();
          onEdit(landmark);
        },
        onDelete: () async {
          Navigator.of(context).pop();
          final success = await controller.removeLandmark(landmark.id);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Deleted ${landmark.title}'
                    : controller.errorMessage ?? 'Failed to delete',
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 110),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const Icon(Icons.location_on, size: 32, color: Colors.redAccent),
      ],
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: const CircleBorder(),
      elevation: 3,
      child: IconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
