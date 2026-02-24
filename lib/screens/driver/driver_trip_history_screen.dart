import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class DriverTripHistoryScreen extends StatelessWidget {
  const DriverTripHistoryScreen({super.key});

  // 🔹 COMPLETED TRIPS
  final List<Map<String, String>> completedTrips = const [
    {
      'vehicle': 'Toyota Corolla',
      'pickup': 'DHA Phase 5',
      'drop': 'Bahria Town',
      'time': 'Yesterday 4:00 PM',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.hostBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryText,
        title: const Text(
          'TRIP HISTORY',
          style: TextStyle(
            color: AppColors.lightText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body:
          completedTrips.isEmpty
              ? const Center(child: Text("No completed trips yet"))
              : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.sm),
                itemCount: completedTrips.length,
                itemBuilder: (context, index) {
                  final trip = completedTrips[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                      title: Text(trip['vehicle']!),
                      subtitle: Text(
                        'Pickup: ${trip['pickup']}\n'
                        'Drop: ${trip['drop']}\n'
                        'Time: ${trip['time']}',
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
    );
  }
}
