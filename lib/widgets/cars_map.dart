import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/car.dart';
import 'package:geolocator/geolocator.dart';

class CarsMap extends StatefulWidget {
  final List<Car> cars;
  final Function(Car)? onCarMarkerTap;

  const CarsMap({super.key, required this.cars, this.onCarMarkerTap});

  @override
  State<CarsMap> createState() => _CarsMapState();
}

class _CarsMapState extends State<CarsMap> {
  GoogleMapController? _controller;
  LatLng? _userLocation;
  final Set<Marker> _markers = {};

  static const LatLng _fallbackLocation = LatLng(24.8607, 67.0011); // Karachi

  @override
  void initState() {
    super.initState();
    _loadLocation();
    _createMarkers();
  }

  @override
  void didUpdateWidget(covariant CarsMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cars != widget.cars) {
      _createMarkers();
    }
  }

  Future<void> _loadLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _userLocation = LatLng(position.latitude, position.longitude);
    });
  }

  void _createMarkers() {
    _markers.clear();

    for (final car in widget.cars) {
      if (car.latitude == null || car.longitude == null) continue;

      _markers.add(
        Marker(
          markerId: MarkerId(car.id),
          position: LatLng(car.latitude!, car.longitude!),
          onTap: (){
            widget.onCarMarkerTap?.call(car);
          },
          infoWindow: InfoWindow(
            title: '${car.make} ${car.model}',
            snippet: 'Rs ${car.pricePerDay.toStringAsFixed(0)}/day',
          ),
        ),
      );
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Positioned(
        //   top: 40,
        //   right: 20,
        //   child: FloatingActionButton(
        //     heroTag: 'back_btn',
        //     mini: true,
        //     backgroundColor: Colors.white,
        //     onPressed: () {},
        //     child: const Icon(Icons.arrow_back, color: Colors.black),
        //   ),
        // ),
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
        ),
         // 🔙 Back Button (Safe & Visible)
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 12, right: 360),
              child: FloatingActionButton(
                heroTag: 'back_btn',
                mini: false,
                backgroundColor: Colors.white,
                elevation: 3,
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Icon(Icons.arrow_back, color: Colors.black,size: 30,),
              ),
            ),
          ),
        ),

        // 📍 Custom My Location Button (Bottom Left)
        Positioned(
          bottom: 30,
          left: 350,
          child: FloatingActionButton(
            heroTag: 'my_location_btn',
            mini: false,
            backgroundColor: Colors.white,
            onPressed: () {
              if (_userLocation != null && _controller != null) {
                _controller!.animateCamera(
                  CameraUpdate.newLatLngZoom(_userLocation!, 14),
                );
              }
            },
            child: const Icon(Icons.my_location, color: Colors.black,size: 30,),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
