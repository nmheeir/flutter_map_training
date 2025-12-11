import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Hàm hỗ trợ di chuyển bản đồ mượt mà (Animation)
void animatedMapMove(
  MapController mapController,
  TickerProvider vsync,
  LatLng destLocation,
  double destZoom,
) {
  final controller = AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: vsync,
  );

  final latTween = Tween<double>(
    begin: mapController.camera.center.latitude,
    end: destLocation.latitude,
  );
  final lngTween = Tween<double>(
    begin: mapController.camera.center.longitude,
    end: destLocation.longitude,
  );
  final zoomTween = Tween<double>(
    begin: mapController.camera.zoom,
    end: destZoom,
  );

  final Animation<double> animation = CurvedAnimation(
    parent: controller,
    curve: Curves.fastOutSlowIn,
  );

  controller.addListener(() {
    mapController.move(
      LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
      zoomTween.evaluate(animation),
    );
  });

  animation.addStatusListener((status) {
    if (status == AnimationStatus.completed) {
      controller.dispose();
    }
  });

  controller.forward();
}