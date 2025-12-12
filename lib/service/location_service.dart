// location_service.dart
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

// Định nghĩa các lỗi tùy chỉnh để dễ xử lý ở UI
class LocationServiceDisabledException implements Exception {}

class LocationPermissionPermanentlyDeniedException implements Exception {}

class LocationStreamTimeoutException implements Exception {
  final String message;
  LocationStreamTimeoutException([this.message = "Timeout location"]);

  @override
  String toString() => message;
}

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
    late LocationSettings locationSettings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 10, // Cập nhật mỗi 10 mét (tùy chỉnh)
        forceLocationManager: true,
        intervalDuration: const Duration(seconds: 1),
       foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: "Đang theo dõi lộ trình",
          notificationText: "Ứng dụng đang lấy vị trí của bạn dưới nền",
          enableWakeLock: true,
          setOngoing: true
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType
            .automotiveNavigation, // Báo cho iOS biết đây là app dẫn đường xe hơi
        distanceFilter: 10,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10,
      );
    }

    return Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: (sink) {
        sink.addError(LocationStreamTimeoutException());
      },
    );
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
      debugPrint(
        'LocationService: Permission is denied, requesting permission...',
      );
      status = await Permission.location.request();
      debugPrint('LocationService: Permission request result: $status');
    }

    if (status.isPermanentlyDenied) {
      debugPrint('LocationService: Location permission permanently denied.');
      throw LocationPermissionPermanentlyDeniedException();
    }

    debugPrint(
      'LocationService: Final permission status before returning: ${status.isGranted}',
    );
    return status.isGranted;
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }
}
