import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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

  Set<Marker> get _markers {
    return widget.cars.map((car) {
      return Marker(
        markerId: MarkerId(car.id),
        position: LatLng(car.latitude!, car.longitude!),
        infoWindow: InfoWindow(title: car.fullName),
        onTap: () => widget.onCarTap(car),
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(24.8607, 67.0011),
        zoom: 12,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
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
    );
  }
}
