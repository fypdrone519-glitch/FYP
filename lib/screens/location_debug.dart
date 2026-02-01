import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/location_service.dart';
import '../services/trip_monitoring_service.dart';

class LocationDebugScreen extends StatefulWidget {
  const LocationDebugScreen({super.key});

  @override
  State<LocationDebugScreen> createState() => _LocationDebugScreenState();
}

class _LocationDebugScreenState extends State<LocationDebugScreen> {
  final LocationService _locationService = LocationService();
  final TripMonitoringService _tripMonitoring = TripMonitoringService();
  
  String _status = 'Idle';
  Map<String, dynamic>? _currentLocation;
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentStatus();
    _listenToOwnLocation();
  }

  void _checkCurrentStatus() {
    setState(() {
      _isTracking = _locationService.isTracking;
      _status = _isTracking ? 'Tracking Active' : 'Not Tracking';
    });
  }

  void _listenToOwnLocation() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      
      final data = snapshot.data();
      if (data != null) {
        setState(() {
          _currentLocation = data['current_location'] as Map<String, dynamic>?;
        });
      }
    });
  }

  Future<void> _startTracking() async {
    setState(() => _status = 'Starting tracking...');
    await _locationService.startLocationTracking();
    await Future.delayed(const Duration(seconds: 1));
    _checkCurrentStatus();
  }

  void _stopTracking() {
    setState(() => _status = 'Stopping tracking...');
    _locationService.stopLocationTracking();
    Future.delayed(const Duration(seconds: 1), _checkCurrentStatus);
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _status = 'Getting current location...');
    final position = await _locationService.getCurrentLocation();
    if (position != null) {
      setState(() {
        _status = 'Got location: ${position.latitude}, ${position.longitude}';
      });
    } else {
      setState(() => _status = 'Failed to get location');
    }
  }

  Future<void> _checkPermissions() async {
    setState(() => _status = 'Checking permissions...');
    final hasPermission = await _locationService.checkLocationPermission();
    setState(() {
      _status = hasPermission 
          ? 'Permissions granted ✓' 
          : 'Permissions denied ✗';
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Debug'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              color: _isTracking ? Colors.green[50] : Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      _isTracking ? Icons.location_on : Icons.location_off,
                      size: 48,
                      color: _isTracking ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // User Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'User Info',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('User ID: ${user?.uid ?? "Not logged in"}'),
                    Text('Email: ${user?.email ?? "N/A"}'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Current Location from Firestore
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Location in Firestore',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_currentLocation != null) ...[
                      Text('Latitude: ${_currentLocation!['latitude']}'),
                      Text('Longitude: ${_currentLocation!['longitude']}'),
                      Text('Accuracy: ${_currentLocation!['accuracy']}'),
                      Text('Speed: ${_currentLocation!['speed']}'),
                      if (_currentLocation!['timestamp'] != null)
                        Text('Updated: ${_currentLocation!['timestamp'].toString()}'),
                    ] else
                      const Text('No location data yet'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            ElevatedButton.icon(
              onPressed: _checkPermissions,
              icon: const Icon(Icons.security),
              label: const Text('Check Permissions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 8),
            
            ElevatedButton.icon(
              onPressed: _getCurrentLocation,
              icon: const Icon(Icons.my_location),
              label: const Text('Get Current Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 8),
            
            ElevatedButton.icon(
              onPressed: _isTracking ? null : _startTracking,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Tracking'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 8),
            
            ElevatedButton.icon(
              onPressed: _isTracking ? _stopTracking : null,
              icon: const Icon(Icons.stop),
              label: const Text('Stop Tracking'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Instructions
            Card(
              color: Colors.blue[50],
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debug Instructions:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('1. Check permissions first'),
                    Text('2. Try getting current location'),
                    Text('3. Start tracking and move around'),
                    Text('4. Check if location updates in Firestore'),
                    Text('5. Open host view to see if location appears'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}