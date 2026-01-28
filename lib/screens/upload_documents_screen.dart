import 'dart:io';
import 'package:car_listing_app/screens/review_kyc_screen.dart';
import 'package:car_listing_app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/kyc_service.dart';
import '../widgets/upload_card.dart';
import '../widgets/kyc_stepper.dart';

class UploadDocumentsScreen extends StatefulWidget {
  const UploadDocumentsScreen({super.key});

  @override
  State<UploadDocumentsScreen> createState() => _UploadDocumentsScreenState();
}

class _UploadDocumentsScreenState extends State<UploadDocumentsScreen> {
  final picker = ImagePicker();
  final service = KycService();

  File? cnicFront;
  File? cnicBack;
  File? licenceFront;
  File? licenceBack;

Future<File?> pickImage(BuildContext context) async {
  return showModalBottomSheet<File?>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Take Photo"),
              onTap: () async {
                final picked = await picker.pickImage(source: ImageSource.camera);
                Navigator.pop(context, picked != null ? File(picked.path) : null);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Choose from Gallery"),
              onTap: () async {
                final picked = await picker.pickImage(source: ImageSource.gallery);
                Navigator.pop(context, picked != null ? File(picked.path) : null);
              },
            ),
          ],
        ),
      );
    },
  );
}


  Future<void> uploadAndNext() async {
    final data = <String, dynamic>{};
    print(data);

    if (cnicFront != null) data["cnic_front"] = await service.uploadImage(cnicFront!, "cnic_front");
    if (cnicBack != null) data["cnic_back"] = await service.uploadImage(cnicBack!, "cnic_back");
    if (licenceFront != null) data["licence_front"] = await service.uploadImage(licenceFront!, "licence_front");
    if (licenceBack != null) data["licence_back"] = await service.uploadImage(licenceBack!, "licence_back");
    await service.saveData(data);

    if (mounted) {
       Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ReviewKycScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.foreground,
      appBar: AppBar(title: const Text("Upload Documents")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const KycStepper(currentStep: 2, totalSteps: 3),
            const SizedBox(height: 20),

            UploadCard(title: "CNIC Front", file: cnicFront, onPick: () async {
              final f = await pickImage(context);
              if (f != null) setState(() => cnicFront = f);
            }),

            UploadCard(title: "CNIC Back", file: cnicBack, onPick: () async {
              final f = await pickImage(context);
              if (f != null) setState(() => cnicBack = f);
            }),

            UploadCard(title: "Licence Front", file: licenceFront, onPick: () async {
              final f = await pickImage(context);
              if (f != null) setState(() => licenceFront = f);
            }),

            UploadCard(title: "Licence Back", file: licenceBack, onPick: () async {
              final f = await pickImage(context);
              if (f != null) setState(() => licenceBack = f);
            }),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                  onPressed: uploadAndNext,
                  child: const Text("Continue", style: TextStyle(color: AppColors.lightText, fontSize: 16),),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
