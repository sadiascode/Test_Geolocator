enum LocationResultStatus {
  allowed,
  outsideBangladesh,
  permissionDenied,
  permissionDeniedForever,
  locationServicesDisabled,
  locationUnavailable,
  error,
}

class LocationResult {
  const LocationResult({
    required this.status,
    this.message,
    this.latitude,
    this.longitude,
  });

  final LocationResultStatus status;
  final String? message;
  final double? latitude;
  final double? longitude;

  bool get isAllowed => status == LocationResultStatus.allowed;
}
