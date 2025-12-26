import 'package:flutter/material.dart';
import '../models/car.dart';
import '../widgets/cars_map.dart';
import '../widgets/car_card.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class MapsScreen extends StatelessWidget {
  const MapsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: MapScreenContent(),);
  }
}

class MapScreenContent extends StatefulWidget {
  const MapScreenContent({super.key});

  @override
  State<MapScreenContent> createState() => _MapScreenContentState();
}

class _MapScreenContentState extends State<MapScreenContent> {
  final List<Car> _cars = [
    Car(
      id: '1',
      make: 'Toyota',
      model: 'Corolla',
      imageUrl: '',
      rating: 4.8,
      trips: 120,
      pricePerDay: 5000,
      features: ['Automatic', 'AC'],
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
          initialChildSize: 0.45,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                //color: const Color.fromARGB(255, 33, 91, 148),
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

                    // Car card
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      child: CarCard(car: car),
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
    return Scaffold(body: CarsMap(cars: _cars, onCarMarkerTap: _openCarSheet));
  }
}
