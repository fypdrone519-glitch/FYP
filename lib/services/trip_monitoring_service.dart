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
      //print('Trip monitoring already started');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      //print('No user logged in');
      return;
    }

    //print('Starting trip monitoring for user: ${user.uid}');

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
    final now = DateTime.now();
    bool hasActiveTrip = false;
    String? activeBookingId;

    for (final doc in bookings) {
      final data = doc.data() as Map<String, dynamic>;
      final status = (data['status'] as String?)?.trim().toLowerCase();
      final startTime = (data['start_time'] as Timestamp?)?.toDate();
      final endTime = (data['end_time'] as Timestamp?)?.toDate();

      // Check if trip is approved and currently active
      if (status == 'approved' && startTime != null && endTime != null) {
        if (now.isAfter(startTime) && now.isBefore(endTime)) {
          hasActiveTrip = true;
          activeBookingId = doc.id;
          //print('Active trip found: ${doc.id}');
          break;
        }
      }
    }

    // Start or stop location tracking based on active trip status
    if (hasActiveTrip) {
      if (!_locationService.isTracking) {
        //print('Starting location tracking for active trip');
        _locationService.startLocationTracking();
        _activeBookingId = activeBookingId;
      }
    } else {
      if (_locationService.isTracking) {
        //print('No active trip, stopping location tracking');
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