import 'package:car_listing_app/screens/auth/login_screen.dart';
import 'package:car_listing_app/screens/driver/driver_navigation.dart';
import 'package:car_listing_app/services/unread_message_service.dart';
import 'package:car_listing_app/theme/app_colors.dart';
import 'package:car_listing_app/theme/app_spacing.dart';
import 'package:car_listing_app/theme/app_text_styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  String verificationStatus = "loading";
  String name = "loading";

  Future<void> loadDriverData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (doc.exists) {
      setState(() {
        verificationStatus = doc.data()?['verification_status'] ?? "unverified";
        name = doc.data()?['name'] ?? "No Name";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadDriverData();
  }

  Future<void> _logout(BuildContext context) async {
    try {
      UnreadMessageService().stopListening();
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error logging out: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.foreground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => _logoutDialog(context),
                        );
                      },
                      icon: const Icon(Icons.logout, color: Colors.red),
                    ),
                  ],
                ),
              ),

              // Profile Picture
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.border,
                  image: DecorationImage(
                    image: NetworkImage(
                      'https://ui-avatars.com/api/?name=$name&size=200&background=19B394&color=fff',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              Column(
                children: [
                  Text(
                    name,
                    style: AppTextStyles.h1(context).copyWith(fontSize: 24),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      verificationStatus == "VERIFIED"
                          ? "Verified"
                          : "Not Verified",
                      style: TextStyle(
                        color:
                            verificationStatus == "VERIFIED"
                                ? Colors.blue
                                : Colors.orange,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Driver Settings Section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Driver Settings',
                        style: AppTextStyles.h2(context).copyWith(fontSize: 18),
                      ),
                    ),
                    _buildSettingItem(
                      icon: Icons.directions_car,
                      title: 'My Trips',
                      onTap: () {},
                    ),
                    _buildSettingItem(
                      icon: Icons.monetization_on,
                      title: 'My Earnings',
                      onTap: () {},
                    ),
                    _buildSettingItem(
                      icon: Icons.dark_mode,
                      title: 'Darkmode',
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logoutDialog(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(24),
      title: Center(
        child: Text('Confirm logout', style: AppTextStyles.h2(context)),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Are you sure you want to log out?',
            textAlign: TextAlign.center,
            style: AppTextStyles.body(
              context,
            ).copyWith(color: AppColors.secondaryText),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _logout(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Log out',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.secondaryText, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// Setting Item Widget (SAME STYLE)
Widget _buildSettingItem({
  required IconData icon,
  required String title,
  required VoidCallback onTap,
}) {
  if (title == 'Darkmode') {
    return SwitchListTile(
      title: const Text(
        'Darkmode',
        style: TextStyle(fontSize: 15, color: Colors.black87),
      ),
      secondary: Icon(icon, size: 24, color: Colors.black54),
      value: false,
      onChanged: (bool value) {},
    );
  }

  return InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.black54),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
          const Icon(Icons.chevron_right, size: 24, color: Colors.black26),
        ],
      ),
    ),
  );
}
