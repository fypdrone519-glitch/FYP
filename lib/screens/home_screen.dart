import 'package:flutter/material.dart';
import '../models/car.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';
import '../widgets/car_card.dart';
import '../widgets/quick_chip.dart';

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  // Sample car data
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Fixed Background Content (First 3 sections)
            Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Share Lane',
                        style: AppTextStyles.h2(
                          context,
                        ).copyWith(color: AppColors.lightText),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Navigate to profile
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: AppColors.lightText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Big Headline
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Find your next ride',
                      style: AppTextStyles.h1(
                        context,
                      ).copyWith(color: AppColors.lightText),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Search Bar Section
                Container(
                  color: AppColors.background,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: Column(
                      children: [
                        // Search Bar
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.cardSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.border,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(
                                      Icons.car_rental,
                                      color: AppColors.secondaryText,
                                    ),
                                    hintText: 'Oshan X7, Honda Civic...',
                                    hintStyle: AppTextStyles.meta(context),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: AppSpacing.sm,
                                    ),
                                  ),
                                ),
                              ),
                              // Filter Icon
                              Padding(
                                padding: const EdgeInsets.only(
                                  right: AppSpacing.xs,
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.tune,
                                    color: AppColors.secondaryText,
                                  ),
                                  onPressed: () {
                                    // Show filter dialog
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // Calendar and Search Button Row
                        Row(
                          children: [
                            Expanded(
                              child: QuickChip(
                                icon: Icons.calendar_today,
                                label: 'Select dates',
                                onTap: () {
                                  // Show date picker
                                },
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: QuickChip(
                                icon: Icons.access_time,
                                label: 'Time',
                                onTap: () {
                                  // Show time picker
                                },
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 28.0),
                          child: Container(
                            height: AppSpacing.minTouchTarget,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  // Perform search
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Center(
                                  child: Text(
                                    'Search',
                                    style: AppTextStyles.button(context),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Scrollable Cars Near You Section (Overlay)
            DraggableScrollableSheet(
              initialChildSize: 0.5, // Start at 40% of screen height
              minChildSize: 0.4, // Minimum 30% of screen height
              maxChildSize: 0.90, // Maximum 95% of screen height
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
                        color: Colors.black.withValues(alpha: 0.1),
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

                      // Section Header
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

                      // Scrollable Car Cards List
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          itemCount: _cars.length,
                          itemBuilder: (context, index) {
                            return CarCard(
                              car: _cars[index],
                              onTap: () {
                                // Navigate to car details
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
