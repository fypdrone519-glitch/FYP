import 'package:car_listing_app/screens/kyc_success_screen.dart';
import 'package:car_listing_app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../services/kyc_service.dart';
import '../widgets/kyc_stepper.dart';

class ReviewKycScreen extends StatelessWidget {
  const ReviewKycScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = KycService();
    

    return Scaffold(
      backgroundColor: AppColors.foreground,
      appBar: AppBar(title: const Text("Review KYC")),
      body: FutureBuilder(
        future: service.getKyc(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const KycStepper(currentStep: 3, totalSteps: 3),
                const SizedBox(height: 20),

                Text("Name: ${data['full_name']}"),
                Text("Phone: ${data['phone']}"),
                Text("Email: ${data['email']}"),

                const Spacer(),

                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                      onPressed: () async {
                        try {
                          await service.updateVerificationStatus("verified");

                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const KycSuccessScreen(),
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Failed to submit KYC: $e")),
                          );
                        }
                      },
                      child: const Text("Submit KYC", style: TextStyle(color: AppColors.lightText, fontSize: 16),),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
