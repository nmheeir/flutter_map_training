import 'package:flutter/material.dart';
import 'package:flutter_map_training/service/permission_service.dart';

void showPermissionDialog(
  BuildContext context,
  PermissionService permissionService,
  Object error,
) {
  String title;
  String message;

  if (error is LocationServiceDisabledException) {
    title = "Dịch vụ vị trí bị tắt";
    message =
        "Thiết bị của bạn đang tắt GPS. Hãy bật GPS để ứng dụng có thể lấy vị trí.";
  } else if (error is LocationPermissionPermanentlyDeniedException) {
    title = "Quyền vị trí bị chặn";
    message =
        "Ứng dụng không thể truy cập vị trí vì quyền đã bị từ chối vĩnh viễn. Vui lòng mở Cài đặt và cấp lại quyền.";
  } else if (error is NotificationPermissionPermanentlyDeniedException) {
    title = "Quyền thông báo bị chặn";
    message =
        "Ứng dụng cần quyền thông báo để gửi Live Activity và thông báo quan trọng. Hãy mở Cài đặt và cấp lại quyền.";
  } else {
    title = "Cần cấp quyền";
    message =
        "Ứng dụng cần một số quyền để hoạt động chính xác. Vui lòng kiểm tra lại trong Cài đặt.";
  }

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text("Đóng"),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            permissionService.openSettings();
          },
          child: const Text("Mở Cài đặt"),
        ),
      ],
    ),
  );
}
