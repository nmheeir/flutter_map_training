// location_service.dart
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
      accuracy: LocationAccuracy.high,
      distanceFilter:
          0,
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  Future<bool> checkPermission() async {
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

    return status.isGranted;
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }
}
