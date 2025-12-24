import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/car.dart';
import '../theme/app_spacing.dart';
import 'package:geolocator/geolocator.dart';

class CarsMap extends StatefulWidget {
  final List<Car> cars;
  final double? initialLatitude;
  final double? initialLongitude;
  final Function(Car)? onCarMarkerTap;
  const CarsMap({
    super.key,
    required this.cars,
    this.initialLatitude,
    this.initialLongitude,
    this.onCarMarkerTap,
  });

  @override
  State<CarsMap> createState() => _CarsMapState();
}

class _CarsMapState extends State<CarsMap> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  // Default location (Karachi, Pakistan)
  static const double _defaultLatitude = 24.8607;
  static const double _defaultLongitude = 67.0011;
  LatLng? _userLocation;
  bool _locationLoaded = false;
  Future<void> _getUserLocation() async {
  LocationPermission permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.deniedForever ||
      permission == LocationPermission.denied) {
    return; // Cannot access location
  }

  Position position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );

  _userLocation = LatLng(position.latitude, position.longitude);

  setState(() {
    _locationLoaded = true;
  });

  _mapController?.animateCamera(
    CameraUpdate.newLatLngZoom(_userLocation!, 14),
  );
}
  @override
  void initState() {
    super.initState();
    _createMarkers();
    _getUserLocation();
  }

  @override
  void didUpdateWidget(CarsMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cars != widget.cars) {
      _createMarkers();
    }
  }

  void _createMarkers() {
    _markers.clear();
    
    for (var car in widget.cars) {
      if (car.latitude != null && car.longitude != null) {
        _markers.add(
          Marker(
            markerId: MarkerId(car.id),
            position: LatLng(car.latitude!, car.longitude!),
            infoWindow: InfoWindow(
              title: car.fullName,
              snippet: 'Rs ${car.pricePerDay.toStringAsFixed(0)}/day • ⭐ ${car.rating.toStringAsFixed(1)}',
            ),
            onTap: () {
              if (widget.onCarMarkerTap != null) {
                widget.onCarMarkerTap!(car);
              }
            },
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double initialLat = widget.initialLatitude ?? _defaultLatitude;
    final double initialLng = widget.initialLongitude ?? _defaultLongitude;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: SizedBox(
        height: 500,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _userLocation ??
                LatLng(
                  widget.initialLatitude ?? _defaultLatitude,
                  widget.initialLongitude ?? _defaultLongitude,
                ),
            zoom: 12.0,
          ),
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          markers: _markers,
          mapType: MapType.normal,
          zoomControlsEnabled: false,
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

