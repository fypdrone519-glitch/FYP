import 'package:car_listing_app/screens/driver/driver_trip_history_screen.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class DriverTripsScreen extends StatelessWidget {
  const DriverTripsScreen({super.key});

  // 🔹 NEW / REQUESTED TRIPS
  final List<Map<String, String>> requestedTrips = const [
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.hostBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryText,
        title: const Text(
          'NEW TRIP REQUESTS',
          style: TextStyle(
            color: AppColors.lightText,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DriverTripHistoryScreen(),
                ),
              );
            },
            child: const Text(
              "History",
              style: TextStyle(
                color: AppColors.lightText,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body:
          requestedTrips.isEmpty
              ? const Center(child: Text("No new trip requests"))
              : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.sm),
                itemCount: requestedTrips.length,
                itemBuilder: (context, index) {
                  final trip = requestedTrips[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.directions_car),
                      title: Text(trip['vehicle']!),
                      subtitle: Text(
                        'Pickup: ${trip['pickup']}\n'
                        'Drop: ${trip['drop']}\n'
                        'Time: ${trip['time']}',
                      ),
                      isThreeLine: true,
                      trailing: ElevatedButton(
                        onPressed: () {
                          // Accept trip logic here
                        },
                        child: const Text("Trip Details"),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
