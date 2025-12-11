// location_service.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

// Định nghĩa các lỗi tùy chỉnh để dễ xử lý ở UI
class LocationServiceDisabledException implements Exception {}

class LocationPermissionPermanentlyDeniedException implements Exception {}

class LocationService {
  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceDisabledException();
    }

    PermissionStatus status = await Permission.location.status;

    if (status.isDenied) {
      status = await Permission.location.request();
    }

    if (status.isPermanentlyDenied) {
      throw LocationPermissionPermanentlyDeniedException();
    }

    if (status.isGranted) {
      return await Geolocator.getCurrentPosition();
    }

    return null;
  }

  Stream<Position> getPositionStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  Future<bool> checkPermission() async {
    debugPrint('LocationService: Checking location permissions...');
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('LocationService: Location service is disabled.');
      throw LocationServiceDisabledException();
    }
    debugPrint('LocationService: Location service is enabled.');

    PermissionStatus status = await Permission.location.status;
    debugPrint('LocationService: Initial location permission status: $status');

    if (status.isDenied) {
      debugPrint('LocationService: Permission is denied, requesting permission...');
      status = await Permission.location.request();
      debugPrint('LocationService: Permission request result: $status');
    }

    if (status.isPermanentlyDenied) {
      debugPrint('LocationService: Location permission permanently denied.');
      throw LocationPermissionPermanentlyDeniedException();
    }

    debugPrint('LocationService: Final permission status before returning: ${status.isGranted}');
    return status.isGranted;
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }
}
