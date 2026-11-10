import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class ChatLocationDetails {
  final LatLng coordinates;
  final String? address;
  final num? accuracyMeters;

  const ChatLocationDetails({
    required this.coordinates,
    this.address,
    this.accuracyMeters,
  });
}

class ChatLocationPage extends StatelessWidget {
  final ChatLocationDetails details;

  const ChatLocationPage({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            PageHeader(
              text: strings.chatLocation,
              leading: BrutalistIconButton(
                icon: Icons.arrow_back,
                semanticLabel: strings.accessibilityBack,
                onTap: () => context.pop(),
              ),
            ),
            Expanded(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: details.coordinates,
                  initialZoom: 16,
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
                        point: details.coordinates,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_pin,
                          color: AppColors.primaryContainer,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (details.address != null || details.accuracyMeters != null)
              Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: SafeArea(
                  top: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (details.address != null)
                        Text(details.address!, style: AppTypography.bodyMedium),
                      if (details.accuracyMeters != null)
                        Text(
                          strings.locationAccuracy(
                            details.accuracyMeters!.toStringAsFixed(0),
                          ),
                          style: AppTypography.bodySmall.copyWith(
                            color: context.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
