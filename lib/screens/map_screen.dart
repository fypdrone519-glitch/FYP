import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/car.dart';
import '../widgets/cars_map.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class MapsScreen extends StatelessWidget {
  const MapsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: MapScreenContent());
  }
}

class MapScreenContent extends StatefulWidget {
  const MapScreenContent({super.key});

  @override
  State<MapScreenContent> createState() => _MapScreenContentState();
}

class _MapScreenContentState extends State<MapScreenContent> {
  final List<Car> _allCars = [
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

  List<Car> _visibleCars = [];

  void _updateVisibleCars(LatLngBounds bounds) {
    setState(() {
      _visibleCars =
          _allCars.where((car) {
            final lat = car.latitude!;
            final lng = car.longitude!;
            return lat >= bounds.southwest.latitude &&
                lat <= bounds.northeast.latitude &&
                lng >= bounds.southwest.longitude &&
                lng <= bounds.northeast.longitude;
          }).toList();
    });
  }

  void _openCarSheet(Car car) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.45,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.foreground,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.cardRadius),
                ),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // Image placeholder
                    Container(
                      height: 220,
                      width: double.infinity,
                      color: AppColors.border,
                      child: const Center(
                        child: Icon(Icons.car_rental, size: 80),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Text(
                        car.fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
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
            cars: _allCars,
            onCarTap: _openCarSheet,
            onBoundsChanged: _updateVisibleCars,
          ),

          // 🚗 Bottom floating horizontal cards
          if (_visibleCars.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _visibleCars.length,
                itemBuilder: (context, index) {
                  final car = _visibleCars[index];
                  return GestureDetector(
                    onTap: () => _openCarSheet(car),
                    child: Container(
                      width: 220,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            car.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          Text(
                            'Rs ${car.pricePerDay.toStringAsFixed(0)}/day',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent,
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
