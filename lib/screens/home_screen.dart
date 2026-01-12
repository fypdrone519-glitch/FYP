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
                      'Find your next ride',
                      style: AppTextStyles.h1(
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
                        // Search Bar
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.iconsBackground,
                            borderRadius: BorderRadius.circular(26),
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
                        Container(
                          width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(
                            color: AppColors.iconsBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.border,
                              width: 1,
                            ),
                          ),
                          child: const DateRangePicker(),
                          // child: Container(
                          //   alignment: Alignment.center,
                          //   child: Padding(
                          //     padding: const EdgeInsets.all(8.0),
                          //     child: Row(
                          //       mainAxisSize: MainAxisSize.min,
                          //       children: [
                          //         // Start Date Section
                          //         Padding(
                          //           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          //           child: Row(
                          //             children: [
                          //               Icon(
                          //                 Icons.calendar_today,
                          //                 size: 16,
                          //                 color: AppColors.white,
                          //               ),
                          //               const SizedBox(width: 8),
                          //               Column(
                          //                 crossAxisAlignment: CrossAxisAlignment.start,
                          //                 mainAxisSize: MainAxisSize.min,
                          //                 children: [
                          //                   Text(
                          //                     'Nov 22, 10:00',
                          //                     style: TextStyle(
                          //                       color: Colors.white,
                          //                       fontSize: 14,
                          //                       fontWeight: FontWeight.w500,
                          //                     ),
                          //                   ),
                          //                 ],
                          //               ),
                          //             ],
                          //           ),
                          //         ),
                          //         Container(
                          //           height: 20,
                          //           width: 20,
                          //           decoration: BoxDecoration(
                          //             borderRadius: BorderRadius.circular(8),
                          //             border: Border.all(
                          //               color: AppColors.border,
                          //             ),
                          //           ),
                          //           child: Padding(
                          //             padding: const EdgeInsets.symmetric(horizontal: 1),
                          //             child: Icon(
                          //               Icons.arrow_forward,
                          //               size: 16,
                          //               color: Colors.white54,
                          //             ),
                          //           ),
                          //         ),
                          //         // End Date Section
                          //         Padding(
                          //           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          //           child: Row(
                          //             children: [
                          //               Icon(
                          //                 Icons.calendar_today,
                          //                 size: 16,
                          //                 color: Colors.white,
                          //               ),
                          //               const SizedBox(width: 8),
                          //               Column(
                          //                 crossAxisAlignment: CrossAxisAlignment.start,
                          //                 mainAxisSize: MainAxisSize.min,
                          //                 children: [
                          //                   Text(
                          //                     'Nov 25, 13:00',
                          //                     style: TextStyle(
                          //                       color: Colors.white,
                          //                       fontSize: 14,
                          //                       fontWeight: FontWeight.w500,
                          //                     ),
                          //                   ),
                          //                 ],
                          //               ),
                          //             ],
                          //           ),
                          //         ),
                          //       ],
                          //     ),
                          //   ),
                          // ),
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
              minChildSize: 0.5, // Minimum 30% of screen height
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

class DateRangePicker extends StatefulWidget {
  const DateRangePicker({Key? key}) : super(key: key);

  @override
  State<DateRangePicker> createState() => _DateRangePickerState();
}

class _DateRangePickerState extends State<DateRangePicker> {
  DateTime? startDate;
  TimeOfDay? startTime;
  DateTime? endDate;
  TimeOfDay? endTime;

  String get formattedStartDateTime {
    if (startDate == null || startTime == null) return 'Select Start';
    return '${_formatDate(startDate!)} ${startTime!.format(context)}';
  }

  String get formattedEndDateTime {
    if (endDate == null || endTime == null) return 'Select End';
    return '${_formatDate(endDate!)} ${endTime!.format(context)}';
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  Future<void> _selectStartDateTime() async {
    // First, pick the date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.cardSurface,
              surface: AppColors.iconsBackground,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      // Then, pick the time
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: startTime ?? TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.dark(
                primary: AppColors.cardSurface,
                surface: AppColors.iconsBackground,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          startDate = pickedDate;
          startTime = pickedTime;
          
          // Clear end date if it's before start date
          if (endDate != null && endDate!.isBefore(pickedDate)) {
            endDate = null;
            endTime = null;
          }
        });
      }
    }
  }

  Future<void> _selectEndDateTime() async {
    if (startDate == null || startTime == null) {
      // Show a message that start date must be selected first
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select start date and time first'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // First, pick the date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: endDate ?? startDate!,
      firstDate: startDate!,
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.cardSurface,
              surface: AppColors.iconsBackground,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      // Then, pick the time
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: endTime ?? TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.dark(
                primary: AppColors.cardSurface,
                surface: AppColors.iconsBackground,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        // Validate that end time is after start time
        final startDateTime = DateTime(
          startDate!.year,
          startDate!.month,
          startDate!.day,
          startTime!.hour,
          startTime!.minute,
        );
        final endDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        if (endDateTime.isAfter(startDateTime)) {
          setState(() {
            endDate = pickedDate;
            endTime = pickedTime;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('End date/time must be after start date/time'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.iconsBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Container(
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Start Date Section - CLICKABLE
              InkWell(
                onTap: _selectStartDateTime,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppColors.white,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formattedStartDateTime,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Arrow Container
              Container(
                height: 20,
                width: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.border,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: Colors.white54,
                  ),
                ),
              ),
              
              // End Date Section - CLICKABLE
              InkWell(
                onTap: _selectEndDateTime,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            formattedEndDateTime,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}