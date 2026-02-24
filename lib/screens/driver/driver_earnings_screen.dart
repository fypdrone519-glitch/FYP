import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

class DriverEarningsScreen extends StatelessWidget {
  const DriverEarningsScreen({super.key});

  final double totalEarnings = 18500.0;
  final List<Map<String, dynamic>> earnings = const [
    {'date': '2026-02-01', 'amount': 2500.0, 'trip': 'Toyota Corolla'},
    {'date': '2026-02-02', 'amount': 4000.0, 'trip': 'Honda Civic'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.hostBackground,
      appBar: AppBar(
        title: const Text(
          'EARNINGS',
          style: TextStyle(
            color: AppColors.lightText,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primaryText,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md,
                horizontal: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryText,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Total Earnings',
                      style: AppTextStyles.h2(context).copyWith(
                        color: Colors.white,
                        fontSize: 18,
                      ), // Reduced size
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'PKR ${totalEarnings.toStringAsFixed(0)}',
                      style: AppTextStyles.h1(context).copyWith(
                        color: Colors.green,
                        fontSize: 22,
                      ), // Reduced size
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: ListView.builder(
                itemCount: earnings.length,
                itemBuilder: (context, index) {
                  final earning = earnings[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.monetization_on),
                      title: Text('Trip: ${earning['trip']}'),
                      subtitle: Text(
                        'Date: ${earning['date']}\nAmount: PKR ${earning['amount']}',
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
