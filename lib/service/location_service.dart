// location_service.dart
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationStreamTimeoutException implements Exception {
  final String message;
  LocationStreamTimeoutException([this.message = "Timeout location"]);

  @override
  String toString() => message;
}

class LocationService {
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
          setOngoing: true,
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

  Future<void> openSettings() async {
    await openAppSettings();
  }
}
