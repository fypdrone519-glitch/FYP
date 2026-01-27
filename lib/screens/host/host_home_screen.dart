import 'package:car_listing_app/models/car.dart';
import 'package:car_listing_app/theme/app_colors.dart';
import 'package:car_listing_app/theme/app_spacing.dart';
import 'package:car_listing_app/theme/app_text_styles.dart';
import 'package:car_listing_app/widgets/host_car_card.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  
  List<Car> _cars = [];
  final List<Map<String, dynamic>> _vehicleDataList = [];
  bool _isLoading = true;
  
  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  double get totalAmount => revenueCategories.fold(0.0, (sum, cat) => sum + cat.amount);

  @override
  void initState() {
    super.initState();
    _loadCars();
  }

  Future<void> _loadCars() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final QuerySnapshot vehiclesSnapshot = await _firestore
          .collection('vehicles')
          .where('owner_id', isEqualTo: currentUser.uid)
          .get();
        _vehicleDataList.clear();

      final List<Car> cars = vehiclesSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

       _vehicleDataList.add({
        'id': doc.id,
        ...data, // Store complete data
      });
        
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

        // Get rent per day
        double rentPerhour = 0.0;
        if (data['rent_per_hour'] != null) {
          rentPerhour = (data['rent_per_hour'] as num).toDouble();
        }

         // Get first image URL
        String imageUrl = '';
        if (data['images'] != null && data['images'] is List && data['images'].isNotEmpty) {
          imageUrl = data['images'][0] as String;
        }

        
        return Car(
          id: doc.id,
          make: data['make'] ?? '',
          model: data['car_name'] ?? '', // car_name is used as model so fullName will be "make car_name"
          imageUrl: imageUrl, // Use the first image URL
          rating: 0.0, // Default value
          trips: 0, // Default value
          pricePerDay: rentPerDay,
          pricePerHour: rentPerhour,
          features: features,
          badges: [], // Default empty
          latitude: latitude,
          longitude: longitude,
        );
      }).toList();

      setState(() {
        _cars = cars;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.hostBackground,
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
                        )
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
                      )
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  color: AppColors.hostBackground,
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
              initialChildSize: 0.5, // Start at 50% of screen height
              minChildSize: 0.5, // Minimum 40% of screen height
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
                                      return HostCarCard(
                                        car: _cars[index],
                                        vehicleData: _vehicleDataList[index],
                                        onDataUpdated: (updatedData) {
                                          setState(() {
                                            updatedData['id'] = _cars[index].id;
                                            _vehicleDataList[index] = updatedData;
                                            _cars[index] = Car(
                                            id: updatedData['id'],
                                            make: updatedData['make'] ?? '',
                                            model: updatedData['car_name'] ?? '',
                                            imageUrl: updatedData['images'] != null && (updatedData['images'] as List).isNotEmpty
                                                ? updatedData['images'][0] as String
                                                : '', // set first image
                                            rating: 0.0,
                                            trips: 0,
                                            pricePerDay: (updatedData['rent_per_day'] as num?)?.toDouble() ?? 0.0,
                                            pricePerHour: (updatedData['rent_per_hour'] as num?)?.toDouble() ?? 0.0,
                                            features: updatedData['features'] != null 
                                                ? List<String>.from(updatedData['features']).take(3).toList()
                                                : [],
                                            badges: [],
                                            latitude: updatedData['location']?['latitude'],
                                            longitude: updatedData['location']?['longitude'],
                                          );

                                          });
                                        },
                                        onTap: () {
                                          _loadCars();
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

  Widget _buildRevenueChart(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Revenue Amount
          Text(
            '\PKR ${totalRevenue.toStringAsFixed(2)}',
            style: AppTextStyles.h1(context).copyWith(
              //color: AppColors.lightText,
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
                //color: AppColors.lightText,
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
