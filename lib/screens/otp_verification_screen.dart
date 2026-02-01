import 'package:car_listing_app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:car_listing_app/screens/upload_documents_screen.dart';
import '../services/kyc_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String email;
  final String? verificationId;

  const OtpVerificationScreen({
    Key? key,
    required this.phoneNumber,
    required this.email,
    this.verificationId,
  }) : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State variables
  bool emailVerified = false;
  bool phoneVerified = false;
  bool isLoading = false;
  bool isResending = false;
  String? verificationId;
  String? errorMessage;
  final KycService _kycService = KycService();

  // OTP Controllers
  final List<TextEditingController> otpControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> otpFocusNodes =
      List.generate(6, (index) => FocusNode());

  @override
  void initState() {
    super.initState();
    verificationId = widget.verificationId;
    _checkInitialEmailVerification();
  }

  @override
  void dispose() {
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var focusNode in otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  // Check if email is already verified
  Future<void> _checkInitialEmailVerification() async {
    await _auth.currentUser?.reload();
    if (_auth.currentUser?.emailVerified ?? false) {
      setState(() {
        emailVerified = true;
      });
    }
  }

  // Verify Phone OTP
  Future<void> verifyPhoneOtp(String smsCode) async {
    if (verificationId == null) {
      setState(() {
        errorMessage = 'Verification ID not found. Please resend OTP.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: smsCode,
      );

      await _linkPhoneCredential(credential);
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Invalid OTP. Please try again.';
      });
    }
  }

  // Link phone credential
  Future<void> _linkPhoneCredential(PhoneAuthCredential credential) async {
    try {
      await _auth.currentUser?.updatePhoneNumber(credential);
      setState(() {
        phoneVerified = true;
        isLoading = false;
        errorMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone verified successfully!')),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to verify phone: ${e.toString()}';
      });
    }
  }

  // Check Email Verification
  Future<void> checkEmailVerification() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await _auth.currentUser?.reload();
      User? user = _auth.currentUser;

      if (user?.emailVerified ?? false) {
        setState(() {
          emailVerified = true;
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email verified successfully!')),
        );
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Email not verified yet. Please check your inbox.';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to check email verification';
      });
    }
  }

  // Continue to next screen
  Future<void> _continueToNextScreen() async {
    if (!emailVerified || !phoneVerified) return;

    setState(() {
      isLoading = true;
    });

    try {
      String uid = _auth.currentUser!.uid;
      await _firestore.collection('users').doc(uid).update({
        'email_verified': true,
        'phone_verified': true,
        'verification_status': 'pending',
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const UploadDocumentsScreen(),
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to update verification status';
      });
    }
  }

  // Get OTP from controllers
  String _getOtpCode() {
    return otpControllers.map((controller) => controller.text).join();
  }

  /// Resend phone OTP and update [verificationId] for verification.
  Future<void> _resendOtp() async {
    if (isResending) return;
    setState(() {
      isResending = true;
      errorMessage = null;
    });
    try {
      final String? newId = await _kycService.sendPhoneOtp(widget.phoneNumber);
      if (!mounted) return;
      setState(() {
        verificationId = newId ?? verificationId;
        isResending = false;
      });
      if (newId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code sent again.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not send code. Check the number and try again.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => isResending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resend failed: $e')),
        );
      }
    }
  }

  Widget _buildOtpBox(int index) {
    return Container(
      width: 48,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: otpControllers[index].text.isEmpty
              ? const Color(0xFFE5E7EB)
              : const Color(0xFF6366F1),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: otpControllers[index],
        focusNode: otpFocusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: Color(0xFF333333),
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
        ),
        onChanged: (value) {
          if (value.length == 1 && index < 5) {
            FocusScope.of(context).requestFocus(otpFocusNodes[index + 1]);
          } else if (value.isEmpty && index > 0) {
            FocusScope.of(context).requestFocus(otpFocusNodes[index - 1]);
          }
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
    ),
    body: SafeArea(
      child: SingleChildScrollView( // Add this wrapper
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title
              const Text(
                'Verify Your Contact Details',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Subtitle
              const Text(
                'We have sent you the code on the following number',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Phone Number with Edit Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.phoneNumber,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.edit,
                    size: 20,
                    color: Colors.blue.shade700,
                  ),
                ],
              ),
              const SizedBox(height: 32), // Reduced from 40

              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  6,
                  (index) => _buildOtpBox(index),
                ),
              ),
              const SizedBox(height: 20), // Reduced from 32

              // Error Message
              if (errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    errorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Phone Verification Section (Move this UP)
              _buildVerificationCard(
                title: 'Phone Verification',
                description: 'Enter the 6-digit code sent to your phone',
                isVerified: phoneVerified,
                buttonText: 'Verify Phone OTP',
                onPressed: () {
                  String otpCode = _getOtpCode();
                  if (otpCode.length == 6) {
                    verifyPhoneOtp(otpCode);
                  } else {
                    setState(() {
                      errorMessage = 'Please enter complete 6-digit OTP';
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Email Verification Section
              _buildVerificationCard(
                title: 'Email Verification',
                description: 'Check your email: ${widget.email}',
                isVerified: emailVerified,
                buttonText: 'Check Email Verification',
                onPressed: checkEmailVerification,
              ),
              const SizedBox(height: 20), // Reduced from 24

              // Resend OTP
              TextButton(
                onPressed: isResending ? null : _resendOtp,
                child: isResending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Didn\'t receive code? Resend',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.accent,
                        ),
                      ),
              ),

              const SizedBox(height: 24), // Fixed spacing instead of Spacer

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (emailVerified && phoneVerified && !isLoading)
                      ? _continueToNextScreen
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24), // Add bottom padding
            ],
          ),
        ),
      ),
    ),
  );
}

  // Verification Card Widget
  Widget _buildVerificationCard({
    required String title,
    required String description,
    required bool isVerified,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isVerified ? Colors.green.shade200 : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isVerified ? Icons.check_circle : Icons.cancel,
                color: isVerified ? Colors.green : Colors.red,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isVerified) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onPressed,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.accent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}