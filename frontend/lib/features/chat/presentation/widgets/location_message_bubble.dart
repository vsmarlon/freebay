import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/features/chat/presentation/pages/chat_location_page.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class LocationMessageBubble extends StatelessWidget {
  final Map<String, dynamic>? metadata;
  final bool isMe;

  const LocationMessageBubble({
    super.key,
    required this.metadata,
    required this.isMe,
  });

  bool get _hasCanonicalMetadata {
    final data = metadata;
    if (data == null ||
        !data.keys.every(
          (key) => const {
            'latitude',
            'longitude',
            'accuracyMeters',
            'capturedAt',
            'address',
          }.contains(key),
        ) ||
        !data.containsKey('latitude') ||
        !data.containsKey('longitude') ||
        !data.containsKey('accuracyMeters') ||
        !data.containsKey('capturedAt')) {
      return false;
    }
    final accuracy = data['accuracyMeters'];
    final capturedAt = data['capturedAt'];
    final parsed = capturedAt is String ? DateTime.tryParse(capturedAt) : null;
    return accuracy is num &&
        accuracy.isFinite &&
        accuracy >= 0 &&
        accuracy <= 100000 &&
        parsed != null &&
        parsed.isUtc &&
        parsed.toIso8601String() == capturedAt &&
        (data['address'] == null ||
            (data['address'] is String &&
                (data['address'] as String).trim().isNotEmpty &&
                (data['address'] as String).length <= 500));
  }

  LatLng? get _coordinates {
    if (!_hasCanonicalMetadata) return null;
    final lat = metadata!['latitude'];
    final lng = metadata!['longitude'];
    if (lat is! num || lng is! num) return null;
    final latitude = lat.toDouble();
    final longitude = lng.toDouble();
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return null;
    }
    return LatLng(latitude, longitude);
  }

  String? get _address {
    if (metadata == null) return null;
    final address = metadata!['address'];
    return address is String ? address : null;
  }

  num? get _accuracy {
    if (!_hasCanonicalMetadata) return null;
    final accuracy = metadata?['accuracyMeters'];
    if (accuracy is! num || !accuracy.isFinite || accuracy < 0) return null;
    return accuracy;
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
              l10n(context).locationUnavailable,
              style: TextStyle(fontSize: 12, color: context.textSecondary),
            ),
          ],
        ),
      );
    }

    final address = _address;

    return Semantics(
      button: true,
      label: l10n(context).chatLocationLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push(
          AppRoutes.chatLocationView,
          extra: ChatLocationDetails(
            coordinates: coords,
            address: address,
            accuracyMeters: _accuracy,
          ),
        ),
        child: Container(
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
                child: IgnorePointer(
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
              if (_accuracy != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Text(
                    l10n(
                      context,
                    ).locationAccuracy(_accuracy!.toStringAsFixed(0)),
                    style: TextStyle(
                      fontSize: 11,
                      color: context.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
