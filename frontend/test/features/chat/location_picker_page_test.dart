import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/chat/presentation/pages/location_picker_page.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';

class _Geolocator extends GeolocatorPlatform {
  LocationPermission permission = LocationPermission.whileInUse;
  final List<Position> positions;
  int currentPositionCalls = 0;

  _Geolocator(this.positions);

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async => permission;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async => positions[currentPositionCalls++];
}

Position _position(double latitude, double longitude, double accuracy) =>
    Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.utc(2026, 10, 9, 12),
      accuracy: accuracy,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'confirm returns the exact measured position without rereading GPS',
    (tester) async {
      final previous = GeolocatorPlatform.instance;
      final fake = _Geolocator([_position(-23.55, -46.63, 8.5)]);
      GeolocatorPlatform.instance = fake;
      addTearDown(() => GeolocatorPlatform.instance = previous);
      Map<String, Object?>? result;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    result = await Navigator.of(context)
                        .push<Map<String, Object?>>(
                          MaterialPageRoute(
                            builder: (_) => const LocationPickerPage(),
                          ),
                        );
                  },
                  child: const Text('Open location picker'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open location picker'));
      await tester.pumpAndSettle();
      final strings = AppLocalizations.of(
        tester.element(find.byType(LocationPickerPage)),
      );
      await tester.tap(
        find.text(strings.chatConfirmSendLocation.toUpperCase()),
      );
      await tester.pumpAndSettle();

      expect(fake.currentPositionCalls, 1);
      expect(result, {
        'latitude': -23.55,
        'longitude': -46.63,
        'accuracyMeters': 8.5,
        'capturedAt': '2026-10-09T12:00:00.000Z',
      });
    },
  );

  testWidgets(
    'permission denial disables sending and retry obtains a measured fix',
    (tester) async {
      final previous = GeolocatorPlatform.instance;
      final fake = _Geolocator([_position(10, 20, 4)]);
      fake.permission = LocationPermission.denied;
      GeolocatorPlatform.instance = fake;
      addTearDown(() => GeolocatorPlatform.instance = previous);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: LocationPickerPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final strings = AppLocalizations.of(
        tester.element(find.byType(LocationPickerPage)),
      );
      expect(
        tester.widget<AppButton>(find.byType(AppButton).last).onPressed,
        isNull,
      );
      expect(fake.currentPositionCalls, 0);

      fake.permission = LocationPermission.whileInUse;
      await tester.tap(find.text(strings.commonRetry.toUpperCase()));
      await tester.pumpAndSettle();

      expect(fake.currentPositionCalls, 1);
      expect(
        tester.widget<AppButton>(find.byType(AppButton).last).onPressed,
        isNotNull,
      );
    },
  );
}
