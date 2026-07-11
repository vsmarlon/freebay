import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';

class LocationMessageBubble extends StatelessWidget {
  final Map<String, dynamic>? metadata;
  final bool isMe;

  const LocationMessageBubble({
    super.key,
    required this.metadata,
    required this.isMe,
  });

  LatLng? get _coordinates {
    if (metadata == null) return null;
    final lat = metadata!['latitude'] ?? metadata!['lat'];
    final lng = metadata!['longitude'] ?? metadata!['lng'];
    if (lat == null || lng == null) return null;
    return LatLng((lat as num).toDouble(), (lng as num).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final coords = _coordinates;
    if (coords == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.isDark
              ? AppColors.surfaceContainerDark
              : AppColors.surfaceContainerLow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off, size: 16, color: context.textSecondary),
            const SizedBox(width: 6),
            Text(
              'Localização indisponível',
              style: TextStyle(fontSize: 12, color: context.textSecondary),
            ),
          ],
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240, maxHeight: 180),
      child: ClipRect(
        child: FlutterMap(
          options: MapOptions(
            initialCenter: coords,
            initialZoom: 15,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.freebay.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: coords,
                  width: 32,
                  height: 32,
                  child: Icon(
                    Icons.location_pin,
                    color: AppColors.primaryContainer,
                    size: 32,
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
