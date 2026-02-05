import 'package:car_listing_app/screens/notifications_screen.dart';
import 'package:flutter/material.dart';
import '../models/car.dart';
import '../models/car_filter_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';
import '../widgets/car_card.dart';
import '../widgets/car_filter_bottom_sheet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  List<Car> _cars = [];
  List<Car> _allCars = []; // Store all cars for filtering
  bool _isLoading = true;
  CarFilterModel _filters = CarFilterModel();
  
  // Firebase instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadCars();
  }

  Future<void> _loadCars() async {
    try {
      final QuerySnapshot vehiclesSnapshot = await _firestore
          .collection('vehicles')
          .get();

      final List<Car> cars = vehiclesSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Get features - take first 3
        List<String> features = [];
        if (data['features'] != null && data['features'] is List) {
          features = List<String>.from(data['features']).take(3).toList();
        }
        
        // Get location
        double? latitude;
        double? longitude;
        if (data['location'] != null) {
          final location = data['location'] as Map<String, dynamic>;
          latitude = (location['latitude'] as num?)?.toDouble();
          longitude = (location['longitude'] as num?)?.toDouble();
        }
        
        // Get rent per day
        double rentPerDay = 0.0;
        if (data['rent_per_day'] != null) {
          rentPerDay = (data['rent_per_day'] as num).toDouble();
        }
        //Get rent per hour
        double rentPerHour = 0.0;
        if (data['rent_per_hour'] != null) {
          rentPerHour = (data['rent_per_hour'] as num).toDouble();
        }
        
        // Get first image URL
        String imageUrl = '';
        if (data['images'] != null && data['images'] is List && data['images'].isNotEmpty) {
          imageUrl = data['images'][0] as String;
        }
        
        // Get additional filter fields
        final drivingOptions = data['driving_options'] as String?;
        final transmissionType = data['transmissionType'] as String?;
        final fuelType = data['fuel_type'] as String?;
        
        return Car(
          id: doc.id,
          make: data['make'] ?? '',
          model: data['car_name'] ?? '', // car_name is used as model so fullName will be "make car_name"
          imageUrl: imageUrl, // Use the first image URL
          rating: 0.0, // Default value
          trips: 0, // Default value
          pricePerDay: rentPerDay,
          pricePerHour: rentPerHour,
          features: features,
          badges: [], // Default empty
          latitude: latitude,
          longitude: longitude,
          drivingOptions: drivingOptions,
          transmissionType: transmissionType,
          fuelType: fuelType,
        );
      }).toList();

      setState(() {
        _allCars = cars;
        _cars = _applyFilters(cars, _filters);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading cars: $e')),
        );
      }
    }
  }

  List<Car> _applyFilters(List<Car> cars, CarFilterModel filters) {
    List<Car> filtered = cars;

    // Filter by price range
    filtered = filtered.where((car) {
      return car.pricePerDay >= filters.minPrice && 
             car.pricePerDay <= filters.maxPrice;
    }).toList();

    // Filter by price per hour range
    // filtered = filtered.where((car) {
    //   return car.pricePerHour >= filters.minPrice && 
    //          car.pricePerHour <= filters.maxPrice;
    // }).toList();
    // Filter by brand
    if (filters.selectedBrands.isNotEmpty) {
      filtered = filtered.where((car) {
        return filters.selectedBrands.contains(car.make);
      }).toList();
    }

    // Filter by location (text search - would need additional location text field)
    // For now, we'll skip location filtering as it requires location text data
    // TODO: Add location text field to database/model if needed

    // Filter by drive type
    if (filters.driveTypes.isNotEmpty) {
      filtered = filtered.where((car) {
        if (car.drivingOptions == null) return false;
        
        // Check if car's driving_options matches any selected filter
        if (filters.driveTypes.contains('Self Driving') && 
            filters.driveTypes.contains('With Driver')) {
          // User selected both, accept any car with either
          return car.drivingOptions == 'Self Driving' || 
                 car.drivingOptions == 'With Driver' || 
                 car.drivingOptions == 'Both';
        } else if (filters.driveTypes.contains('Self Driving')) {
          return car.drivingOptions == 'Self Driving'|| car.drivingOptions == 'Both';
        } else if (filters.driveTypes.contains('With Driver')) {
          return car.drivingOptions == 'With Driver';
        }
        return false;
      }).toList();
    }

    // Filter by transmission
    if (filters.transmission != null) {
      filtered = filtered.where((car) {
        return car.transmissionType == filters.transmission;
      }).toList();
    }

    // Filter by fuel type
    if (filters.fuelTypes.isNotEmpty) {
      filtered = filtered.where((car) {
        if (car.fuelType == null) return false;
        return filters.fuelTypes.contains(car.fuelType);
      }).toList();
    }

    // Filter by delivery options
    // Note: Delivery options would need to be stored in the database
    // For now, we check badges for 'Delivery' badge if user selects 'Delivers to Me'
    if (filters.deliveryOptions.isNotEmpty) {
      filtered = filtered.where((car) {
        if (filters.deliveryOptions.contains('Delivers to Me')) {
          return car.badges.contains('Delivery');
        }
        // If user selects 'Pickup', we don't filter (all cars can be picked up)
        return true;
      }).toList();
    }

    return filtered;
  }

  Future<void> _showFilterBottomSheet() async {
    final result = await showModalBottomSheet<CarFilterModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CarFilterBottomSheet(
        initialFilters: _filters,
      ),
    );

    if (result != null) {
      setState(() {
        _filters = result;
        _cars = _applyFilters(_allCars, _filters);
      });
    }
  }

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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return NotificationsScreen();
                              },
                            ),
                          );
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
                                  style: const TextStyle(
                                    color: AppColors.secondaryText,
                                    fontSize: 16,      
                                  ),
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
                                child: Stack(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.tune,
                                        color: AppColors.secondaryText,
                                      ),
                                      onPressed: _showFilterBottomSheet,
                                    ),
                                    if (_filters.hasActiveFilters)
                                      Positioned(
                                        right: 8,
                                        top: 8,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: AppColors.accent,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                  ],
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
                        child: _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(),
                              )
                            : _cars.isEmpty
                                ? const Center(
                                    child: Text('No vehicles found'),
                                  )
                                : ListView.builder(
                                    controller: scrollController,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                    ),
                                    itemCount: _cars.length,
                                    itemBuilder: (context, index) {
                                      return CarCard(
                                        car: _cars[index],
                                        onTap: () {
                                          
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