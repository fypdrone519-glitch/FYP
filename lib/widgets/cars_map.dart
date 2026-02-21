import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/car.dart';
import 'map_pin_widget.dart';

class CarsMap extends StatefulWidget {
  final List<Car> cars;
  final Function(Car) onCarTap;
  final Function(LatLngBounds) onBoundsChanged;
  final void Function(GoogleMapController)? onMapReady;
  final String? selectedCarId; // ID of the currently selected car

  const CarsMap({
    super.key,
    required this.cars,
    required this.onCarTap,
    required this.onBoundsChanged,
    this.onMapReady,
    this.selectedCarId,
  });

  @override
  State<CarsMap> createState() => _CarsMapState();
}

class _CarsMapState extends State<CarsMap> {
  GoogleMapController? _controller;
  LatLng? _userLocation;
  Map<String, BitmapDescriptor> _markerIcons = {};

  static const LatLng _fallbackLocation = LatLng(24.8607, 67.0011); // Karachi

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
    _loadMarkerIcons();
  }

  @override
  void didUpdateWidget(CarsMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload markers when selected car changes
    if (oldWidget.selectedCarId != widget.selectedCarId) {
      _loadMarkerIcons();
    }
  }

  Future<void> _loadMarkerIcons() async {
    final Map<String, BitmapDescriptor> icons = {};

    for (var car in widget.cars) {
      if (car.latitude != null && car.longitude != null) {
        final isSelected = widget.selectedCarId == car.id;
        final icon = await MapPinWidget.createCustomMarker(
          price: car.pricePerDay,
          isSelected: isSelected,
        );
        icons[car.id] = icon;
      }
    }

    if (mounted) {
      setState(() {
        _markerIcons = icons;
      });
    }
  }

  Future<void> _loadUserLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _userLocation = LatLng(position.latitude, position.longitude);
    });
    //move camera to user's location once fetched
    _controller?.animateCamera(CameraUpdate.newLatLngZoom(_userLocation!, 13));
  }

  Set<Marker> get _markers {
    return widget.cars
        .where((car) => car.latitude != null && car.longitude != null)
        .map((car) {
          final icon = _markerIcons[car.id];
          final isSelected = widget.selectedCarId == car.id;

          return Marker(
            markerId: MarkerId(car.id),
            position: LatLng(car.latitude!, car.longitude!),
            icon: icon ?? BitmapDescriptor.defaultMarker,
            onTap: () => widget.onCarTap(car),
            alpha:
                isSelected
                    ? 1.0
                    : 0.5, // Full opacity for selected, 50% for others
            anchor: const Offset(0.5, 0.5), // Center the marker
          );
        })
        .toSet();
  }

  @override
  @override
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(24.8607, 67.0011),
            zoom: 13,
          ),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          markers: _markers,
          onMapCreated: (controller) {
            _controller = controller;
            widget.onMapReady?.call(controller);
          },
          onCameraIdle: () async {
            if (_controller == null) return;
            final bounds = await _controller!.getVisibleRegion();
            widget.onBoundsChanged(bounds);
          },
        ),
      ],
    );
  }
}
