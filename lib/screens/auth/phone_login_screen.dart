import 'package:flutter/material.dart';
import 'package:car_listing_app/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';
import '../../services/auth_service.dart';
import '../main_navigation.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _auth = AuthService();

  String _verificationId = "";
  bool _otpSent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // ================= SEND OTP =================
  Future<void> _sendOTP() async {
    // Validate form before sending OTP
    if (!_formKey.currentState!.validate()) {
      return;
    }

    String phoneNumber = _phoneController.text.trim();

    // Ensure phone number starts with country code
    if (!phoneNumber.startsWith('+')) {
      // If user enters number without +92, add it
      if (phoneNumber.startsWith('0')) {
        phoneNumber = '+92${phoneNumber.substring(1)}';
      } else if (phoneNumber.startsWith('92')) {
        phoneNumber = '+$phoneNumber';
      } else {
        phoneNumber = '+92$phoneNumber';
      }
    }

    setState(() => _isLoading = true);

    await _auth.verifyPhone(
      phone: phoneNumber,
      codeSent: (verificationId) {
        setState(() {
          _verificationId = verificationId;
          _otpSent = true;
          _isLoading = false;
        });
        _showMessage('OTP sent successfully', isError: false);
      },
      onError: (error) {
        setState(() => _isLoading = false);
        _showMessage(error, isError: true);
      },
    );
  }

  // ================= VERIFY OTP =================
  Future<void> _verifyOTP() async {
    if (_otpController.text.trim().isEmpty) {
      _showMessage('Please enter OTP', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _auth.verifyOTP(_verificationId, _otpController.text);

      if (user != null) {
        // Save user data to Firestore
        await _saveUserDataToFirestore(user.uid);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainNavigation()),
          );
        }
      }
    } catch (e) {
      _showMessage(e.toString(), isError: true);
    }

    setState(() => _isLoading = false);
  }

  // ================= SAVE USER DATA TO FIRESTORE =================
  Future<void> _saveUserDataToFirestore(String uid) async {
    try {
      // Get the formatted phone number
      String phoneNumber = _phoneController.text.trim();
      if (!phoneNumber.startsWith('+')) {
        if (phoneNumber.startsWith('0')) {
          phoneNumber = '+92${phoneNumber.substring(1)}';
        } else if (phoneNumber.startsWith('92')) {
          phoneNumber = '+$phoneNumber';
        } else {
          phoneNumber = '+92$phoneNumber';
        }
      }

      // Check if user document already exists
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        // User exists, update only if name is empty or update the name
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'name': _nameController.text.trim(),
          'phone': phoneNumber,
          'lastLogin': FieldValue.serverTimestamp(),
        });
      } else {
        // New user, create document
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'name': _nameController.text.trim(),
          'phone': phoneNumber,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Log error but don't prevent login
      debugPrint('Error saving user data: $e');
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.cardSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _otpSent ? 'Verify OTP' : 'Phone Login',
                  style: TextStyle(
                    fontSize: screenHeight * 0.036,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _otpSent
                      ? 'Enter the 6-digit code sent to your phone'
                      : 'Sign in with your phone number',
                  style: AppTextStyles.meta(context),
                ),
                const SizedBox(height: AppSpacing.xl),

                if (!_otpSent) ...[
                  // Name Field
                  _buildTextField(
                    controller: _nameController,
                    hint: 'Full Name',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your full name';
                      }
                      if (value.trim().length < 3) {
                        return 'Name must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Phone Field
                  _buildTextField(
                    controller: _phoneController,
                    hint: 'Phone Number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      // Remove spaces and special characters for validation
                      final cleanedValue =
                          value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

                      // Check if it's a valid Pakistani number (with or without country code)
                      final phoneRegex =
                          RegExp(r'^(03[0-9]{9}|(\+92|92)3[0-9]{9})$');
                      if (!phoneRegex.hasMatch(cleanedValue)) {
                        return 'Enter valid Pakistani number (03XXXXXXXXX)';
                      }
                      return null;
                    },
                  ),
                ],

                if (_otpSent) ...[
                  // OTP Field
                  _buildTextField(
                    controller: _otpController,
                    hint: 'Enter OTP',
                    icon: Icons.lock_outline,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter OTP';
                      }
                      if (value.length != 6) {
                        return 'OTP must be 6 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Change Phone Number option
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _otpSent = false;
                                _otpController.clear();
                              });
                            },
                      child: Text(
                        'Change Phone Number',
                        style: AppTextStyles.body(context).copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.xl),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : _otpSent
                            ? _verifyOTP
                            : _sendOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _otpSent ? 'Verify OTP' : 'Send OTP',
                            style: AppTextStyles.button(context).copyWith(
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Sign up link (only show when not in OTP mode)
                if (!_otpSent)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Don\'t have an account? ',
                        style: AppTextStyles.body(context),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          'Sign Up',
                          style: AppTextStyles.body(context).copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.meta(context),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        prefixIcon: Icon(
          icon,
          color: AppColors.secondaryText,
          size: 20,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
      ),
      style: AppTextStyles.body(context),
    );
  }
}