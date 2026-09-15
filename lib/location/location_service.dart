import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'location_result.dart';

class LocationService {
  const LocationService();

  /// This is a simplified Bangladesh boundary polygon.
  ///
  /// For production, replace this with a detailed official GeoJSON boundary
  /// containing the complete Bangladesh border.
  static const List<_GeoPoint> _bangladeshBoundary = [
    _GeoPoint(26.6345, 88.0283),
    _GeoPoint(26.4465, 88.5631),
    _GeoPoint(26.0144, 89.3551),
    _GeoPoint(25.9651, 89.8325),
    _GeoPoint(25.2698, 89.9207),
    _GeoPoint(25.1326, 90.8722),
    _GeoPoint(25.1474, 91.7996),
    _GeoPoint(24.9767, 92.3762),
    _GeoPoint(24.1304, 91.9151),
    _GeoPoint(24.0727, 91.4677),
    _GeoPoint(23.5035, 91.1590),
    _GeoPoint(22.9853, 91.7065),
    _GeoPoint(23.6244, 91.8699),
    _GeoPoint(23.6275, 92.1461),
    _GeoPoint(22.0412, 92.6727),
    _GeoPoint(21.3241, 92.6523),
    _GeoPoint(21.4755, 92.3033),
    _GeoPoint(20.6709, 92.3686),
    _GeoPoint(21.1922, 92.0829),
    _GeoPoint(21.7016, 92.0252),
    _GeoPoint(22.1829, 91.8349),
    _GeoPoint(22.7650, 91.4171),
    _GeoPoint(22.8050, 90.4960),
    _GeoPoint(22.3928, 90.5870),
    _GeoPoint(21.8364, 90.2730),
    _GeoPoint(22.0391, 89.8475),
    _GeoPoint(21.8571, 89.7021),
    _GeoPoint(21.9662, 89.4189),
    _GeoPoint(22.0557, 89.0320),
    _GeoPoint(22.8791, 88.8763),
    _GeoPoint(23.6311, 88.5298),
    _GeoPoint(24.2337, 88.6999),
    _GeoPoint(24.5017, 88.0844),
    _GeoPoint(24.8661, 88.3064),
    _GeoPoint(25.2387, 88.9315),
    _GeoPoint(25.7681, 88.2098),
    _GeoPoint(26.4465, 88.5631),
  ];

  Future<LocationResult> validateCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        return const LocationResult(
          status: LocationResultStatus.locationServicesDisabled,
          message: 'Location services are disabled.',
        );
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return const LocationResult(
          status: LocationResultStatus.permissionDenied,
          message: 'Location permission was denied.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(
          status: LocationResultStatus.permissionDeniedForever,
          message: 'Location permission is permanently denied.',
        );
      }

      if (!_hasUsablePermission(permission)) {
        return const LocationResult(
          status: LocationResultStatus.permissionDenied,
          message: 'Location permission was not granted.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
          timeLimit: Duration(seconds: 20),
        ),
      );

      final isInsideBangladesh = _isPointInsideBangladesh(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!isInsideBangladesh) {
        return LocationResult(
          status: LocationResultStatus.outsideBangladesh,
          message: 'The current location is outside Bangladesh.',
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }

      return LocationResult(
        status: LocationResultStatus.allowed,
        message: 'The current location is inside Bangladesh.',
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on TimeoutException {
      return const LocationResult(
        status: LocationResultStatus.locationUnavailable,
        message: 'The location request timed out.',
      );
    } on LocationServiceDisabledException {
      return const LocationResult(
        status: LocationResultStatus.locationServicesDisabled,
        message: 'Location services are disabled.',
      );
    } on PermissionDefinitionsNotFoundException {
      return const LocationResult(
        status: LocationResultStatus.error,
        message: 'Location permission configuration is missing.',
      );
    } catch (error) {
      return LocationResult(
        status: LocationResultStatus.error,
        message: 'Unable to determine the current location: $error',
      );
    }
  }

  bool _hasUsablePermission(LocationPermission permission) {
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Ray-casting point-in-polygon algorithm.
  bool _isPointInsideBangladesh({
    required double latitude,
    required double longitude,
  }) {
    final point = _GeoPoint(latitude, longitude);

    var isInside = false;

    for (
      var i = 0, j = _bangladeshBoundary.length - 1;
      i < _bangladeshBoundary.length;
      j = i++
    ) {
      final current = _bangladeshBoundary[i];
      final previous = _bangladeshBoundary[j];

      final crossesLongitude =
          (current.longitude > point.longitude) !=
          (previous.longitude > point.longitude);

      if (!crossesLongitude) {
        continue;
      }

      final intersectionLatitude =
          previous.latitude +
          (current.latitude - previous.latitude) *
              (point.longitude - previous.longitude) /
              (current.longitude - previous.longitude);

      if (point.latitude < intersectionLatitude) {
        isInside = !isInside;
      }
    }

    return isInside;
  }

  Future<bool> openApplicationSettings() {
    return Geolocator.openAppSettings();
  }

  Future<bool> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }
}

class _GeoPoint {
  const _GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}
