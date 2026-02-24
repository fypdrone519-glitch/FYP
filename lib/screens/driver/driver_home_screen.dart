import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Import your other driver screens
import 'driver_trips_screen.dart';
import 'driver_trip_history_screen.dart';
import 'driver_earnings_screen.dart';
import 'driver_inbox_screen.dart';
import 'driver_profile_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;

  late final List<Widget> _screens;

  // Dummy driver stats
  final double totalEarnings = 18500.0;
  final int todayTrips = 3;
  final int completedTrips = 25;

  // Dummy trips list
  final List<Map<String, String>> upcomingTrips = [
    {
      'vehicle': 'Toyota Corolla',
      'pickup': 'DHA Phase 5',
      'drop': 'Bahria Town',
      'time': '10:00 AM',
    },
    {
      'vehicle': 'Honda Civic',
      'pickup': 'Gulberg',
      'drop': 'Airport',
      'time': '02:30 PM',
    },
  ];

  @override
  void initState() {
    super.initState();

    _screens = [
      _buildHomeContent(),
      const DriverTripsScreen(),
      const DriverEarningsScreen(),
      const DriverInboxScreen(),
      const DriverProfileScreen(),
    ];

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.hostBackground,
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // ================= HOME CONTENT =================

  Widget _buildHomeContent() {
    final String driverId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.hostBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Driver Dashboard",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('bookings')
                .where('owner_id', isEqualTo: driverId)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings = snapshot.data?.docs ?? [];
          final today = DateTime.now();

          int pending = 0;
          int active = 0;
          int completed = 0;
          int todaysTrips = 0;

          double earnings = 0;
          double todaysEarnings = 0;

          for (var booking in bookings) {
            final data = booking.data() as Map<String, dynamic>;
            final status = data['status'];

            if (status == 'pending') pending++;
            if (status == 'approved' || status == 'started') active++;
            if (status == 'ended') completed++;

            if (status == 'ended') {
              earnings += (data['amount_paid'] ?? 0).toDouble();
            }

            if (data['started_at'] != null) {
              final date = (data['started_at'] as Timestamp).toDate();
              if (date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day) {
                todaysTrips++;
              }
            }

            if (data['ended_at'] != null) {
              final date = (data['ended_at'] as Timestamp).toDate();
              if (date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day) {
                todaysEarnings += (data['amount_paid'] ?? 0).toDouble();
              }
            }
          }

          // Gradient colors for header and circular cards
          const headerGradient = LinearGradient(
            colors: [Color(0xFF09111C), Color(0xFF1C2B3A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

          return Column(
            children: [
              // 🔹 WELCOME CARD (full width, above sheet)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(gradient: headerGradient),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Welcome Back 👋",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pending > 0
                          ? "You have $pending new booking requests"
                          : "No new booking requests",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total Earnings",
                            style: TextStyle(color: Colors.white70),
                          ),
                          Text(
                            "PKR ${earnings.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 🔹 DRAGGABLE SHEET BELOW WELCOME CARD
              Expanded(
                child: DraggableScrollableSheet(
                  initialChildSize: 1,
                  minChildSize: 0.8,
                  maxChildSize: 1,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(20),
                        children: [
                          if (bookings.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.only(bottom: 16),
                                child: Text(
                                  "No bookings yet",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ),

                          _dashboardTile(
                            icon: Icons.notifications,
                            color: Colors.red,
                            title: "Pending Requests",
                            count: pending,
                            onTap: () => setState(() => _currentIndex = 1),
                          ),
                          _dashboardTile(
                            icon: Icons.car_rental,
                            color: Colors.green,
                            title: "Active Rentals",
                            count: active,
                            onTap: () {},
                          ),
                          _dashboardTile(
                            icon: Icons.check_circle,
                            color: Colors.blue,
                            title: "Completed Trips",
                            count: completed,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => const DriverTripHistoryScreen(),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                child: _circularStatCard(
                                  title: "Today's Trips",
                                  value: todaysTrips.toString(),
                                  gradient: headerGradient,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _circularStatCard(
                                  title: "Today's Earnings",
                                  value:
                                      "PKR ${todaysEarnings.toStringAsFixed(0)}",
                                  gradient: headerGradient,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  // ================= NAVIGATION =================

  Widget _buildBottomNavigation() {
    return Opacity(
      opacity: 0.95,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.home_outlined, Icons.home, 'Home', 0),
                _navItem(
                  Icons.directions_car_outlined,
                  Icons.directions_car,
                  'Trips',
                  1,
                ),
                _navItem(
                  Icons.monetization_on_outlined,
                  Icons.monetization_on,
                  'Earnings',
                  2,
                ),
                _navItem(Icons.inbox_outlined, Icons.inbox, 'Inbox', 3),
                _navItem(Icons.person_outline, Icons.person, 'Profile', 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    IconData outlinedIcon,
    IconData filledIcon,
    String label,
    int index,
  ) {
    final bool isSelected = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? filledIcon : outlinedIcon,
              color:
                  isSelected
                      ? const Color(0xFF09111C)
                      : AppColors.secondaryText,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color:
                    isSelected ? AppColors.background : AppColors.secondaryText,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  // ================= STAT CARD =================

  Widget _horizontalStatCard(
    String label,
    String value,
    Color valueColor, {
    Color backgroundColor = Colors.white,
    Color labelColor = Colors.grey,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTextStyles.h2(
              context,
            ).copyWith(fontWeight: FontWeight.bold, color: valueColor),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTextStyles.body(
              context,
            ).copyWith(color: labelColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

Widget _dashboardTile({
  required IconData icon,
  required Color color,
  required String title,
  required int count,
  required VoidCallback onTap,
}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.15),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      trailing:
          count > 0
              ? CircleAvatar(
                radius: 14,
                backgroundColor: color,
                child: Text(
                  count.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              )
              : const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    ),
  );
}

Widget _circularStatCard({
  required String title,
  required String value,
  Gradient gradient = const LinearGradient(
    colors: [Colors.orange, Colors.deepOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
}) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.2),
          ),
          child: Center(
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
