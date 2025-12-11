import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_training/widgets/zoombuttons_plugin.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geodesy/geodesy.dart';
import 'package:geolocator/geolocator.dart'
    hide LocationServiceDisabledException;
import 'package:flutter_map_training/service/live_activity_map_service.dart';
import 'package:flutter_map_training/service/location_service.dart';
import 'package:flutter_map_training/widgets/tile_layer.dart';
import 'package:flutter_map_training/widgets/map_info_panel.dart';
import 'package:flutter_map_training/widgets/permission_dialog.dart';
import 'package:flutter_map_training/utils/map_helper.dart';
import 'package:flutter_map_training/models/map_live_activity.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final MapController _mapController;
  final LocationService _locationService = LocationService();
  final LiveActivityMapService _liveActivityService = LiveActivityMapService();
  final Geodesy _geodesy = Geodesy();

  final LatLng _defaultLocation = const LatLng(10.762622, 106.660172);
  final LatLng _destination = const LatLng(37.3340, -122.0102);

  LatLng? _currentCenter;
  num? _totalDistanceInMeters;
  final double _initialZoom = 15;
  bool _isLoading = true;
  bool _isAutoCenter = true;
  bool _isLocationTracking = false;

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

    _totalDistanceInMeters = _geodesy.distanceBetweenTwoGeoPoints(
      _defaultLocation,
      _destination,
    );

    _startLiveTracking();
  }

  @override
  void dispose() {
    _liveActivityService.endLiveActivity();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  void _initLiveActivity() {
    _liveActivityService.startLiveActivity(
      data: MapLiveActivity(
        remainingDistanceStr: "Bắt đầu di chuyển",
        progress: 0,
        minutesToArrive: 0,
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
    if (_totalDistanceInMeters == null || _totalDistanceInMeters == 0) return;

    double progressPercent =
        ((_totalDistanceInMeters! - _distanceInMeters) /
            _totalDistanceInMeters!) *
        100;
    int progressInt = progressPercent.clamp(0, 100).toInt();

    String distanceStr = _distanceInMeters > 1000
        ? "${(_distanceInMeters / 1000).toStringAsFixed(2)} km"
        : "${_distanceInMeters.toStringAsFixed(0)} m";

    _liveActivityService.updateLiveActivity(
      data: MapLiveActivity(
        remainingDistanceStr: distanceStr,
        progress: progressInt,
        minutesToArrive: (_distanceInMeters / 500).round(),
      ),
    );

    if (_distanceInMeters < 20) {
      _liveActivityService.endLiveActivity();
    }
  }

  Future<void> _startLiveTracking() async {
    try {
      final hasPermission = await _locationService.checkPermission();
      debugPrint('hasPermission: $hasPermission');
      if (hasPermission) {
        _positionStreamSubscription?.cancel();
        _positionStreamSubscription = _locationService
            .getPositionStream()
            .listen(
              (Position position) async {
                debugPrint('Position: ${position.toJson()}');
                if (!mounted) return;

                final newLocation = LatLng(
                  position.latitude,
                  position.longitude,
                );

                setState(() {
                  _currentCenter = newLocation;
                  _calculateMetrics();
                  _totalDistanceInMeters ??= _distanceInMeters;
                  _updateLiveActivityInfo();
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
    } on LocationPermissionPermanentlyDeniedException {
      if (mounted) {
        showPermissionDialog(context, _locationService);
        _useFallbackLocation();
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
    }
    setState(() {
      _isLocationTracking = !_isLocationTracking;
    });
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

                // Widget đã tách
                Visibility(
                  visible: _isLocationTracking,
                  child: MapInfoPanel(
                    distanceInMeters: _distanceInMeters,
                    currentAddress: _currentAddress,
                    destinationAddress: _destinationAddress,
                    currentCenter: _currentCenter,
                    destination: _destination,
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
