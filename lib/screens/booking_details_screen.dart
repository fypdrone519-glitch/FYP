import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_colors.dart';

class BookingDetailsScreen extends StatefulWidget {
  final String bookingId;
  final bool isHostView;

  const BookingDetailsScreen({
    super.key,
    required this.bookingId,
    this.isHostView = false,
  });

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  Map<String, dynamic>? _bookingData;
  Map<String, dynamic>? _vehicleData;
  Map<String, dynamic>? _renterData;
  Map<String, dynamic>? _ownerData;
  bool _isLoading = true;
  GoogleMapController? _mapController;
  LatLng? _renterLocation;

  @override
  void initState() {
    super.initState();
    _loadBookingDetails();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadBookingDetails() async {
    try {
      // Load booking data
      final bookingDoc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .get();

      if (!bookingDoc.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking not found')),
        );
        Navigator.pop(context);
        return;
      }

      final bookingData = bookingDoc.data()!;
      final vehicleId = bookingData['vehicle_id'] as String?;
      final renterId = bookingData['renter_id'] as String?;
      final ownerId = bookingData['owner_id'] as String?;

      // Load vehicle data
      Map<String, dynamic>? vehicleData;
      if (vehicleId != null) {
        final vehicleDoc = await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(vehicleId)
            .get();
        vehicleData = vehicleDoc.data();
      }

      // Load renter data
      Map<String, dynamic>? renterData;
      if (renterId != null) {
        final renterDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(renterId)
            .get();
        renterData = renterDoc.data();
      }

      // Load owner data
      Map<String, dynamic>? ownerData;
      if (ownerId != null) {
        final ownerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(ownerId)
            .get();
        ownerData = ownerDoc.data();
      }

      if (!mounted) return;
      setState(() {
        _bookingData = bookingData;
        _vehicleData = vehicleData;
        _renterData = renterData;
        _ownerData = ownerData;
        _isLoading = false;
      });
      
      // Start listening to location after data is loaded
      if (widget.isHostView) {
        print('DEBUG: Calling _listenToRenterLocation');
        _listenToRenterLocation();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading booking: $e')),
      );
    }
  }

  void _listenToRenterLocation() {
    final renterId = _bookingData?['renter_id'] as String?;
    if (renterId == null) {
      print('DEBUG: No renter ID found in booking data');
      return;
    }

    print('DEBUG: Starting to listen to renter location for user: $renterId');

    // Listen to real-time location updates
    FirebaseFirestore.instance
        .collection('users')
        .doc(renterId)
        .snapshots()
        .listen((snapshot) {
      print('DEBUG: Received user snapshot update');
      
      if (!snapshot.exists) {
        print('DEBUG: User document does not exist');
        return;
      }
      
      if (!mounted) {
        print('DEBUG: Widget not mounted');
        return;
      }
      
      final data = snapshot.data();
      if (data == null) {
        print('DEBUG: User data is null');
        return;
      }

      print('DEBUG: User data: $data');

      final location = data['current_location'] as Map<String, dynamic>?;
      if (location == null) {
        print('DEBUG: No current_location field in user data');
        return;
      }

      print('DEBUG: Location data: $location');

      final lat = location['latitude'];
      final lng = location['longitude'];
      
      print('DEBUG: Latitude: $lat, Longitude: $lng');
      
      if (lat != null && lng != null) {
        final latDouble = lat is int ? lat.toDouble() : lat as double;
        final lngDouble = lng is int ? lng.toDouble() : lng as double;
        
        print('DEBUG: Setting location to: $latDouble, $lngDouble');
        
        setState(() {
          _renterLocation = LatLng(latDouble, lngDouble);
        });
        
        // Animate camera to new location
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(_renterLocation!),
        );
        
        print('DEBUG: Location updated successfully');
      } else {
        print('DEBUG: Latitude or longitude is null');
      }
    }, onError: (error) {
      print('DEBUG: Error listening to location: $error');
    });
  }

  String _formatDateTime(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return '${_monthName(date.month)} ${date.day}, ${date.year} at ${_formatTime(date)}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Booking Details',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          // Debug button to test location fetching
          if (widget.isHostView)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.blue),
              onPressed: () async {
                print('=== MANUAL LOCATION FETCH TEST ===');
                final renterId = _bookingData?['renter_id'] as String?;
                print('Renter ID: $renterId');
                
                if (renterId != null) {
                  try {
                    final doc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(renterId)
                        .get();
                    
                    print('Document exists: ${doc.exists}');
                    print('Full document data: ${doc.data()}');
                    
                    final location = doc.data()?['current_location'];
                    print('Location field: $location');
                    
                    if (location != null) {
                      final lat = location['latitude'];
                      final lng = location['longitude'];
                      print('✅ Found location: $lat, $lng');
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Location: $lat, $lng'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } else {
                      print('❌ No location field in document');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No location found'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    print('❌ Error fetching location: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle Information
                  _buildSectionTitle('Vehicle Information', screenHeight),
                  SizedBox(height: screenHeight * 0.015),
                  _buildVehicleCard(screenHeight, screenWidth),
                  
                  SizedBox(height: screenHeight * 0.03),

                  // Trip Details
                  _buildSectionTitle('Trip Details', screenHeight),
                  SizedBox(height: screenHeight * 0.015),
                  _buildTripDetailsCard(screenHeight, screenWidth),

                  SizedBox(height: screenHeight * 0.03),

                  // Renter/Owner Information
                  _buildSectionTitle(
                    widget.isHostView ? 'Renter Information' : 'Owner Information',
                    screenHeight,
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  _buildUserInfoCard(screenHeight, screenWidth),

                  SizedBox(height: screenHeight * 0.03),

                  // Payment Information
                  _buildSectionTitle('Payment Information', screenHeight),
                  SizedBox(height: screenHeight * 0.015),
                  _buildPaymentCard(screenHeight, screenWidth),

                  // Live Location (only for host view)
                  if (widget.isHostView) ...[
                    SizedBox(height: screenHeight * 0.03),
                    _buildSectionTitle('Renter Live Location', screenHeight),
                    SizedBox(height: screenHeight * 0.015),
                    _buildLiveLocationMap(screenHeight, screenWidth),
                  ],

                  SizedBox(height: screenHeight * 0.02),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, double screenHeight) {
    return Text(
      title,
      style: TextStyle(
        fontSize: screenHeight * 0.022,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  Widget _buildVehicleCard(double screenHeight, double screenWidth) {
    final make = (_vehicleData?['make'] as String?) ?? '';
    final carName = (_vehicleData?['car_name'] as String?) ?? '';
    final modelData = _vehicleData?['model'];
    final model = modelData != null ? modelData.toString() : '';
    final yearData = _vehicleData?['year'];
    final year = yearData != null ? yearData.toString() : '';
    final images = (_vehicleData?['images'] as List?)?.cast<String>() ?? [];
    final imageUrl = images.isNotEmpty ? images.first : '';
    final location = (_vehicleData?['street_address'] as String?) ?? 'N/A';

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          // Vehicle Image
          if (imageUrl.isNotEmpty)
            Container(
              width: screenWidth * 0.25,
              height: screenHeight * 0.1,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.directions_car, size: 40);
                  },
                ),
              ),
            ),
          
          SizedBox(width: screenWidth * 0.04),

          // Vehicle Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$make $carName'.trim(),
                  style: TextStyle(
                    fontSize: screenHeight * 0.02,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: screenHeight * 0.005),
                if (model.isNotEmpty || year.isNotEmpty)
                  Text(
                    '$model $year'.trim(),
                    style: TextStyle(
                      fontSize: screenHeight * 0.016,
                      color: Colors.grey[600],
                    ),
                  ),
                SizedBox(height: screenHeight * 0.005),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                    SizedBox(width: screenWidth * 0.01),
                    Expanded(
                      child: Text(
                        location,
                        style: TextStyle(
                          fontSize: screenHeight * 0.015,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripDetailsCard(double screenHeight, double screenWidth) {
    final startTime = _bookingData?['start_time'] as Timestamp?;
    final endTime = _bookingData?['end_time'] as Timestamp?;
    final status = (_bookingData?['status'] as String?) ?? 'N/A';
    final bookingId = widget.bookingId;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          _buildDetailRow('Booking ID', bookingId, screenHeight, screenWidth),
          Divider(height: screenHeight * 0.03),
          _buildDetailRow('Start Date & Time', _formatDateTime(startTime), screenHeight, screenWidth),
          Divider(height: screenHeight * 0.03),
          _buildDetailRow('End Date & Time', _formatDateTime(endTime), screenHeight, screenWidth),
          Divider(height: screenHeight * 0.03),
          _buildDetailRow('Status', status, screenHeight, screenWidth, valueColor: AppColors.accent),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard(double screenHeight, double screenWidth) {
    final userData = widget.isHostView ? _renterData : _ownerData;
    final name = (userData?['name'] as String?) ?? 'N/A';
    final email = (userData?['email'] as String?) ?? 'N/A';
    final phoneData = userData?['phone'] ?? userData?['phone_number'];
    final phone = phoneData != null ? phoneData.toString() : 'N/A';
    final profileImage = (userData?['profile_image'] as String?) ?? '';

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // Profile Image
          if (profileImage.isNotEmpty)
            CircleAvatar(
              radius: screenWidth * 0.12,
              backgroundImage: NetworkImage(profileImage),
              backgroundColor: Colors.grey[200],
              onBackgroundImageError: (_, __) {},
            )
          else
            CircleAvatar(
              radius: screenWidth * 0.12,
              backgroundColor: Colors.grey[200],
              child: Icon(
                Icons.person,
                size: screenWidth * 0.12,
                color: Colors.grey[600],
              ),
            ),
          
          SizedBox(height: screenHeight * 0.02),

          _buildDetailRow('Name', name, screenHeight, screenWidth),
          Divider(height: screenHeight * 0.03),
          _buildDetailRow('Email', email, screenHeight, screenWidth),
          Divider(height: screenHeight * 0.03),
          _buildDetailRow('Phone', phone, screenHeight, screenWidth),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(double screenHeight, double screenWidth) {
    final amountPaid = (_bookingData?['amount_paid'] as num?)?.toDouble() ?? 0.0;
    final paymentMethod = (_bookingData?['payment_method'] as String?) ?? 'N/A';
    final paymentStatus = (_bookingData?['payment_status'] as String?) ?? 'N/A';

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            'Total Amount',
            'PKR ${amountPaid.toStringAsFixed(0)}',
            screenHeight,
            screenWidth,
            valueColor: AppColors.accent,
            valueBold: true,
          ),
          Divider(height: screenHeight * 0.03),
          _buildDetailRow('Payment Method', paymentMethod, screenHeight, screenWidth),
          Divider(height: screenHeight * 0.03),
          _buildDetailRow('Payment Status', paymentStatus, screenHeight, screenWidth),
        ],
      ),
    );
  }

  Widget _buildLiveLocationMap(double screenHeight, double screenWidth) {
    return Container(
      height: screenHeight * 0.35,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Map or placeholder
            if (_renterLocation != null)
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _renterLocation!,
                  zoom: 14.0,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('renter_location'),
                    position: _renterLocation!,
                    infoWindow: InfoWindow(
                      title: _renterData?['name'] ?? 'Renter',
                      snippet: 'Current Location',
                    ),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed,
                    ),
                  ),
                },
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                myLocationButtonEnabled: true,
                zoomControlsEnabled: true,
              )
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_off,
                      size: 48,
                      color: Colors.grey[600],
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Text(
                      'Location not available',
                      style: TextStyle(
                        fontSize: screenHeight * 0.018,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Text(
                      'The renter\'s location will appear here when shared',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: screenHeight * 0.014,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            
            // Location info overlay (when location is available)
            if (_renterLocation != null)
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Live Location: ${_renterLocation!.latitude.toStringAsFixed(6)}, ${_renterLocation!.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    double screenHeight,
    double screenWidth, {
    Color? valueColor,
    bool valueBold = false,
  }) {
    if(value == 'approved')
    {
      value = "Waiting for host to start trip";
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: screenHeight * 0.016,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontSize: screenHeight * 0.016,
              color: valueColor ?? Colors.black,
              fontWeight: valueBold ? FontWeight.bold : FontWeight.w500,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}