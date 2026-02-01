import 'package:flutter/material.dart';
import '../services/location_service.dart';
import '../services/trip_monitoring_service.dart';

class LocationTrackingBanner extends StatefulWidget {
  const LocationTrackingBanner({super.key});

  @override
  State<LocationTrackingBanner> createState() => _LocationTrackingBannerState();
}

class _LocationTrackingBannerState extends State<LocationTrackingBanner> {
  final LocationService _locationService = LocationService();
  final TripMonitoringService _tripMonitoring = TripMonitoringService();
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    _checkTrackingStatus();
    // Check status periodically
    Future.delayed(const Duration(seconds: 2), _checkTrackingStatus);
  }

  void _checkTrackingStatus() {
    if (mounted) {
      setState(() {
        _isTracking = _locationService.isTracking;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isTracking) {
      return const SizedBox.shrink();
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.01,
      ),
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[300]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            color: Colors.green[700],
            size: 24,
          ),
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location Sharing Active',
                  style: TextStyle(
                    fontSize: screenHeight * 0.018,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[900],
                  ),
                ),
                SizedBox(height: screenHeight * 0.003),
                Text(
                  'Your location is being shared with the car owner',
                  style: TextStyle(
                    fontSize: screenHeight * 0.014,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
          // Pulsing indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}