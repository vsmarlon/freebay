import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:freebay/core/ui.dart';

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

  String? get _address {
    if (metadata == null) return null;
    return metadata!['address'];
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

    final address = _address;

    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      decoration: BoxDecoration(
        color: context.isDark
            ? AppColors.surfaceContainerDark
            : AppColors.surfaceContainerLow,
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 140,
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
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.freebay.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: coords,
                        width: 32,
                        height: 32,
                        child: const Icon(
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
          ),
          if (address != null && address.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                address,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: context.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
