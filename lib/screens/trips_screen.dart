import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Text(
                'Activity',
                style: TextStyle(
                  fontSize: screenHeight * 0.032,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),

            // Tab Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey[600],
                  labelStyle: TextStyle(
                    fontSize: screenHeight * 0.018,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: const [
                    Tab(text: 'Upcoming'),
                    Tab(text: 'History'),
                  ],
                ),
              ),
            ),

            SizedBox(height: screenHeight * 0.02),

            // Tab Bar View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildUpcomingTab(screenHeight, screenWidth),
                  _buildHistoryTab(screenHeight, screenWidth),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingTab(double screenHeight, double screenWidth) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Header
          Text(
            'October 2023',
            style: TextStyle(
              fontSize: screenHeight * 0.02,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          SizedBox(height: screenHeight * 0.02),

          // Reservation Card
          _buildReservationCard(
            screenHeight: screenHeight,
            screenWidth: screenWidth,
            carName: 'Porsche Taycan',
            dateRange: 'Oct. 5 - 8, 2023',
            price: '\$700',
            imageUrl: 'https://via.placeholder.com/100x80',
            location: 'Crosby St. NY, New York City',
            isUpcoming: true,
          ),

          SizedBox(height: screenHeight * 0.03),

          // Month Header
          Text(
            'September 2023',
            style: TextStyle(
              fontSize: screenHeight * 0.02,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          SizedBox(height: screenHeight * 0.02),

          // Reservation Card
          _buildReservationCard(
            screenHeight: screenHeight,
            screenWidth: screenWidth,
            carName: 'Porsche Taycan',
            dateRange: 'Oct. 5 - 8, 2023',
            price: '\$700',
            imageUrl: 'https://via.placeholder.com/100x80',
            location: 'Crosby St. NY, New York City',
            isUpcoming: true,
          ),

          SizedBox(height: screenHeight * 0.02),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(double screenHeight, double screenWidth) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenHeight * 0.012,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: Colors.grey[600], size: 20),
                SizedBox(width: screenWidth * 0.02),
                Expanded(
                  child: Text(
                    'Search with car model, date or location',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: screenHeight * 0.016,
                    ),
                  ),
                ),
                Icon(Icons.tune, color: Colors.grey[600], size: 20),
              ],
            ),
          ),

          SizedBox(height: screenHeight * 0.03),

          // Section Header
          Text(
            'Reservation History',
            style: TextStyle(
              fontSize: screenHeight * 0.024,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          SizedBox(height: screenHeight * 0.02),

          // Date Range
          Text(
            'October 5 - 30, 2023',
            style: TextStyle(
              fontSize: screenHeight * 0.018,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),

          SizedBox(height: screenHeight * 0.02),

          // History Cards
          _buildHistoryCard(
            screenHeight: screenHeight,
            screenWidth: screenWidth,
            carName: 'Porsche Taycan',
            dateRange: 'Oct. 5 - 8, 2023',
            price: '\$700',
            status: 'Completed',
            imageUrl: 'https://via.placeholder.com/100x80',
          ),

          SizedBox(height: screenHeight * 0.015),

          _buildHistoryCard(
            screenHeight: screenHeight,
            screenWidth: screenWidth,
            carName: 'Porsche 718',
            dateRange: 'Oct. 15 - 16, 2023',
            price: '\$560',
            status: 'Completed',
            imageUrl: 'https://via.placeholder.com/100x80',
          ),

          SizedBox(height: screenHeight * 0.015),

          _buildHistoryCard(
            screenHeight: screenHeight,
            screenWidth: screenWidth,
            carName: 'Porsche Cayenne',
            dateRange: 'Oct. 25 - 30, 2023',
            price: '\$1700',
            status: 'Completed',
            imageUrl: 'https://via.placeholder.com/100x80',
          ),

          SizedBox(height: screenHeight * 0.03),

          // Date Range
          Text(
            'September 1 - 17, 2023',
            style: TextStyle(
              fontSize: screenHeight * 0.018,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),

          SizedBox(height: screenHeight * 0.02),

          _buildHistoryCard(
            screenHeight: screenHeight,
            screenWidth: screenWidth,
            carName: 'Porsche 718',
            dateRange: 'Sep. 1, 2023',
            price: '\$0.00',
            status: 'Cancelled',
            imageUrl: 'https://via.placeholder.com/100x80',
          ),

          SizedBox(height: screenHeight * 0.02),
        ],
      ),
    );
  }

  Widget _buildReservationCard({
    required double screenHeight,
    required double screenWidth,
    required String carName,
    required String dateRange,
    required String price,
    required String imageUrl,
    required String location,
    required bool isUpcoming,
  }) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // Car Info Row
          Row(
            children: [
              // Car Image
              Container(
                width: screenWidth * 0.22,
                height: screenHeight * 0.08,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.directions_car, size: 40, color: Colors.grey),
              ),

              SizedBox(width: screenWidth * 0.04),

              // Car Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      carName,
                      style: TextStyle(
                        fontSize: screenHeight * 0.02,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    Text(
                      dateRange,
                      style: TextStyle(
                        fontSize: screenHeight * 0.016,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: screenHeight * 0.018,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: screenHeight * 0.015),

          // Location Info
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              SizedBox(width: screenWidth * 0.01),
              Expanded(
                child: Text(
                  location,
                  style: TextStyle(
                    fontSize: screenHeight * 0.015,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),

          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              SizedBox(width: screenWidth * 0.01),
              Expanded(
                child: Text(
                  location,
                  style: TextStyle(
                    fontSize: screenHeight * 0.015,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: screenHeight * 0.015),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'Cancel Trip',
                    style: TextStyle(
                      fontSize: screenHeight * 0.016,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.edit, size: 16, color: AppColors.accent),
                  label: Text(
                    'Modify',
                    style: TextStyle(
                      fontSize: screenHeight * 0.016,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent.withOpacity(0.1),
                    foregroundColor: AppColors.accent,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard({
    required double screenHeight,
    required double screenWidth,
    required String carName,
    required String dateRange,
    required String price,
    required String status,
    required String imageUrl,
  }) {
    final isCompleted = status == 'Completed';
    
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          // Car Image
          Container(
            width: screenWidth * 0.18,
            height: screenHeight * 0.07,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.directions_car, size: 35, color: Colors.grey),
          ),

          SizedBox(width: screenWidth * 0.04),

          // Car Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  carName,
                  style: TextStyle(
                    fontSize: screenHeight * 0.019,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: screenHeight * 0.005),
                Text(
                  dateRange,
                  style: TextStyle(
                    fontSize: screenHeight * 0.015,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: screenHeight * 0.005),
                Row(
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: screenHeight * 0.016,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: screenHeight * 0.015,
                        fontWeight: FontWeight.w600,
                        color: isCompleted ? AppColors.accent : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Rebook Button
          OutlinedButton.icon(
            onPressed: () {},
            icon: Icon(Icons.refresh, size: 16, color: AppColors.accent),
            label: Text(
              'Rebook',
              style: TextStyle(
                fontSize: screenHeight * 0.015,
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.03,
                vertical: screenHeight * 0.01,
              ),
              side: BorderSide(color: AppColors.accent),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
