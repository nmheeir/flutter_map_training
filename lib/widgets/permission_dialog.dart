import 'package:flutter/material.dart';
import 'package:flutter_map_training/service/location_service.dart';

void showPermissionDialog(BuildContext context, LocationService locationService) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("Cần quyền truy cập vị trí"),
      content: const Text(
        "Ứng dụng cần quyền vị cập vị trí để hiển thị bản đồ chính xác. Vui lòng mở Cài đặt và cấp quyền.",
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
          },
          child: const Text("Hủy"),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            locationService.openSettings();
          },
          child: const Text("Mở Cài đặt"),
        ),
      ],
    ),
  );
}