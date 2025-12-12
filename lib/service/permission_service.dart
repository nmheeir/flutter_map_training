import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Các exception riêng để UI xử lý rõ ràng hơn
class LocationServiceDisabledException implements Exception {}

class LocationPermissionPermanentlyDeniedException implements Exception {}

class NotificationPermissionPermanentlyDeniedException implements Exception {}

class PermissionService {
  /// Check ALL required permissions (location + notification)
  Future<bool> checkAllPermissions() async {
    final loc = await checkLocationPermission();
    final noti = await checkNotificationPermission();
    return loc && noti;
  }

  /// LOCATION
  Future<bool> checkLocationPermission() async {
    debugPrint('PermissionService: Checking location permission...');

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
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

    return status.isGranted;
  }

  /// NOTIFICATION
  Future<bool> checkNotificationPermission() async {
    debugPrint('PermissionService: Checking notification permission...');

    PermissionStatus status = await Permission.notification.status;

    if (status.isDenied) {
      status = await Permission.notification.request();
    }

    if (status.isPermanentlyDenied) {
      throw NotificationPermissionPermanentlyDeniedException();
    }

    return status.isGranted;
  }

  /// Mở setting nếu cần
  Future<void> openSettings() async {
    await openAppSettings();
  }
}
