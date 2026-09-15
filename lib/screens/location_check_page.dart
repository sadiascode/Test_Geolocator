import 'package:flutter/material.dart';

import '../location/location_result.dart';
import '../location/location_service.dart';
import 'next_page.dart';

class LocationCheckPage extends StatefulWidget {
  const LocationCheckPage({super.key});

  @override
  State<LocationCheckPage> createState() => _LocationCheckPageState();
}

class _LocationCheckPageState extends State<LocationCheckPage> {
  late final LocationService _locationService;

  bool _isCheckingLocation = false;

  @override
  void initState() {
    super.initState();

    _locationService = const LocationService();
  }

  Future<void> _onContinuePressed() async {
    if (_isCheckingLocation) {
      return;
    }

    setState(() {
      _isCheckingLocation = true;
    });

    final result = await _locationService.validateCurrentLocation();

    if (!mounted) {
      return;
    }

    setState(() {
      _isCheckingLocation = false;
    });

    if (result.status == LocationResultStatus.allowed) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const NextPage()));

      return;
    }

    switch (result.status) {
      case LocationResultStatus.outsideBangladesh:
        await _showMessage(
          title: 'Location not allowed',
          message: 'You must be inside Bangladesh to continue.',
        );
        break;

      case LocationResultStatus.permissionDenied:
        await _showMessage(
          title: 'Permission required',
          message:
              'Location permission was denied. Location permission is required to continue.',
        );
        break;

      case LocationResultStatus.permissionDeniedForever:
        await _showSettingsDialog(
          title: 'Location permission disabled',
          message:
              'Location permission has been permanently denied. Enable it from the app settings to continue.',
          openSettings: _locationService.openApplicationSettings,
        );
        break;

      case LocationResultStatus.locationServicesDisabled:
        await _showSettingsDialog(
          title: 'Location services disabled',
          message: 'Enable location services on your device to continue.',
          openSettings: _locationService.openLocationSettings,
        );
        break;

      case LocationResultStatus.locationUnavailable:
      case LocationResultStatus.error:
        await _showMessage(
          title: 'Unable to verify location',
          message: result.message ?? 'Please try again.',
        );
        break;

      case LocationResultStatus.allowed:
        break;
    }
  }

  Future<void> _showMessage({
    required String title,
    required String message,
  }) async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSettingsDialog({
    required String title,
    required String message,
    required Future<bool> Function() openSettings,
  }) async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await openSettings();
              },
              child: const Text('Open settings'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Location Check',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D2433),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFEAECEF)),
        ),
      ),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  size: 42,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Verify your location',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D2433),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'We need to verify that you are currently inside Bangladesh to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _isCheckingLocation ? null : _onContinuePressed,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isCheckingLocation
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.my_location_rounded, size: 19),
                            SizedBox(width: 8),
                            Text(
                              'Verify Location',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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
