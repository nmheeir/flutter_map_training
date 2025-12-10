import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart'; // Chỉ cần nếu dùng showDialog

// Hàm kiểm tra và yêu cầu quyền
Future<bool> requestPermission(Permission permission) async {
  // 1. Kiểm tra trạng thái hiện tại của quyền
  PermissionStatus status = await permission.status;

  // 2. Nếu quyền đã được cấp, trả về true
  if (status.isGranted) {
    return true;
  }

  // 3. Nếu quyền chưa được cấp, yêu cầu cấp quyền
  if (status.isDenied) {
    PermissionStatus result = await permission.request();

    if (result.isGranted) {
      return true;
    } else {
      // Quyền bị từ chối lần nữa
      return false;
    }
  }

  // 4. Nếu quyền bị từ chối vĩnh viễn (permanentlyDenied) hoặc bị hạn chế (restricted)
  if (status.isPermanentlyDenied || status.isRestricted) {
    // Thường hiển thị dialog hướng dẫn người dùng mở cài đặt ứng dụng
    // Mở cài đặt
    openAppSettings();
    return false;
  }

  // Mặc định trả về false nếu có vấn đề
  return false;
}

// Ví dụ sử dụng hàm này trong một widget hoặc sự kiện
void handleCameraPermissionRequest() async {
  bool isGranted = await requestPermission(Permission.camera);

  if (isGranted) {
    print("Quyền Camera đã được cấp!");
    // Thực hiện chức năng Camera
  } else {
    print("Quyền Camera bị từ chối hoặc cần mở Cài đặt.");
  }
}

// Ví dụ yêu cầu nhiều quyền cùng lúc:
void handleMultiplePermissionsRequest() async {
  Map<Permission, PermissionStatus> statuses = await [
    Permission.location,
    Permission.storage,
  ].request();

  if (statuses[Permission.location]!.isGranted) {
    print("Quyền Vị trí đã được cấp.");
  }

  if (statuses[Permission.storage]!.isGranted) {
    print("Quyền Bộ nhớ đã được cấp.");
  }

  // Bạn có thể xử lý các trạng thái khác tương tự.
}

// Trong một widget Flutter:
class PermissionDemoScreen extends StatelessWidget {
  const PermissionDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Yêu cầu Cấp quyền')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: handleCameraPermissionRequest,
              child: Text('Yêu cầu Quyền Camera'),
            ),
            ElevatedButton(
              onPressed: handleMultiplePermissionsRequest,
              child: Text('Yêu cầu Quyền Vị trí & Bộ nhớ'),
            ),
          ],
        ),
      ),
    );
  }
}