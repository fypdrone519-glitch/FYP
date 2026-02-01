import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isTracking = false;

  /// Check if location services are enabled and permissions are granted
  Future<bool> checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Check location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Start tracking user's location and update to Firestore
  Future<void> startLocationTracking() async {
    if (_isTracking) {
      print('Location tracking already started');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user logged in');
      return;
    }

    final hasPermission = await checkLocationPermission();
    if (!hasPermission) {
      print('Location permission not granted');
      return;
    }

    print('Starting location tracking for user: ${user.uid}');

    // Define location settings
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    // Start listening to position stream
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _updateLocationToFirestore(position, user.uid);
      },
      onError: (error) {
        print('Location tracking error: $error');
      },
    );

    _isTracking = true;
    print('Location tracking started successfully');
  }

  /// Update location to Firestore
  Future<void> _updateLocationToFirestore(Position position, String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'current_location': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': FieldValue.serverTimestamp(),
          'accuracy': position.accuracy,
          'speed': position.speed,
          'heading': position.heading,
        },
      });
      print('Location updated: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('Error updating location to Firestore: $e');
    }
  }

  /// Stop location tracking
  void stopLocationTracking() {
    if (_positionStreamSubscription != null) {
      _positionStreamSubscription!.cancel();
      _positionStreamSubscription = null;
      _isTracking = false;
      print('Location tracking stopped');
    }
  }

  /// Check if currently tracking
  bool get isTracking => _isTracking;

  /// Get current location once (without continuous tracking)
  Future<Position?> getCurrentLocation() async {
    final hasPermission = await checkLocationPermission();
    if (!hasPermission) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }
}