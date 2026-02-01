import 'package:car_listing_app/screens/auth/login_screen.dart';
import 'package:car_listing_app/screens/host_navigation.dart';
import 'package:car_listing_app/screens/kyc_intro_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String verificationStatus = "loading";
  String name = "loading";
  //method to fetch verification status
  Future<void> loadVerificationStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (doc.exists) {
      setState(() {
        verificationStatus = doc.data()?['verification_status'] ?? "unverified";
        print(verificationStatus);
      });
    }
  }
  Future<void> loadname() async {
    print("loading name");
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (doc.exists) {
      setState(() {
        // Assuming the document has a field 'name'
        name = doc.data()?['name'] ?? "No Name";
        print(name);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadVerificationStatus();
    loadname();
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();

      // Navigate to login screen and remove all previous routes
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
                        // Show logout confirmation dialog
                        showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                contentPadding: const EdgeInsets.all(24),
                                title: Center(
                                  child: Text(
                                    'Confirm logout',
                                    style: AppTextStyles.h2(context).copyWith(
                                      //fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Are you sure you want to log out?',
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.body(
                                        context,
                                      ).copyWith(
                                        color: AppColors.secondaryText,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    // Log out button
                                    SizedBox(
                                      width: double.infinity,
                                      height: 48,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(
                                            context,
                                          ); // Close dialog
                                          _logout(context);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.red, // Burgundy/wine color
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: const Text(
                                          'Log out',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // Cancel button
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(
                                          color: AppColors.secondaryText,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
                      'https://ui-avatars.com/api/?name=${name}&size=200&background=19B394&color=fff',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Stack(
                alignment: Alignment.center,
                children: [
                  // Centered Name + Status
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: AppTextStyles.h1(context).copyWith(fontSize: 24),
                      ),
                      TextButton(
                        onPressed: () {
                          if (verificationStatus != "VERIFIED") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const KycVerificationScreen(),
                              ),
                            );
                          }
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
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
                ],
              ),

              const SizedBox(height: AppSpacing.xs),

              // Location
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [
              //     Icon(
              //       Icons.location_on,
              //       size: 16,
              //       color: AppColors.secondaryText,
              //     ),
              //     const SizedBox(width: 4),
              //     Text(
              //       'Karachi',
              //       style: AppTextStyles.meta(context),
              //     ),
              //   ],
              // ),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'General',
                        style: AppTextStyles.h2(context).copyWith(fontSize: 18),
                      ),
                    ),
                    _buildSettingItem(
                      icon: Icons.favorite_border,
                      title: 'Favorite Cars',
                      onTap: () {},
                    ),
                    _buildSettingItem(
                      icon: Icons.how_to_reg_sharp,
                      title: 'Become a Host',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => const HostNavigation(),
                          ),
                        );
                      },
                    ),
                    _buildSettingItem(
                      icon: Icons.dark_mode,
                      title: 'Darkmode',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Payment Method Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Payment Method',
                          style: AppTextStyles.h2(
                            context,
                          ).copyWith(fontSize: 18),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            '+ Add New',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // Credit Card
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF2C3E50), Color(0xFF1A252F)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Card Logo
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: 50,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.transparent,
                                  ),
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        left: 0,
                                        child: Container(
                                          width: 25,
                                          height: 25,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xFFEB001B),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: 15,
                                        child: Container(
                                          width: 25,
                                          height: 25,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xFFF79E1B),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.contactless,
                                  color: Colors.white.withValues(alpha: 0.5),
                                  size: 30,
                                ),
                              ],
                            ),

                            // Card Name
                            Text(
                              'FAWAD NAVEED',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            // Card Number and Balance
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          '•••• 3673',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.copy,
                                          color: Colors.white.withValues(
                                            alpha: 0.5,
                                          ),
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Text(
                                  'Rs 2,912.56',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Recent Transactions
                    Text(
                      'Recent Transactions',
                      style: AppTextStyles.h2(context).copyWith(fontSize: 18),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // Transaction List
                    _buildTransactionItem(
                      date: '10 April, 6:39 am',
                      carModel: 'Tesla model S',
                      duration: '10m 30s',
                      amount: '-Rs103.24',
                    ),
                    const Divider(height: 1),

                    _buildTransactionItem(
                      date: '8 April',
                      carModel: 'Tesla model S',
                      duration: '15m',
                      amount: '-Rs90.05',
                    ),
                    const Divider(height: 1),

                    _buildTransactionItem(
                      date: '6 April',
                      carModel: 'Honda Civic',
                      duration: '8m',
                      amount: '-Rs150.64',
                    ),

                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem({
    required String date,
    required String carModel,
    required String duration,
    required String amount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$carModel • $duration',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildSettingItem({
  required IconData icon,
  required String title,
  required VoidCallback onTap,
}) {
  if (title == 'Darkmode') {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, color: Colors.black87),
      ),
      secondary: Icon(icon, size: 24, color: Colors.black54),
      value: false, // Replace with actual value
      onChanged: (bool value) {
        // Handle dark mode toggle
      },
    );
  }
  return InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
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
