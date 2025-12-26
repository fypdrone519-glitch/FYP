import 'package:flutter/material.dart';
import '../models/car.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';
import '../widgets/car_card.dart';
import '../widgets/cars_map.dart';

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
      features: ['Automatic', 'AC', 'Bluetooth'],
      badges: ['Instant', 'Verified'],
      latitude: 24.8607,
      longitude: 67.0011,
    ),
    Car(
      id: '2',
      make: 'Honda',
      model: 'Civic',
      imageUrl: '',
      rating: 4.9,
      trips: 85,
      pricePerDay: 6000,
      features: ['Automatic', 'AC', 'Navigation'],
      badges: ['Delivery', 'Verified'],
      latitude: 24.8607,
      longitude: 67.0011,
    ),
    Car(
      id: '3',
      make: 'Suzuki',
      model: 'Alto',
      imageUrl: '',
      rating: 4.6,
      trips: 200,
      pricePerDay: 3000,
      features: ['Manual', 'AC'],
      badges: ['Instant'],
      latitude: 24.8607,
      longitude: 67.0011,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.foreground,
      body: SafeArea(
        child: Stack(
          children: [
            // Full Screen Map
            CarsMap(cars: _cars, onCarMarkerTap: (car) {}),

            // Top Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Text(
                      'Cars on Map',
                      style: AppTextStyles.h2(
                        context,
                      ).copyWith(color: AppColors.lightText),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.tune, color: AppColors.lightText),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),

            // Draggable Cards
            DraggableScrollableSheet(
              initialChildSize: 0.35,
              minChildSize: 0.25,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.foreground,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppSpacing.cardRadius),
                      topRight: Radius.circular(AppSpacing.cardRadius),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Drag Handle
                      Container(
                        margin: const EdgeInsets.only(top: AppSpacing.xs),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Cars near you',
                            style: AppTextStyles.h2(context),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          itemCount: _cars.length,
                          itemBuilder: (context, index) {
                            return CarCard(car: _cars[index], onTap: () {});
                          },
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                );
              },
            ),

            // Current Location Button
            Positioned(
              bottom: 120,
              right: AppSpacing.sm,
              child: FloatingActionButton(
                backgroundColor: AppColors.accent,
                onPressed: () {},
                child: const Icon(
                  Icons.my_location,
                  color: AppColors.lightText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
