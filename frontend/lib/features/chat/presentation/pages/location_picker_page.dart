import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/page_header.dart';
import 'package:freebay/core/components/brutalist_icon_button.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final _mapController = MapController();
  LatLng? _selectedPoint;
  bool _isLoading = true;
  String? _errorMsg;

  static const _initialCenter = LatLng(
    -23.5505,
    -46.6333,
  ); // São Paulo fallback
  static const _initialZoom = 16.0;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    try {
      final status = await Permission.location.request();
      if (!status.isGranted && !status.isLimited) {
        if (mounted) {
          setState(() {
            _errorMsg =
                'Permissão de localização negada. Toque no mapa para selecionar o ponto.';
            _selectedPoint = _initialCenter;
            _isLoading = false;
          });
        }
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (!mounted) return;

      if (position != null) {
        final point = LatLng(position.latitude, position.longitude);
        setState(() {
          _selectedPoint = point;
          _isLoading = false;
          _errorMsg = null;
        });
        _mapController.move(point, _initialZoom);
      } else {
        setState(() {
          _selectedPoint = _initialCenter;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _selectedPoint = _initialCenter;
          _isLoading = false;
        });
      }
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng latLng) {
    setState(() => _selectedPoint = latLng);
  }

  Future<void> _sendLocation() async {
    if (_selectedPoint == null) return;

    setState(() => _isLoading = true);
    String? address;
    try {
      final response = await Dio().get(
        'https://photon.komoot.io/reverse',
        queryParameters: {
          'lat': _selectedPoint!.latitude,
          'lon': _selectedPoint!.longitude,
          'lang': 'pt',
        },
      );
      if (response.statusCode == 200) {
        final features = response.data['features'] as List?;
        final props =
            features?.firstOrNull?['properties'] as Map<String, dynamic>?;
        if (props != null) {
          address = [
            'name',
            'street',
            'city',
            'town',
            'state',
          ].map((k) => props[k] as String?).nonNulls.toSet().join(', ');
        }
      }
    } catch (e) {
      debugPrint('Reverse geocoding failed: $e');
    }

    if (mounted) {
      Navigator.pop(context, {
        'lat': _selectedPoint!.latitude,
        'lng': _selectedPoint!.longitude,
        'address': address,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = _selectedPoint ?? _initialCenter;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          PageHeader(
            text: 'LOCALIZAÇÃO',
            leading: BrutalistIconButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
            ),
          ),
          if (_errorMsg != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.warning.withAlpha(40),
              child: Text(
                _errorMsg!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryContainer,
                    ),
                  )
                : Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: center,
                          initialZoom: _initialZoom,
                          onTap: _onMapTap,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.freebay.app',
                          ),
                          if (_selectedPoint != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _selectedPoint!,
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
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: BrutalistIconButton(
                          icon: Icons.my_location,
                          size: 48,
                          onTap: _determinePosition,
                        ),
                      ),
                    ],
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              border: Border(
                top: BorderSide(color: context.borderColor, width: 2),
              ),
            ),
            child: SafeArea(
              top: false,
              child: AppButton(
                label: 'ENVIAR LOCALIZAÇÃO',
                onPressed: _selectedPoint != null ? _sendLocation : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
