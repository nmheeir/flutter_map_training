// home_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_training/plugins/zoombuttons_plugin.dart';
import 'package:flutter_map_training/service/location_service.dart';
import 'package:flutter_map_training/tile_layer.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geodesy/geodesy.dart';
import 'package:geolocator/geolocator.dart'
    hide LocationServiceDisabledException;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final MapController _mapController;
  final LocationService _locationService = LocationService();

  final Geodesy _geodesy = Geodesy();

  // fallback nếu người dùng từ chối cấp quyền truy cập vị trí
  final LatLng _defaultLocation = const LatLng(10.762622, 106.660172);
  final LatLng _destination = const LatLng(37.3340, -122.0102);

  LatLng? _currentCenter;
  final double _initialZoom = 15;
  bool _isLoading = true;
  bool _isAutoCenter = true;

  // Biến lưu trữ thông tin tính toán
  num _distanceInMeters = 0;
  String _currentAddress = "Đang tải vị trí...";
  String _destinationAddress = "Đang tải vị trí...";

  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    _updateAddress(_destination).then((addr) {
      if (mounted) setState(() => _destinationAddress = addr);
    });

    _startLiveTracking();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  /// Reverse Geocoding
  Future<String> _updateAddress(LatLng coordinates) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        coordinates.latitude,
        coordinates.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final components = [
          place.street,
          place.subAdministrativeArea,
          place.administrativeArea,
          place.country,
        ].where((e) => e != null && e.isNotEmpty).toList();

        return components.join(", ");
      }
      return "Không xác định được địa chỉ";
    } catch (e) {
      debugPrint("Lỗi geocoding: $e");
      return "Lỗi mạng hoặc giới hạn API";
    }
  }

  void _calculateMetrics() {
    if (_currentCenter == null) return;

    setState(() {
      _distanceInMeters = _geodesy.distanceBetweenTwoGeoPoints(
        _currentCenter!,
        _destination,
      );
    });
  }

  Future<void> _startLiveTracking() async {
    debugPrint("_startLiveTracking called");
    try {
      final hasPermission = await _locationService.checkPermission();
      debugPrint("Location permission status: $hasPermission");

      if (hasPermission) {
        // Hủy stream trước đó nếu có
        _positionStreamSubscription?.cancel();
        debugPrint("Previous position stream cancelled.");

        _positionStreamSubscription = _locationService
            .getPositionStream()
            .listen(
              (Position position) async {
                if (!mounted) {
                  debugPrint("Not mounted, skipping position update.");
                  return;
                }

                final newLocation = LatLng(
                  position.latitude,
                  position.longitude,
                );
                debugPrint("Received new position: $newLocation");

                setState(() {
                  _currentCenter = newLocation;
                  _calculateMetrics();
                });

                final address = await _updateAddress(newLocation);
                if (mounted) {
                  setState(() => _currentAddress = address);
                  debugPrint("Updated current address: $address");
                }

                if (_isAutoCenter) {
                  _animatedMapMove(_currentCenter!, _mapController.camera.zoom);
                  debugPrint("Auto-centering map to: $_currentCenter");
                }
              },
              onError: (e) {
                debugPrint("Lỗi stream vị trí: $e");
              },
            );
      } else {
        debugPrint("Permission not granted, using fallback location.");
        _useFallbackLocation();
      }
    } on LocationServiceDisabledException {
      debugPrint("LocationServiceDisabledException caught.");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Vui lòng bật GPS')));
        _useFallbackLocation();
      }
    } on LocationPermissionPermanentlyDeniedException {
      debugPrint("LocationPermissionPermanentlyDeniedException caught.");
      if (mounted) {
        _showPermissionDialog();
        _useFallbackLocation();
      }
    } catch (e) {
      debugPrint("Lỗi khởi tạo: $e");
      _useFallbackLocation();
    }
  }

  void _onMyLocationPressed() {
    setState(() {
      _isAutoCenter = true;
    });
    if (_currentCenter != null) {
      _animatedMapMove(_currentCenter!, _mapController.camera.zoom);
    } else {
      _startLiveTracking();
    }
  }

  void _useFallbackLocation() async {
    debugPrint("[_useFallbackLocation] Using fallback location.");
    if (!mounted) return;
    setState(() {
      _currentCenter ??= _defaultLocation;
      _isLoading = false;
      _calculateMetrics();
    });

    final addr = await _updateAddress(_defaultLocation);
    if (mounted) setState(() => _currentAddress = addr);
  }

  void _showPermissionDialog() {
    debugPrint("[_showPermissionDialog] Showing permission dialog.");
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
              debugPrint("[_showPermissionDialog] 'Hủy' button pressed.");
              Navigator.pop(ctx);
            },
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () {
              debugPrint(
                "[_showPermissionDialog] 'Mở Cài đặt' button pressed. Opening settings.",
              );
              Navigator.pop(ctx);
              _locationService.openSettings();
            },
            child: const Text("Mở Cài đặt"),
          ),
        ],
      ),
    );
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(
      begin: _mapController.camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.camera.zoom,
      end: destZoom,
    );

    final controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    final Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: Curves.fastOutSlowIn,
    );

    controller.addListener(() {
      _mapController.move(
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

  Widget _buildLines() {
    return PolylineLayer(
      polylines: [
        Polyline(
          points: [_currentCenter!, LatLng(37.3340, -122.0102)],
          strokeWidth: 4,
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildInfoPanel() {
    String distanceStr = _distanceInMeters > 1000
        ? "${(_distanceInMeters / 1000).toStringAsFixed(2)} km"
        : "${_distanceInMeters.toStringAsFixed(0)} m";

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
              // HÀNG 1: KHOẢNG CÁCH (Nổi bật)
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

              // HÀNG 2: THÔNG TIN CHI TIẾT (Địa chỉ)
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
                          _currentAddress,
                          maxLines: 3, // Cho phép tối đa 3 dòng
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                        Text(
                          _currentCenter != null
                              ? "${_currentCenter!.latitude.toStringAsFixed(4)}, ${_currentCenter!.longitude.toStringAsFixed(4)}"
                              : "Đang tải...",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ĐƯỜNG KẺ DỌC NGĂN CÁCH
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
                          _destinationAddress,
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
                          _currentCenter != null
                              ? "${_destination.latitude.toStringAsFixed(4)}, ${_destination.longitude.toStringAsFixed(4)}"
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading && _currentCenter == null
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentCenter ?? _defaultLocation,
                initialZoom: _initialZoom,
                onPositionChanged: (camera, hasGesture) {
                  if (hasGesture) {
                    setState(() {
                      _isAutoCenter = false;
                    });
                  }
                },
              ),
              children: [
                openStreetMapTileLayer,
                _buildLines(),
                if (_currentCenter != null)
                  MarkerLayer(
                    markers: [
                      // Marker Vị trí hiện tại
                      if (_currentCenter != null)
                        Marker(
                          point: _currentCenter!,
                          width: 50,
                          height: 50,
                          child: const Icon(
                            Icons.directions_car,
                            size: 40,
                            color: Colors.red,
                          ),
                        ),
                      // Marker Đích đến
                      Marker(
                        point: _destination,
                        width: 50,
                        height: 50,
                        child: const Icon(
                          Icons.flag,
                          size: 40,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),

                _buildInfoPanel(),

                const FlutterMapZoomButtons(
                  minZoom: 4,
                  maxZoom: 19,
                  mini: true,
                  padding: 10,
                  alignment: Alignment.bottomLeft,
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onMyLocationPressed,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
