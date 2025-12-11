import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class MapInfoPanel extends StatelessWidget {
  final num distanceInMeters;
  final String currentAddress;
  final String destinationAddress;
  final LatLng? currentCenter;
  final LatLng destination;

  const MapInfoPanel({
    super.key,
    required this.distanceInMeters,
    required this.currentAddress,
    required this.destinationAddress,
    required this.currentCenter,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    String distanceStr = distanceInMeters > 1000
        ? "${(distanceInMeters / 1000).toStringAsFixed(2)} km"
        : "${distanceInMeters.toStringAsFixed(0)} m";

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // HÀNG 1: KHOẢNG CÁCH
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.directions, color: Colors.blue, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      distanceStr,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // HÀNG 2: THÔNG TIN CHI TIẾT
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CỘT TRÁI: ĐIỂM ĐI
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.my_location,
                              size: 16,
                              color: Colors.red,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "Vị trí của tôi",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentAddress,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                        Text(
                          currentCenter != null
                              ? "${currentCenter!.latitude.toStringAsFixed(4)}, ${currentCenter!.longitude.toStringAsFixed(4)}"
                              : "Đang tải...",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ĐƯỜNG KẺ DỌC
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey.shade300,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),

                  // CỘT PHẢI: ĐIỂM ĐẾN
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              "Đích đến",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.flag, size: 16, color: Colors.green),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          destinationAddress,
                          textAlign: TextAlign.right,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                        Text(
                          currentCenter != null
                              ? "${destination.latitude.toStringAsFixed(4)}, ${destination.longitude.toStringAsFixed(4)}"
                              : "Đang tải...",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
