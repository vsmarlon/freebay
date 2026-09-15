import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:freebay/core/ui.dart';

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final _mapController = MapController();
  Position? _position;
  bool _isLoading = true;
  String? _errorMsg;

  static const _initialZoom = 16.0;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _setError('Ative o serviço de localização para continuar.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _setError(
          'Permissão negada permanentemente. Ative-a nas configurações.',
        );
        return;
      }
      if (permission == LocationPermission.denied) {
        _setError('Permissão de localização negada.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      setState(() {
        _position = position;
      });
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        _initialZoom,
      );
    } catch (_) {
      _setError('Não foi possível obter sua localização. Tente novamente.');
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() {
      _errorMsg = message;
      _isLoading = false;
      _position = null;
    });
  }

  Future<void> _sendLocation() async {
    if (_position == null || _isLoading) return;

    setState(() => _isLoading = true);
    late final Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      setState(() {
        _position = position;
      });
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        _initialZoom,
      );
    } catch (_) {
      _setError('Não foi possível obter sua localização. Tente novamente.');
      return;
    }

    if (!mounted) return;
    String? address;
    try {
      final response = await Dio().get(
        'https://photon.komoot.io/reverse',
        queryParameters: {
          'lat': position.latitude,
          'lon': position.longitude,
          'lang': 'pt',
        },
      );
      if (response.statusCode == 200) {
        final features = response.data['features'] as List?;
        final props =
            features?.firstOrNull?['properties'] as Map<String, dynamic>?;
        if (props != null) {
          final resolvedAddress = [
            'name',
            'street',
            'city',
            'town',
            'state',
          ].map((k) => props[k] as String?).nonNulls.toSet().join(', ');
          if (resolvedAddress.isNotEmpty) {
            address = resolvedAddress.length > 500
                ? resolvedAddress.substring(0, 500)
                : resolvedAddress;
          }
        }
      }
    } catch (e) {
      debugPrint('Reverse geocoding failed: $e');
    }

    if (mounted) {
      Navigator.pop(context, {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracyMeters': position.accuracy,
        'capturedAt': DateTime.fromMillisecondsSinceEpoch(
          position.timestamp.toUtc().millisecondsSinceEpoch,
          isUtc: true,
        ).toIso8601String(),
        if (address != null && address.isNotEmpty) 'address': address,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final position = _position;
    final center = position == null
        ? null
        : LatLng(position.latitude, position.longitude);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
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
                  : center == null
                  ? Center(
                      child: AppButton(
                        label: 'TENTAR NOVAMENTE',
                        onPressed: _determinePosition,
                      ),
                    )
                  : Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: center,
                            initialZoom: _initialZoom,
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
                                  point: center,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_position != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Precisão do provedor: ${_position!.accuracy.toStringAsFixed(0)} m',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textSecondary,
                          ),
                        ),
                      ),
                    AppButton(
                      label: 'CONFIRMAR E ENVIAR LOCALIZAÇÃO',
                      onPressed: _position != null && !_isLoading
                          ? _sendLocation
                          : null,
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
