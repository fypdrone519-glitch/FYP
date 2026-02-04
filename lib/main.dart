import 'package:car_listing_app/screens/home_screen.dart';
import 'package:car_listing_app/screens/host/host_home_screen.dart';
import 'package:car_listing_app/screens/host_navigation.dart';
import 'package:car_listing_app/screens/main_navigation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth/welcome_screen.dart';
import 'theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/trip_monitoring_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize notification service
  await NotificationService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    TripMonitoringService().startMonitoring();
    
    // Set navigator key for notification navigation
    NotificationService.navigatorKey = _navigatorKey;
  }

   @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Stop monitoring when app is closed
    TripMonitoringService().stopMonitoring();
    super.dispose();
  }
    @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    if (state == AppLifecycleState.resumed) {
      // Restart monitoring when app comes to foreground
      TripMonitoringService().startMonitoring();
    }
  }
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CarShare - Car Listing App',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          surface: AppColors.cardSurface,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.interTextTheme(),
      ),
      //home: const HostNavigation(),
      home: const MainNavigation(),
      //home: const WelcomeScreen(),
    );
  }
}
