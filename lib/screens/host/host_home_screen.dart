import 'package:car_listing_app/models/car.dart';
import 'package:car_listing_app/theme/app_colors.dart';
import 'package:car_listing_app/theme/app_spacing.dart';
import 'package:car_listing_app/theme/app_text_styles.dart';
import 'package:car_listing_app/widgets/car_card.dart';
import 'package:car_listing_app/widgets/host_car_card.dart';
import 'package:flutter/material.dart';

class HostHomeScreen extends StatefulWidget {
  const HostHomeScreen({super.key});

  @override
  State<HostHomeScreen> createState() => _HostHomeScreenState();
}

class _HostHomeScreenState extends State<HostHomeScreen> {
  // Mock revenue data
  final double totalRevenue = 9852.02;
  
  final List<RevenueCategory> revenueCategories = [
    RevenueCategory(
      name: 'Civic',
      amount: 5712.17,
      color: const Color(0xFF4ECDC4), // Teal
    ),
    RevenueCategory(
      name: 'Corolla',
      amount: 3152.65,
      color: const Color(0xFFFF6B9D), // Pink
    ),
    RevenueCategory(
      name: 'Suzuki',
      amount: 987.20,
      color: const Color(0xFFFFC857), // Yellow/Orange
    ),
  ];
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
  ];

  double get totalAmount => revenueCategories.fold(0.0, (sum, cat) => sum + cat.amount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
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
                            color: AppColors.iconsBackground,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_none,
                            color: AppColors.lightText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Revenue Generated',
                      style: AppTextStyles.h2(
                        context,
                      ).copyWith(color: AppColors.lightText),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  color: AppColors.background,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: Column(
                      children: [
                        // Revenue Breakdown Chart
                        _buildRevenueChart(context),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Scrollable Cars Near You Section (Overlay)
            DraggableScrollableSheet(
              initialChildSize: 0.4, // Start at 40% of screen height
              minChildSize: 0.4, // Minimum 40% of screen height
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
                            'Your Vehicles',
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
                            return HostCarCard(car: _cars[index],onTap: () {
                              
                            },
                            ); // Placeholder for car cards
                          }
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

  Widget _buildRevenueChart(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Revenue Amount
          Text(
            '\$${totalRevenue.toStringAsFixed(2)}',
            style: AppTextStyles.h1(context).copyWith(
              color: AppColors.lightText,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Progress Bar
          _buildProgressBar(context),
          const SizedBox(height: AppSpacing.md),
          
          // Category List
          ...revenueCategories.map((category) {
            final percentage = (category.amount / totalAmount * 100);
            return _buildCategoryItem(
              context,
              category: category,
              percentage: percentage,
            );
          }),
        ],
      ),
    );
  }

Widget _buildProgressBar(BuildContext context) {
  return SizedBox(
    height: 22,
    child: Row(
      children: revenueCategories.asMap().entries.map((entry) {
        final index = entry.key;
        final category = entry.value;
        final percentage = category.amount / totalAmount;
        
        return Expanded(
          flex: (percentage * 100).round(),
          child: Padding(
            padding: EdgeInsets.only(
              right: index < revenueCategories.length - 1 ? 2.0 : 0,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                color: category.color,
              ),
            ),
          ),
        );
      }).toList(),
    ),
  );
}

  Widget _buildCategoryItem(
    BuildContext context, {
    required RevenueCategory category,
    required double percentage,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          // Colored Dot
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: category.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          // Category Name
          Expanded(
            child: Text(
              category.name,
              style: AppTextStyles.body(context).copyWith(
                color: AppColors.lightText,
              ),
            ),
          ),
          // Percentage
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: AppTextStyles.body(context).copyWith(
              color: AppColors.secondaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Revenue Category Model
class RevenueCategory {
  final String name;
  final double amount;
  final Color color;

  RevenueCategory({
    required this.name,
    required this.amount,
    required this.color,
  });
}
