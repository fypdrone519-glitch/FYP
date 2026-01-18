import 'package:car_listing_app/screens/auth/welcome_screen.dart';
import 'package:car_listing_app/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/svg.dart';
import '../../theme/app_colors.dart';
import '../main_navigation.dart';
import 'signup_screen.dart';
import 'phone_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.cardSurface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight * 0.02),

              IconButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  );
                },
                icon: const Icon(Icons.arrow_back),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),

              SizedBox(height: screenHeight * 0.04),

              Text(
                'Let\'s Sign you in.',
                style: TextStyle(
                  fontSize: screenHeight * 0.036,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              SizedBox(height: screenHeight * 0.015),

              Text(
                'Welcome back',
                style: TextStyle(
                  fontSize: screenHeight * 0.022,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                'You\'ve been missed!',
                style: TextStyle(
                  fontSize: screenHeight * 0.022,
                  color: Colors.grey[600],
                ),
              ),

              SizedBox(height: screenHeight * 0.05),

              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'Email, phone or username',
                  hintStyle: AppTextStyles.meta(context),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.02),

              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: AppTextStyles.meta(context),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
              ),

              const Spacer(),
              // LOGIN BUTTON
              SizedBox(
                width: double.infinity,
                height: screenHeight * 0.07,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      final result = await FirebaseAuth.instance
                          .signInWithEmailAndPassword(
                            email: _emailController.text.trim(),
                            password: _passwordController.text.trim(),
                          );

                      if (result.user != null) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MainNavigation(),
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.lightText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                  ),
                  child: const Text("Login", style: TextStyle(fontSize: 16)),
                ),
              ),

              SizedBox(height: screenHeight * 0.02),
              // GOOGLE LOGIN BUTTON 
               // login in with phone button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.accent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PhoneLoginScreen(),
                      ),
                    );
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Icon(
                          Icons.phone,
                          size: screenHeight * 0.025,
                          color: AppColors.accent,
                        ),
                      ),
                      Center(
                        child: Text("Continue with Phone", style: TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.025),
              // login in with Google button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.accent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                  onPressed: () {
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (_) => const PhoneLoginScreen(),
                    //   ),
                    // );
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SvgPicture.asset(
                        'lib/assets/google.svg',
                        height: 30,
                        width: 30,
                      ),
                      ),
                      Center(
                        child: Text("Continue with Google", style: TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.025),

              // REGISTER LINK — restored
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account? ',
                      style: TextStyle(
                        fontSize: screenHeight * 0.018,
                        color: Colors.grey[600],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SignUpScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Register',
                        style: TextStyle(
                          fontSize: screenHeight * 0.018,
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: screenHeight * 0.03),
            ],
          ),
        ),
      ),
    );
  }
}
