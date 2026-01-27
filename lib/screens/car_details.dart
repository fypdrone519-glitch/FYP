import 'dart:async';

import 'package:car_listing_app/screens/car_booking_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:table_calendar/table_calendar.dart';

class CarDetails extends StatefulWidget {
  final String vehicleId;

  const CarDetails({super.key, required this.vehicleId});

  @override
  State<CarDetails> createState() => _CarDetailsState();
}

class _CarDetailsState extends State<CarDetails> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? _vehicleData;
  bool _isLoading = true;
  bool _isFavorite = false;
  int _currentImageIndex = 0;
  //for calander
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  Set<DateTime> _availableDates = {}; // Available dates from Firebase
  bool _isLoadingDates = false;

  @override
  void initState() {
    super.initState();
    _loadVehicleData();
  }

  //load dates from the firebase
  Future<void> _loadAvailableDates() async {
    setState(() => _isLoadingDates = true);

    try {
      final vehicleDoc =
          await _firestore.collection('vehicles').doc(widget.vehicleId).get();

      Set<DateTime> availableDates = {};

      if (vehicleDoc.exists) {
        final data = vehicleDoc.data();
        if (data != null && data['availability'] != null) {
          final List<dynamic> availabilityList = data['availability'];

          for (var dateString in availabilityList) {
            if (dateString is String) {
              try {
                final parts = dateString.split('-');
                if (parts.length == 3) {
                  final year = int.parse(parts[0]);
                  final month = int.parse(parts[1]);
                  final day = int.parse(parts[2]);
                  availableDates.add(DateTime(year, month, day));
                }
              } catch (e) {
                print('Error parsing date: $dateString');
              }
            }
          }
        }
      }

      setState(() {
        _availableDates = availableDates;
        _isLoadingDates = false;
      });
    } catch (e) {
      setState(() => _isLoadingDates = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading availability: $e')),
        );
      }
    }
  }

  Future<void> _loadVehicleData() async {
    try {
      final doc =
          await _firestore.collection('vehicles').doc(widget.vehicleId).get();
      if (doc.exists) {
        setState(() {
          _vehicleData = doc.data();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading vehicle: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    if (_vehicleData == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text('Vehicle not found', style: AppTextStyles.h2(context)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    _buildImageCarousel(),
                    _buildCarInfo(),
                    _buildOwnerInfo(),
                    _buildCarFeatures(),
                    _buildReviews(),
                    const SizedBox(height: 100), // Space for button
                  ],
                ),
              ),
            ),
            _buildBookNowButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.lg * 2,
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, size: 20),
            ),
          ),
          Expanded(
            child: Center(
              child: Text('Car Details', style: AppTextStyles.h2(context)),
            ),
          ),
          const SizedBox(width: 40), // Spacer to balance the back button
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    // Default placeholder if no images
    final List<String> images =
        _vehicleData!['images'] != null &&
                (_vehicleData!['images'] as List).isNotEmpty
            ? List<String>.from(_vehicleData!['images'])
            : ['https://via.placeholder.com/400x250?text=No+Image'];

    return Stack(
      children: [
        SizedBox(
          height: 250,
          child: PageView.builder(
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    images[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.directions_car,
                          size: 100,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          top: 16,
          right: 32,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : Colors.grey,
                size: 20,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              images.length,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      _currentImageIndex == index
                          ? Colors.black
                          : Colors.grey[400],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCarInfo() {
    final String make = _vehicleData!['make'] ?? 'Unknown';
    final String model = _vehicleData!['car_name'] ?? 'Model';
    final String streetaddress = _vehicleData!['street_address'] ?? 'street address';
   
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$make $model', style: AppTextStyles.h2(context)),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      '5.0',
                      style: AppTextStyles.body(
                        context,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.star, color: Colors.orange, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '(100+ Review)',
            style: AppTextStyles.meta(context).copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                streetaddress,
                style: AppTextStyles.body(
                  context,
                ).copyWith(color: Colors.grey[600],fontSize: 14),
              ),
            ],
          ),
           const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildOwnerInfo() {
    final String ownerName = _vehicleData!['car_name'] ?? 'Owner Name';
    final String ownerContact = _vehicleData!['owner_contact'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[200],
            child: const Icon(Icons.person, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      ownerName,
                      style: AppTextStyles.body(
                        context,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified, color: Colors.blue, size: 16),
                  ],
                ),
              ],
            ),
          ),
          if (ownerContact.isNotEmpty) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phone, size: 20, color: Colors.grey),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 20,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  // Helper method to get icon and category for feature
  Map<String, dynamic> _getFeatureDetails(String feature) {
    final featureLower = feature.toLowerCase();

    if (featureLower.contains('air conditioning') ||
        featureLower.contains('ac')) {
      return {'icon': Icons.ac_unit, 'category': 'Climate', 'value': feature};
    } else if (featureLower.contains('gps') ||
        featureLower.contains('navigation')) {
      return {'icon': Icons.map, 'category': 'Navigation', 'value': feature};
    } else if (featureLower.contains('bluetooth')) {
      return {
        'icon': Icons.bluetooth,
        'category': 'Connectivity',
        'value': feature,
      };
    } else if (featureLower.contains('wifi') ||
        featureLower.contains('wi-fi')) {
      return {'icon': Icons.wifi, 'category': 'Connectivity', 'value': feature};
    } else if (featureLower.contains('cruise control')) {
      return {'icon': Icons.speed, 'category': 'Advance', 'value': feature};
    } else if (featureLower.contains('child seat')) {
      return {
        'icon': Icons.child_friendly,
        'category': 'Safety',
        'value': feature,
      };
    } else if (featureLower.contains('parking')) {
      return {
        'icon': Icons.local_parking,
        'category': 'Advance',
        'value': feature,
      };
    } else if (featureLower.contains('camera')) {
      return {'icon': Icons.camera_alt, 'category': 'Safety', 'value': feature};
    } else if (featureLower.contains('usb')) {
      return {'icon': Icons.usb, 'category': 'Connectivity', 'value': feature};
    } else if (featureLower.contains('sunroof')) {
      return {'icon': Icons.wb_sunny, 'category': 'Comfort', 'value': feature};
    } else if (featureLower.contains('heated seats')) {
      return {
        'icon': Icons.event_seat,
        'category': 'Comfort',
        'value': feature,
      };
    } else if (featureLower.contains('leather')) {
      return {'icon': Icons.weekend, 'category': 'Interior', 'value': feature};
    } else {
      return {
        'icon': Icons.check_circle_outline,
        'category': 'Feature',
        'value': feature,
      };
    }
  }

  Widget _buildCarFeatures() {
    final List<String> features =
        _vehicleData!['features'] != null
            ? List<String>.from(_vehicleData!['features'])
            : [];

    // If no features, show a message
    if (features.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Car features', style: AppTextStyles.h2(context)),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'No features available',
                style: AppTextStyles.body(context).copyWith(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    // Convert features to display format
    final List<Map<String, dynamic>> displayFeatures =
        features.map((feature) {
          return _getFeatureDetails(feature);
        }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Car features', style: AppTextStyles.h2(context)),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.15,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: displayFeatures.length,
            itemBuilder: (context, index) {
              final feature = displayFeatures[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(feature['icon'], size: 26, color: Colors.grey[700]),
                    const SizedBox(height: 8),
                    Column(
                      children: [
                        Text(
                          feature['category'],
                          style: AppTextStyles.meta(
                            context,
                          ).copyWith(fontSize: 10, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Center(
                          child: Text(
                            feature['value'],
                            style: AppTextStyles.meta(context).copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReviews() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Review (125)', style: AppTextStyles.h2(context)),
              TextButton(
                onPressed: () {
                  // Handle see all
                },
                child: Text(
                  'See All',
                  style: AppTextStyles.body(
                    context,
                  ).copyWith(color: AppColors.accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildReviewCard(
                  'Mr. Jack',
                  '5.0',
                  'The rental car was clean, reliable, and the service was quick and efficient.',
                ),
                const SizedBox(width: 12),
                _buildReviewCard(
                  'Robert',
                  '5.0',
                  'The rental car was clean, and the service was quick.',
                ),
                const SizedBox(width: 12),
                _buildReviewCard(
                  'Sarah',
                  '4.8',
                  'Great experience! Highly recommend.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(String name, String rating, String review) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[300],
                child: const Icon(Icons.person, size: 16, color: Colors.grey),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: AppTextStyles.body(
                    context,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Text(
                      rating,
                      style: AppTextStyles.meta(
                        context,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.star, color: Colors.orange, size: 12),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              review,
              style: AppTextStyles.meta(
                context,
              ).copyWith(color: Colors.grey[600], height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookNowButton() {
    final double rentPerDay =
        (_vehicleData!['rent_per_day'] as num?)?.toDouble() ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => _showAvailabilityCalendar(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Check Availability',
              style: AppTextStyles.button(context),
            ),
          ),
        ),
      ),
    );
  }

  void _showAvailabilityCalendar() async {
    await _loadAvailableDates();

    if (!mounted) return;

    DateTime focusedDay = DateTime.now();
    final DateTime firstDay = DateTime.now();
    final DateTime lastDay = DateTime.now().add(const Duration(days: 365));

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.all(16),
                content: SizedBox(
                  width: 350,
                  height: MediaQuery.of(context).size.height * 0.45,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title
                        // Text(
                        //   'Car Availability',
                        //   style: AppTextStyles.h2(context),
                        // ),
                        // const SizedBox(height: 8),

                        // Calendar Header
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: () {
                                  setDialogState(() {
                                    final newMonth = DateTime(
                                      focusedDay.year,
                                      focusedDay.month - 1,
                                    );
                                    if (newMonth.isAfter(firstDay) ||
                                        isSameDay(newMonth, firstDay)) {
                                      focusedDay = newMonth;
                                    }
                                  });
                                },
                              ),
                              Text(
                                '${_getMonthName(focusedDay.month)} ${focusedDay.year}',
                                style: AppTextStyles.h2(context),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: () {
                                  setDialogState(() {
                                    final newMonth = DateTime(
                                      focusedDay.year,
                                      focusedDay.month + 1,
                                    );
                                    if (newMonth.isBefore(lastDay)) {
                                      focusedDay = newMonth;
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                        // Calendar
                        TableCalendar(
                          firstDay: firstDay,
                          lastDay: lastDay,
                          focusedDay: focusedDay,
                          calendarFormat: CalendarFormat.month,
                          selectedDayPredicate: (day) => false, // No selection
                          onDaySelected: null, // Disable day selection
                          onPageChanged: (newFocusedDay) {
                            setDialogState(() {
                              focusedDay = newFocusedDay;
                            });
                          },
                          calendarBuilders: CalendarBuilders(
                            defaultBuilder: (context, day, focusedDay) {
                              // Check if day is in the availability list (car IS available on these dates)
                              final isAvailable = _availableDates.any(
                                (availableDate) =>
                                    isSameDay(availableDate, day),
                              );

                              return Container(
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color:
                                      isAvailable
                                          ? Colors
                                              .transparent // Available = Normal background
                                          : Colors.white.withOpacity(
                                            0.1,
                                          ), // Not available = Light red tint
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${day.day}',
                                    style: TextStyle(
                                      color:
                                          isAvailable
                                              ? Colors
                                                  .black // Available = Dark/bold text
                                              : Colors.grey.withOpacity(
                                                0.7,
                                              ), // Not available = Light red text
                                      fontWeight:
                                          isAvailable
                                              ? FontWeight
                                                  .w700 // Available = Bold
                                              : FontWeight
                                                  .w400, // Not available = Normal weight
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          calendarStyle: CalendarStyle(
                            todayDecoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            todayTextStyle: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                            ),
                            defaultTextStyle: AppTextStyles.body(context),
                            weekendTextStyle: AppTextStyles.body(context),
                            outsideDaysVisible: false,
                          ),
                          headerVisible: false,
                          daysOfWeekStyle: DaysOfWeekStyle(
                            weekdayStyle: AppTextStyles.meta(
                              context,
                            ).copyWith(fontWeight: FontWeight.w600),
                            weekendStyle: AppTextStyles.meta(
                              context,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                          availableGestures: AvailableGestures.none,
                        ),
                        const SizedBox(height: 16),

                        // Close Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (context) => BookingDetailsScreen(
                                    vehicleData: _vehicleData!,
                                  ), 
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Proceed to Booking ->',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }


  void _proceedToBooking() {
    if (_rangeStart != null && _rangeEnd != null) {
      // Calculate days and total price
      final days = _rangeEnd!.difference(_rangeStart!).inDays + 1;
      final rentPerDay =
          (_vehicleData!['rent_per_day'] as num?)?.toDouble() ?? 0.0;
      final totalPrice = days * rentPerDay;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Selected: ${days} days - Total: \$${totalPrice.toStringAsFixed(2)}',
          ),
        ),
      );

      // TODO: Navigate to booking confirmation screen
    }
  }
}
