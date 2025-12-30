import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/car.dart';
import '../widgets/cars_map.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'package:geolocator/geolocator.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  GoogleMapController? _mapController;
  final List<Car> _cars = [
    Car(
      id: '1',
      make: 'Toyota',
      model: 'Corolla',
      imageUrl: '',
      rating: 4.8,
      trips: 120,
      pricePerDay: 5000,
      features: ['Automatic'],
      badges: ['Instant'],
      latitude: 24.8607,
      longitude: 67.0011,
    ),
    Car(
      id: '2',
      make: 'Honda',
      model: 'Civic',
      imageUrl: '',
      rating: 4.9,
      trips: 80,
      pricePerDay: 6000,
      features: ['Automatic'],
      badges: ['Verified'],
      latitude: 24.865,
      longitude: 67.01,
    ),
  ];

  void _openCarSheet(Car car) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          maxChildSize: 0.95,
          builder: (context, controller) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.foreground,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.cardRadius),
                ),
              ),
              child: ListView(
                controller: controller,
                children: [
                  const SizedBox(height: 12),

                  /// HANDLE
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// IMAGE (FULL WIDTH – FIXED)
                  SizedBox(
                    width: double.infinity,
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child:
                            car.imageUrl.isNotEmpty
                                ? Image.network(car.imageUrl, fit: BoxFit.cover)
                                : Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(
                                    Icons.car_rental,
                                    size: 90,
                                    color: Colors.grey,
                                  ),
                                ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          car.fullName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Karachi, Pakistan',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.lightGreen,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Available • Rs ${car.pricePerDay}/day',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CarsMap(
            cars: _cars,
            onCarTap: _openCarSheet,
            onBoundsChanged: (_) {},
            onMapReady: (controller) {
              _mapController = controller;
            },
          ),

          /// BACK
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FloatingActionButton(
                  heroTag: null,
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: Colors.black),
                ),
              ),
            ),
          ),

          /// LOCATION
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FloatingActionButton(
                  heroTag: null,
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: () async {
                    if (_mapController == null) return;

                    final position = await Geolocator.getCurrentPosition();
                    _mapController!.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(position.latitude, position.longitude),
                        14,
                      ),
                    );
                  },
                  child: const Icon(Icons.my_location, color: Colors.black),
                ),
              ),
            ),
          ),

          /// BOTTOM CARDS
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            height: 260,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _cars.length,
              itemBuilder: (context, index) {
                final car = _cars[index];
                return GestureDetector(
                  onTap: () => _openCarSheet(car),
                  child: Container(
                    width: 260,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// IMAGE (FIXED — FULL WIDTH)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: SizedBox(
                            width: double.infinity,
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child:
                                    car.imageUrl.isNotEmpty
                                        ? Image.network(
                                          car.imageUrl,
                                          fit: BoxFit.cover,
                                        )
                                        : Container(
                                          color: Colors.grey.shade200,
                                          child: const Icon(
                                            Icons.car_rental,
                                            size: 40,
                                            color: Colors.grey,
                                          ),
                                        ),
                              ),
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// ⭐ RATING (unchanged position)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      car.rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                car.fullName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Karachi, Pakistan',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.lightGreen,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Available • Rs ${car.pricePerDay}/day',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
