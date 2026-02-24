import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'location_service.dart';

class TripMonitoringService {
  static final TripMonitoringService _instance = TripMonitoringService._internal();
  factory TripMonitoringService() => _instance;
  TripMonitoringService._internal();

  StreamSubscription<QuerySnapshot>? _bookingsSubscription;
  final LocationService _locationService = LocationService();
  bool _isMonitoring = false;
  String? _activeBookingId;

  /// Start monitoring user's bookings for approved trips
  void startMonitoring() {
    if (_isMonitoring) {
      print('Trip monitoring already started for user: ${FirebaseAuth.instance.currentUser?.uid}');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user logged in');
      return;
    }

    print('Starting trip monitoring for user: ${user.uid}');
    //print("calling _checkactivetrips for user: ${user.uid}");

    // Listen to all bookings where user is the renter
    _bookingsSubscription = FirebaseFirestore.instance
        .collection('bookings')
        .where('renter_id', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      _checkForActiveTrips(snapshot.docs);
    });

    _isMonitoring = true;
  }

  /// Check if there are any active (approved) trips
  void _checkForActiveTrips(List<QueryDocumentSnapshot> bookings) {
    print('Checking for active trips among ${bookings.length} bookings');
    bool hasActiveTrip = false;
    String? activeBookingId;

    for (final doc in bookings) {
      final data = doc.data() as Map<String, dynamic>;
      final status = (data['status'] as String?)?.trim().toLowerCase();

      // Track location only when trip is explicitly started.
      if (status == 'started') {
        hasActiveTrip = true;
        activeBookingId = doc.id;
        break;
      }
    }
    print('Active trip status: $hasActiveTrip, Booking ID: $activeBookingId');

    // Start or stop location tracking based on active trip status
    if (hasActiveTrip) {
      print('Active trip found (booking ID: $activeBookingId), starting location tracking');
      if (!_locationService.isTracking) {
        print('Starting location tracking for active trip');
        _locationService.startLocationTracking();
        _activeBookingId = activeBookingId;
      }
    } else {
      if (_locationService.isTracking) {
        print('No active trip, stopping location tracking');
        _locationService.stopLocationTracking();
        _activeBookingId = null;
      }
    }
  }

  /// Stop monitoring trips
  void stopMonitoring() {
    if (_bookingsSubscription != null) {
      _bookingsSubscription!.cancel();
      _bookingsSubscription = null;
    }
    _locationService.stopLocationTracking();
    _isMonitoring = false;
    _activeBookingId = null;
    //print('Trip monitoring stopped');
  }

  /// Check if currently monitoring
  bool get isMonitoring => _isMonitoring;

  /// Get active booking ID
  String? get activeBookingId => _activeBookingId;

  /// Manually start location tracking (for testing or manual activation)
  Future<void> startLocationTracking() async {
    await _locationService.startLocationTracking();
  }

  /// Manually stop location tracking
  void stopLocationTracking() {
    _locationService.stopLocationTracking();
  }
}
