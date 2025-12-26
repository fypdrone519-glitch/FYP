import 'package:flutter/material.dart';
import '../models/car.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';

class CarCard extends StatelessWidget {
  final Car car;
  final VoidCallback? onTap;

  const CarCard({super.key, required this.car, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Car Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.cardRadius),
                topRight: Radius.circular(AppSpacing.cardRadius),
              ),
              child: Stack(
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    color: AppColors.border,
                    child:
                        car.imageUrl.isNotEmpty
                            ? Image.network(
                              car.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.car_rental,
                                    size: 60,
                                    color: AppColors.secondaryText,
                                  ),
                                );
                              },
                            )
                            : const Center(
                              child: Icon(
                                Icons.car_rental,
                                size: 60,
                                color: AppColors.secondaryText,
                              ),
                            ),
                  ),
                  // Badges
                  Positioned(
                    top: AppSpacing.sm,
                    left: AppSpacing.sm,
                    child: Wrap(
                      spacing: AppSpacing.xs,
                      children:
                          car.badges.map((badge) {
                            Color badgeColor = AppColors.accent;
                            if (badge == 'Verified') {
                              badgeColor = Colors.blue;
                            } else if (badge == 'Instant') {
                              badgeColor = Colors.orange;
                            }
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: badgeColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                badge,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            // Car Details
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Model Name
                  Text(car.fullName, style: AppTextStyles.carModel(context)),
                  const SizedBox(height: AppSpacing.xs),
                  // Features
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children:
                        car.features.take(3).map((feature) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.foreground,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              feature,
                              style: AppTextStyles.meta(context),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Rating and Trips
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: AppColors.ratingStar,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        car.rating.toStringAsFixed(1),
                        style: AppTextStyles.meta(context),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '(${car.trips} trips)',
                        style: AppTextStyles.meta(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Price and CTA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rs ${car.pricePerDay.toStringAsFixed(0)}/day',
                            style: AppTextStyles.price(context),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(
                            AppSpacing.minTouchTarget,
                            AppSpacing.minTouchTarget,
                          ),
                        ),
                        child: Text(
                          'View details',
                          style: AppTextStyles.button(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
