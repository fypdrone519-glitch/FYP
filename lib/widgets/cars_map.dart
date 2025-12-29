import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/car.dart';

class CarsMap extends StatefulWidget {
  final List<Car> cars;
  final Function(Car) onCarTap;
  final Function(LatLngBounds) onBoundsChanged;

  const CarsMap({
    super.key,
    required this.cars,
    required this.onCarTap,
    required this.onBoundsChanged,
  });

  @override
  State<CarsMap> createState() => _CarsMapState();
}

class _CarsMapState extends State<CarsMap> {
  GoogleMapController? _controller;
  LatLng? _userLocation;

  static const LatLng _fallbackLocation = LatLng(24.8607, 67.0011); // Karachi

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
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
  }

  Set<Marker> get _markers {
    return widget.cars
        .where((car) => car.latitude != null && car.longitude != null)
        .map(
          (car) => Marker(
            markerId: MarkerId(car.id),
            position: LatLng(car.latitude!, car.longitude!),
            infoWindow: InfoWindow(
              title: car.fullName,
              snippet: 'Rs ${car.pricePerDay.toStringAsFixed(0)}/day',
            ),
            onTap: () => widget.onCarTap(car),
          ),
        )
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _userLocation ?? _fallbackLocation,
            zoom: 13,
          ),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          markers: _markers,
          onMapCreated: (controller) {
            _controller = controller;
          },
          onCameraIdle: () async {
            if (_controller == null) return;
            final bounds = await _controller!.getVisibleRegion();
            widget.onBoundsChanged(bounds);
          },
        ),

        // 📍 My Location button (BOTTOM LEFT)
        Positioned(
          bottom: 24,
          left: 16,
          child: FloatingActionButton(
            heroTag: 'my_location_btn',
            backgroundColor: Colors.white,
            onPressed: () {
              if (_userLocation != null && _controller != null) {
                _controller!.animateCamera(
                  CameraUpdate.newLatLngZoom(_userLocation!, 14),
                );
              }
            },
            child: const Icon(Icons.my_location, color: Colors.black),
          ),
        ),
      ],
    );
  }
}
