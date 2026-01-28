import 'package:car_listing_app/screens/main_navigation.dart';
import 'package:car_listing_app/screens/profile_screen.dart';
import 'package:car_listing_app/theme/app_colors.dart';
import 'package:flutter/material.dart';

class KycSuccessScreen extends StatelessWidget {
  const KycSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.foreground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              "KYC Completed",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text("Your documents are under review."),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                builder: (context) => const MainNavigation(),
              )),
              child: const Text("Back to Profile", style: TextStyle(color: AppColors.lightText,fontSize: 16),),
            ),
          ],
        ),
      ),
    );
  }
}
