import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/page_header.dart';
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

  static const _initialCenter = LatLng(-15.7801, -47.9292); // Brasilia fallback
  static const _initialZoom = 15.0;

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
            _errorMsg = 'Permissão de localização negada';
            _selectedPoint = _initialCenter;
            _isLoading = false;
          });
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      final point = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedPoint = point;
        _isLoading = false;
      });
      _mapController.move(point, _initialZoom);
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

  void _sendLocation() {
    if (_selectedPoint == null) return;
    Navigator.pop(context, {
      'lat': _selectedPoint!.latitude,
      'lng': _selectedPoint!.longitude,
      'address': null,
    });
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
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: context.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          if (_errorMsg != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.warning.withValues(alpha: 0.15),
              child: Text(
                _errorMsg!,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
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
