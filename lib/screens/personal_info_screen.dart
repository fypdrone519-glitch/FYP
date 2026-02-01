import 'package:car_listing_app/screens/otp_verification_screen.dart';
import 'package:car_listing_app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/kyc_service.dart';
import '../widgets/kyc_stepper.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final service = KycService();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final cnicController = TextEditingController();
  String? formatted_phone;
  bool _isSending = false;

  Future<void> saveAndNext() async {
    if (nameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        emailController.text.isEmpty ||
        addressController.text.isEmpty ||
        cnicController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }
    formatted_phone = '+92${phoneController.text.substring(1)}';

    setState(() => _isSending = true);
    try {
      await service.saveData({
        "full_name": nameController.text,
        "phone": phoneController.text,
        "cnic": cnicController.text,
        "email": emailController.text,
        "address": addressController.text,
      });

      // Send verification email (user clicks link in inbox, then verifies on next screen)
      await service.sendEmailVerification(emailController.text);

      // Send phone OTP and get verificationId for the next screen
      final String? verificationId = await service.sendPhoneOtp(
        formatted_phone ?? '',
      );

      if (!mounted) return;
      if (verificationId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Could not send SMS. Use 'Resend' on the next screen or check the phone number.",
            ),
          ),
        );
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => OtpVerificationScreen(
                phoneNumber: formatted_phone ?? '',
                email: emailController.text,
                verificationId: verificationId,
              ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.foreground,
      appBar: AppBar(title: const Text("KYC Verification")),
      body: SingleChildScrollView(
        // Add this
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const KycStepper(currentStep: 1, totalSteps: 3),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Personal Information",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Please provide your personal details",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              CustomTextField(
                label: 'Full name',
                controller: nameController,
                validator: Validators.validateFullName,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                ],
              ),

              const SizedBox(height: 20),

              CustomTextField(
                label: 'Phone Number',
                controller: phoneController,
                keyboardType: TextInputType.phone,
                validator: Validators.validatePhoneNumber,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
              ),

              const SizedBox(height: 20),

              CustomTextField(
                label: 'CNIC Number',
                controller: cnicController,
                keyboardType: TextInputType.number,
                validator: Validators.validateCNIC,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CnicInputFormatter(),
                ],
              ),

              const SizedBox(height: 20),

              CustomTextField(
                label: 'Email Address',
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.validateEmail,
              ),

              const SizedBox(height: 20),

              CustomTextField(
                label: 'Address',
                controller: addressController,
                validator: Validators.validateAddress,
              ),

              // Replace Spacer with SizedBox
              SizedBox(
                height: MediaQuery.of(context).viewInsets.bottom > 0 ? 20 : 40,
              ),

              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                    ),
                    onPressed: _isSending ? null : saveAndNext,
                    child:
                        _isSending
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: AppColors.lightText,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text(
                              "Continue",
                              style: TextStyle(
                                color: AppColors.lightText,
                                fontSize: 16,
                              ),
                            ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextField({
    Key? key,
    required this.label,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
    this.validator,
    this.inputFormatters,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          onChanged: onChanged,
          validator: validator,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFFD1D5DB),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// CNIC Input Formatter
class CnicInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('-', '');

    if (text.length > 13) {
      return oldValue;
    }

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 4 || i == 11) {
        buffer.write('-');
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// Validators Class
class Validators {
  // Full Name Validator - No numbers or special characters
  static String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your full name';
    }

    // Only letters and spaces allowed
    final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
    if (!nameRegex.hasMatch(value)) {
      return 'Name can only contain letters and spaces';
    }

    if (value.trim().length < 3) {
      return 'Name must be at least 3 characters';
    }

    return null;
  }

  // Phone Number Validator - Format: 03359459794
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }

    // Must start with 03 and be 11 digits
    final phoneRegex = RegExp(r'^03[0-9]{9}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Phone number must be in format: 03XXXXXXXXX';
    }

    return null;
  }

  // CNIC Validator - Format: 37405-7464621-9
  static String? validateCNIC(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your CNIC';
    }

    // Format: XXXXX-XXXXXXX-X
    final cnicRegex = RegExp(r'^[0-9]{5}-[0-9]{7}-[0-9]$');
    if (!cnicRegex.hasMatch(value)) {
      return 'CNIC must be in format: XXXXX-XXXXXXX-X';
    }

    return null;
  }

  // Email Validator
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email address';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // Address Validator
  static String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your address';
    }

    if (value.trim().length < 10) {
      return 'Please enter a complete address';
    }

    return null;
  }
}
