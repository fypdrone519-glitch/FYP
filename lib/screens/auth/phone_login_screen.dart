import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../main_navigation.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  final _auth = AuthService();

  String _verificationId = "";

  bool otpSent = false;
  bool loading = false;

  // ================= SEND OTP =================
  Future<void> sendOTP() async {
    setState(() => loading = true);

    await _auth.verifyPhone(
      phone: _phone.text,
      codeSent: (verificationId) {
        setState(() {
          _verificationId = verificationId;
          otpSent = true;
          loading = false;
        });
      },
      onError: (error) {
        setState(() => loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      },
    );
  }

  // ================= VERIFY OTP =================
  Future<void> verifyOTP() async {
    setState(() => loading = true);

    try {
      final user = await _auth.verifyOTP(_verificationId, _otp.text);

      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: otpSent ? _otp : _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: otpSent ? "OTP" : "Phone Number",
                hintText: otpSent ? "123456" : "+92XXXXXXXXXX",
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed:
                  loading
                      ? null
                      : otpSent
                      ? verifyOTP
                      : sendOTP,
              child: Text(otpSent ? "Verify OTP" : "Send OTP"),
            ),
          ],
        ),
      ),
    );
  }
}
