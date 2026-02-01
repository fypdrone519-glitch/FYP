import 'dart:io';
import 'package:car_listing_app/screens/upload_documents_screen.dart';
import 'package:car_listing_app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../services/kyc_service.dart';

/// Screen for biometric verification (Face ID on iOS, Fingerprint on Android)
/// This screen appears after OTP verification and before document upload
/// Purpose: Ensure the person completing KYC controls the device
class BiometricVerificationScreen extends StatefulWidget {
  const BiometricVerificationScreen({super.key});

  @override
  State<BiometricVerificationScreen> createState() =>
      _BiometricVerificationScreenState();
}

class _BiometricVerificationScreenState
    extends State<BiometricVerificationScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final KycService _kycService = KycService();

  bool _isVerifying = false;
  bool _canCheckBiometrics = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  /// Check if biometric authentication is available on the device
  Future<void> _checkBiometricAvailability() async {
    try {
      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics ||
          await _localAuth.isDeviceSupported();

      setState(() {
        _canCheckBiometrics = canAuthenticate;
      });

      if (!canAuthenticate) {
        setState(() {
          _errorMessage = 'Biometric authentication is not available on this device';
        });
      }
    } catch (e) {
      print('Error checking biometric availability: $e');
      setState(() {
        _errorMessage = 'Failed to check biometric availability';
      });
    }
  }

  /// Perform biometric authentication (Face ID or Fingerprint)
  Future<void> _authenticateWithBiometrics() async {
    if (!_canCheckBiometrics) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometric authentication not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      // Determine biometric type message based on platform
      String biometricTypeMessage = 'Authenticate with biometrics';
      if (Platform.isIOS) {
        biometricTypeMessage = 'Authenticate with Face ID';
      } else if (Platform.isAndroid) {
        biometricTypeMessage = 'Authenticate with Fingerprint';
      }

      // Perform biometric authentication
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: biometricTypeMessage,
        options: const AuthenticationOptions(
          stickyAuth: true, // Keep authentication dialog until success or explicit cancel
          biometricOnly: true, // Only allow biometric, no PIN/password fallback
        ),
      );

      if (!mounted) return;

      if (didAuthenticate) {
        // Biometric authentication successful
        print('✅ Biometric authentication successful');

        // Get device ID
        final String deviceId = await _kycService.getDeviceId();

        // Save biometric verification status and device ID to Firestore
        await _kycService.saveBiometricVerification(deviceId);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric verification successful!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to Upload Documents screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const UploadDocumentsScreen(),
          ),
        );
      } else {
        // Authentication failed
        setState(() {
          _isVerifying = false;
          _errorMessage = 'Biometric authentication failed. Please try again.';
        });
      }
    } catch (e) {
      print('❌ Biometric authentication error: $e');
      setState(() {
        _isVerifying = false;
        _errorMessage = 'Authentication error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine biometric icon and title based on platform
    IconData biometricIcon = Icons.fingerprint;
    String biometricTitle = 'Biometric Verification';
    String biometricDescription = 'Use your fingerprint to verify your identity';

    if (Platform.isIOS) {
      biometricIcon = Icons.face;
      biometricTitle = 'Face ID Verification';
      biometricDescription = 'Use Face ID to verify your identity';
    } else if (Platform.isAndroid) {
      biometricIcon = Icons.fingerprint;
      biometricTitle = 'Fingerprint Verification';
      biometricDescription = 'Use your fingerprint to verify your identity';
    }

    return Scaffold(
      backgroundColor: AppColors.foreground,
      appBar: AppBar(
        backgroundColor: AppColors.foreground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'KYC Verification',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // Biometric Icon
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  biometricIcon,
                  size: 100,
                  color: AppColors.accent,
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                biometricTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Description
              Text(
                biometricDescription,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Error Message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const Spacer(),

              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isVerifying || !_canCheckBiometrics
                      ? null
                      : _authenticateWithBiometrics,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isVerifying
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                      : const Text(
                          'Verify Now',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
