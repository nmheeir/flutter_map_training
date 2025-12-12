import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_training/models/map_live_activity.dart';
import 'package:flutter_map_training/service/live_activity_map_service.dart';
import 'package:flutter_map_training/service/location_service.dart';
import 'package:flutter_map_training/service/permission_service.dart';
import 'package:flutter_map_training/utils/map_helper.dart';
import 'package:flutter_map_training/widgets/arrival_panel.dart';
import 'package:flutter_map_training/widgets/map_info_panel.dart';
import 'package:flutter_map_training/widgets/permission_dialog.dart';
import 'package:flutter_map_training/widgets/tile_layer.dart';
import 'package:flutter_map_training/widgets/zoombuttons_plugin.dart';
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
  final PermissionService _permissionService = PermissionService();
  final LocationService _locationService = LocationService();
  final LiveActivityMapService _liveActivityService = LiveActivityMapService();
  final Geodesy _geodesy = Geodesy();

  final LatLng _defaultLocation = const LatLng(10.762622, 106.660172);
  // Inifinite Loop 1
  final LatLng _destination = const LatLng(37.330535, -122.029850);

  // Vị trí hiện tại
  LatLng? _currentCenter;
  //Độ dài quãng đường cần đi ban đầu
  num? _totalDistanceInMeters;
  final double _initialZoom = 16;
  // load map
  bool _isLoading = true;
  // auto focus vị trí hiện tại trên map
  bool _isAutoCenter = true;
  // có đang track location hay không
  bool _isLocationTracking = false;
  // đã tới địa điểm hay chưa
  bool _hasArrived = false;

  // khoảng cách hiện tại tới đích
  num _distanceInMeters = 0;

  String _currentAddress = "Đang tải vị trí...";
  String _destinationAddress = "Đang tải vị trí...";

  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    _liveActivityService.onEndTripStream.listen((event) {
      debugPrint("Flutter received method: ${event.methodName}");

      switch (event.methodName) {
        case 'endTrip':
          debugPrint('endTrip');
          _finishTrip();
          break;
        case 'pauseTrip':
          // _pauseTrip();
          break;
        default:
          debugPrint("Unknown method from native: ${event.methodName}");
      }
    });

    _updateAddress(_destination).then((addr) {
      if (mounted) setState(() => _destinationAddress = addr);
    });

    _startLiveTracking();
  }

  @override
  void dispose() {
    _liveActivityService.endLiveActivity();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  void _initLiveActivity() {
    int minutes = 0;

    if (_totalDistanceInMeters != null) {
      minutes = (_totalDistanceInMeters! / 500).round();
    }

    _liveActivityService.startLiveActivity(
      data: MapLiveActivity(
        remainingDistanceStr: "Bắt đầu di chuyển",
        progress: 0,
        minutesToArrive: minutes,
      ),
    );
  }

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

  void _updateLiveActivityInfo() {
    debugPrint("Khoảng cách hiện tại: $_distanceInMeters m");
    if (_totalDistanceInMeters == null || _totalDistanceInMeters == 0) {
      debugPrint("Debug: _totalDistanceInMeters is null or 0. Returning.");
      return;
    }
    if (_distanceInMeters > _totalDistanceInMeters!) {
      debugPrint("Debug: Cập nhật độ dài quãng đưởng phải đi.");
      _totalDistanceInMeters = _distanceInMeters;
    }

    if (_hasArrived) {
      debugPrint("Debug: Already arrived. _hasArrived is true. Returning.");
      return;
    }

    if (_distanceInMeters > _totalDistanceInMeters!) {
      debugPrint(
        "Debug: _distanceInMeters ($_distanceInMeters) > _totalDistanceInMeters! ($_totalDistanceInMeters). Updating _totalDistanceInMeters.",
      );
      _totalDistanceInMeters = _distanceInMeters;
    }

    // CHECK KHOẢNG CÁCH ĐẾN ĐÍCH
    debugPrint(
      "Debug: Checking arrival condition. _distanceInMeters: $_distanceInMeters",
    );

    // TRƯỜNG HỢP: ĐÃ ĐẾN NƠI (< 20m) và đang trong trạng thái theo dõi vị trí
    if (_distanceInMeters < 20 && _isLocationTracking) {
      debugPrint('Đã đến nơi');
      setState(() {
        _hasArrived = true;
        _isLocationTracking = false;
      });

      // Gửi update cuối cùng sang iOS: Progress 100%
      _liveActivityService.updateLiveActivity(
        data: MapLiveActivity(
          remainingDistanceStr: "Đã đến",
          progress: 100,
          minutesToArrive: 0,
        ),
      );
      debugPrint(
        "Debug: Live Activity updated for arrival: progress 100%, 0 mins.",
      );
    } else {
      debugPrint('Đang di chuyển');
      debugPrint('_distanceInMeters < 20: ${_distanceInMeters < 20}');
      // TRƯỜNG HỢP: ĐANG DI CHUYỂN
      double progressPercent =
          ((_totalDistanceInMeters! - _distanceInMeters) /
              _totalDistanceInMeters!) *
          100;
      int progressInt = progressPercent.clamp(0, 99).toInt();
      debugPrint(
        "Debug: Calculated progressPercent: $progressPercent, progressInt: $progressInt",
      );

      String distanceStr = _distanceInMeters > 1000
          ? "${(_distanceInMeters / 1000).toStringAsFixed(2)} km"
          : "${_distanceInMeters.toStringAsFixed(0)} m";
      debugPrint("Debug: Formatted distanceStr: $distanceStr");

      _liveActivityService.updateLiveActivity(
        data: MapLiveActivity(
          remainingDistanceStr: distanceStr,
          progress: progressInt,
          minutesToArrive: (_distanceInMeters / 500).round(),
        ),
      );
      debugPrint(
        "Debug: Live Activity updated for tracking: distance $distanceStr, progress $progressInt%, minutes ${(_distanceInMeters / 500).round()}.",
      );
    }
  }

  void _finishTrip() {
    _liveActivityService.endLiveActivity();

    // Reset trạng thái App về ban đầu
    setState(() {
      _hasArrived = false;
      _isLocationTracking = false;
      _totalDistanceInMeters = null;
      // _currentCenter = null;
      // _positionStreamSubscription?.cancel();
    });

    animatedMapMove(
      _mapController,
      this,
      _currentCenter!,
      _mapController.camera.zoom,
    );
  }

  Future<void> _startLiveTracking() async {
    try {
      final hasPermission = await _permissionService.checkAllPermissions();
      debugPrint('hasPermission: $hasPermission');
      if (hasPermission) {
        _positionStreamSubscription?.cancel();
        _positionStreamSubscription = _locationService
            .getPositionStream()
            .listen(
              (Position position) async {
                // debugPrint('Position: ${position.toJson()}');
                if (!mounted) return;

                final newLocation = LatLng(
                  position.latitude,
                  position.longitude,
                );

                setState(() {
                  _currentCenter = newLocation;
                  _calculateMetrics();
                  _totalDistanceInMeters ??= _distanceInMeters;
                  if (_isLocationTracking) {
                    _updateLiveActivityInfo();
                  }
                });

                final address = await _updateAddress(newLocation);
                if (mounted) setState(() => _currentAddress = address);

                if (_isAutoCenter) {
                  animatedMapMove(
                    _mapController,
                    this,
                    _currentCenter!,
                    _mapController.camera.zoom,
                  );
                }
              },
              onError: (e) {
                debugPrint("Lỗi stream vị trí: $e");
                if (e is LocationStreamTimeoutException) {
                  _useFallbackLocation();
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            );
      } else {
        _useFallbackLocation();
      }
    } on LocationServiceDisabledException {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Vui lòng bật GPS')));
        _useFallbackLocation();
      }
    } on LocationPermissionPermanentlyDeniedException catch (e) {
      if (mounted) {
        showPermissionDialog(context, _permissionService, e);
        _useFallbackLocation();
      }
    } on NotificationPermissionPermanentlyDeniedException catch (e) {
      if (mounted) {
        showPermissionDialog(context, _permissionService, e);
      }
    } catch (e) {
      debugPrint("Lỗi khởi tạo: $e");
      _useFallbackLocation();
    }
  }

  void _onMyLocationPressed() {
    setState(() => _isAutoCenter = true);
    if (_currentCenter != null) {
      animatedMapMove(
        _mapController,
        this,
        _currentCenter!,
        _mapController.camera.zoom,
      );
    } else {
      debugPrint('_onMyLocationPressed: currentCenter is null');
      // _startLiveTracking();
    }
  }

  void _useFallbackLocation() async {
    if (!mounted) return;
    setState(() {
      _currentCenter ??= _defaultLocation;
      _isLoading = false;
      _calculateMetrics();
    });
    final addr = await _updateAddress(_defaultLocation);
    if (mounted) setState(() => _currentAddress = addr);
  }

  void _startOrEndLiveActivity() {
    if (_isLocationTracking) {
      _liveActivityService.endLiveActivity();
    } else {
      _initLiveActivity();
      _startLiveTracking();
    }
    setState(() {
      _isLocationTracking = !_isLocationTracking;
    });
  }

  Widget _buildTopPanel() {
    if (_hasArrived) {
      return ArrivalPanel(
        key: const ValueKey("arrival_panel"),
        onFinish: _finishTrip,
      );
    }

    if (_isLocationTracking) {
      return MapInfoPanel(
        key: const ValueKey("map_info_panel"),
        distanceInMeters: _distanceInMeters,
        currentAddress: _currentAddress,
        destinationAddress: _destinationAddress,
        currentCenter: _currentCenter,
        destination: _destination,
      );
    }

    return const SizedBox.shrink(key: ValueKey("empty_panel"));
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
                  if (hasGesture) setState(() => _isAutoCenter = false);
                },
              ),
              children: [
                openStreetMapTileLayer,
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [_currentCenter!, _destination],
                      strokeWidth: 4,
                      color: Colors.blue,
                    ),
                  ],
                ),
                if (_currentCenter != null)
                  MarkerLayer(
                    markers: [
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

                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: SafeArea(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _buildTopPanel(),
                    ),
                  ),
                ),

                const FlutterMapZoomButtons(
                  minZoom: 4,
                  maxZoom: 19,
                  mini: true,
                  padding: 10,
                  alignment: Alignment.bottomLeft,
                ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: _onMyLocationPressed,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _startOrEndLiveActivity,
            child: Icon(
              _isLocationTracking
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
            ),
          ),
        ],
      ),
    );
  }
}
