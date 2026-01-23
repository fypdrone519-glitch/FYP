import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';

class EditCarScreen extends StatefulWidget {
 
  final String vehicleId;
  final Map<String, dynamic> vehicleData;

  const EditCarScreen({
    super.key,
    required this.vehicleId,
    required this.vehicleData,
    
  });

  @override
  State<EditCarScreen> createState() => _EditCarScreenState();
}

class _EditCarScreenState extends State<EditCarScreen> {
  // Form controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _carRegistrationController = TextEditingController();
  final TextEditingController _carAbilityController = TextEditingController();
  final TextEditingController _rentPerDayController = TextEditingController();

  // State variables
  String? _transmissionType;
  Set<String> _drivingOptions = {};
  Set<String> _selectedFeatures = {};
  int _selectedTab = 0;
  String? _selectedBrand;
  String? _selectedColor;
  String? _selectedFuelType;
  bool _termsAccepted = true; // Pre-checked for edit
  int _characterCount = 0;
  final int _maxCharacters = 1000;
  
  // Location variables
  LatLng? carLocation;
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(33.6844, 73.0479);
  bool _isLoadingLocation = false;
  Set<Marker> _markers = {};
  bool _isInteractingWithMap = false;

  // Image selection variable
  List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  
  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Loading state
  bool _isSubmitting = false;

  // Car brands data
  final List<String> regularBrands = ['Changan', 'Honda', 'Toyota', 'Nissan', 'Mercedes'];
  final List<String> luxuryBrands = ['BMW', 'Ferrari', 'Bentley', 'Maybach', 'Lamborghini'];

  // Colors data
  final List<Map<String, dynamic>> colors = [
    {'name': 'White', 'color': Colors.white},
    {'name': 'Gray', 'color': Colors.grey},
    {'name': 'Blue', 'color': Colors.blue},
    {'name': 'Black', 'color': Colors.black},
  ];

  // Fuel types
  final List<String> fuelTypes = ['Electric', 'Petrol', 'Diesel', 'Hybrid'];

  @override
  void initState() {
    super.initState();
    _loadVehicleData();
    _carAbilityController.addListener(() {
      setState(() {
        _characterCount = _carAbilityController.text.length;
      });
    });
  }

  void _loadVehicleData() {
    // Load text fields
    _fullNameController.text = widget.vehicleData['car_name'] ?? '';
    _emailController.text = widget.vehicleData['owner_email'] ?? '';
    _contactController.text = widget.vehicleData['owner_contact'] ?? '';
    _carRegistrationController.text = widget.vehicleData['registration_number'] ?? '';
    _carAbilityController.text = widget.vehicleData['description'] ?? '';
    _rentPerDayController.text = widget.vehicleData['rent_per_day']?.toString() ?? '';

    // Load selections
    _selectedBrand = widget.vehicleData['make'];
    _selectedColor = widget.vehicleData['color'] ?? 'Blue';
    _selectedFuelType = widget.vehicleData['fuel_type'] ?? 'Diesel';
    _transmissionType = widget.vehicleData['transmissionType'];

    // Load features
    if (widget.vehicleData['features'] != null) {
      _selectedFeatures = Set<String>.from(widget.vehicleData['features']);
    }
    print('Loaded features: $_selectedFeatures');

    // Load driving options
    String drivingOptions = widget.vehicleData['driving_options'] ?? '';
    if (drivingOptions == 'Both') {
      _drivingOptions = {'Self Driving', 'With Driver'};
    } else if (drivingOptions == 'Self Driving') {
      _drivingOptions = {'Self Driving'};
    } else if (drivingOptions == 'With Driver') {
      _drivingOptions = {'With Driver'};
    }

    // Load location
    if (widget.vehicleData['location'] != null) {
      final location = widget.vehicleData['location'];
      carLocation = LatLng(
        location['latitude'] ?? 33.6844,
        location['longitude'] ?? 73.0479,
      );
      _currentPosition = carLocation!;
      
      _markers.add(
        Marker(
          markerId: const MarkerId('car_location'),
          position: carLocation!,
          infoWindow: const InfoWindow(title: 'Car Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _carRegistrationController.dispose();
    _carAbilityController.dispose();
    _rentPerDayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppColors.hostBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // App bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Car Details',
                  style: AppTextStyles.h2(context),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              physics: _isInteractingWithMap 
                  ? const NeverScrollableScrollPhysics() 
                  : const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('General information'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildTextField(_fullNameController, 'Car name'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildTextField(_emailController, 'Email Addresses'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildTextField(_contactController, 'Contact'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildTextField(_carRegistrationController, 'Car Registration Number'),
                  const SizedBox(height: AppSpacing.md),
                  _buildTextField(_rentPerDayController, 'Renting Price per day'),
                  const SizedBox(height: AppSpacing.md),

                  _buildSectionTitle('Car information'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildSegmentedControl(),
                  const SizedBox(height: AppSpacing.sm),
                  if (_selectedTab == 0) _buildCarBrandSelection(),
                  const SizedBox(height: AppSpacing.md),
                  
                  _buildSectionTitle("Location"),
                  const SizedBox(height: AppSpacing.sm),
                  _buildLocation(),
                  const SizedBox(height: AppSpacing.md),

                  _buildColorsSection(),
                  const SizedBox(height: AppSpacing.md),

                  _buildFuelTypeSection(),
                  const SizedBox(height: AppSpacing.sm),

                  _buildDrivingOptionsSection(),
                  const SizedBox(height: AppSpacing.md),

                  _buildTransmissionTypeSection(),
                  const SizedBox(height: AppSpacing.md),

                  _buildFeaturesSection(),
                  const SizedBox(height: AppSpacing.md),

                  // _buildCarAbilityTextArea(),
                  // const SizedBox(height: AppSpacing.md),

                  _buildSubmitButton(),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // All the widget building methods from AddCarScreen
  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTextStyles.h2(context));
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    TextInputType keyboardType = TextInputType.text;
    if (hint.toLowerCase().contains('renting price per day') || 
        hint.toLowerCase().contains('contact')) {
      keyboardType = TextInputType.number;
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.2)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.meta(context),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
        ),
        style: AppTextStyles.body(context),
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.hostBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTabButton(0, 'Car Brand')),
          Expanded(child: _buildTabButton(1, 'Car Model')),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.white : const Color(0xFF4A4A4A),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCarBrandSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Text('Regular Cars Brand', 
            style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600)),
        ),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: regularBrands.map((brand) => _buildBrandChip(brand, false)).toList(),
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Text('Luxury Cars Brand',
            style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600)),
        ),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: luxuryBrands.map((brand) => _buildBrandChip(brand, true)).toList(),
        ),
      ],
    );
  }

  Widget _buildBrandChip(String brand, bool isLuxury) {
    final isSelected = _selectedBrand == brand;
    return GestureDetector(
      onTap: () => setState(() => _selectedBrand = brand),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.accent : Colors.transparent,
          ),
        ),
        child: Text(
          brand,
          style: AppTextStyles.body(context).copyWith(
            color: isSelected ? AppColors.accent : AppColors.secondaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildLocation() {
    final size = MediaQuery.of(context).size;
    return Listener(
      onPointerDown: (_) => setState(() => _isInteractingWithMap = true),
      onPointerUp: (_) => setState(() => _isInteractingWithMap = false),
      child: Container(
        height: size.height * 0.3,
        width: size.width,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withOpacity(0.2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentPosition,
                  zoom: 14,
                ),
                onMapCreated: (controller) => _mapController = controller,
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                onTap: (position) {
                  setState(() {
                    carLocation = position;
                    _markers.clear();
                    _markers.add(
                      Marker(
                        markerId: const MarkerId('car_location'),
                        position: position,
                        infoWindow: const InfoWindow(title: 'Car Location'),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                      ),
                    );
                  });
                },
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(28),
                  child: InkWell(
                    onTap: _isLoadingLocation ? null : _getCurrentLocation,
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: _isLoadingLocation
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.accent,
                                ),
                              )
                            : const Icon(Icons.my_location, color: AppColors.accent, size: 24),
                      ),
                    ),
                  ),
                ),
              ),
              if (carLocation != null)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, color: AppColors.accent, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Lat: ${carLocation!.latitude.toStringAsFixed(4)}, '
                            'Lng: ${carLocation!.longitude.toStringAsFixed(4)}',
                            style: AppTextStyles.meta(context),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable location services')),
        );
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        carLocation = LatLng(position.latitude, position.longitude);
        _currentPosition = carLocation!;
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId('car_location'),
            position: carLocation!,
            infoWindow: const InfoWindow(title: 'Car Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
        _isLoadingLocation = false;
      });

      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(carLocation!, 15));
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  Widget _buildColorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Colors'),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: colors.map((colorData) {
            final isSelected = _selectedColor == colorData['name'];
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedColor = colorData['name']),
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: colorData['color'],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.accent : Colors.grey.shade300,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: AppColors.white, size: 24)
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(colorData['name'], style: AppTextStyles.meta(context)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFuelTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Fuel Type'),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: fuelTypes.map((fuelType) {
            final isSelected = _selectedFuelType == fuelType;
            return GestureDetector(
              onTap: () => setState(() => _selectedFuelType = fuelType),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent : AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border.withOpacity(0.2)),
                ),
                child: Text(
                  fuelType,
                  style: AppTextStyles.body(context).copyWith(
                    color: isSelected ? AppColors.white : AppColors.primaryText,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDrivingOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Driving Options'),
        const SizedBox(height: AppSpacing.md),
        _buildDrivingOptions(Icons.directions_car, "Self Driving"),
        const SizedBox(height: AppSpacing.sm),
        _buildDrivingOptions(Icons.person, "With Driver"),
      ],
    );
  }

  Widget _buildDrivingOptions(IconData icon, String title) {
    final isSelected = _drivingOptions.contains(title);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _drivingOptions.remove(title);
          } else {
            _drivingOptions.add(title);
          }
        });
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accent : const Color(0xFFE0E0E0),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.accent : AppColors.secondaryText,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              title,
              style: AppTextStyles.body(context).copyWith(
                color: isSelected ? AppColors.primaryText : AppColors.secondaryText,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransmissionTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Transmission Type'),
        const SizedBox(height: AppSpacing.md),
        _buildTransmission(Icons.directions_car, "Manual"),
        const SizedBox(height: AppSpacing.sm),
        _buildTransmission(Icons.person, "Automatic"),
      ],
    );
  }

  Widget _buildTransmission(IconData icon, String title) {
    final isSelected = _transmissionType == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _transmissionType = isSelected ? null : title;
        });
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accent : const Color(0xFFE0E0E0),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.accent : AppColors.secondaryText,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              title,
              style: AppTextStyles.body(context).copyWith(
                color: isSelected ? AppColors.primaryText : AppColors.secondaryText,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Features'),
        const SizedBox(height: AppSpacing.md),
        _buildFeatures(Icons.ac_unit, "Air Conditioning"),
        const SizedBox(height: AppSpacing.sm),
        _buildFeatures(Icons.map, "GPS Navigation"),
        const SizedBox(height: AppSpacing.sm),
        _buildFeatures(Icons.bluetooth, "Bluetooth"),
        const SizedBox(height: AppSpacing.sm),
        _buildFeatures(Icons.wifi, "Wi-Fi"),
        const SizedBox(height: AppSpacing.sm),
        _buildFeatures(Icons.speed, "Cruise Control"),
        const SizedBox(height: AppSpacing.sm),
        _buildFeatures(Icons.child_friendly, "Child Seat"),
      ],
    );
  }

  Widget _buildFeatures(IconData icon, String title) {
    final isSelected = _selectedFeatures.contains(title);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedFeatures.remove(title);
          } else {
            _selectedFeatures.add(title);
          }
        });
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accent : const Color(0xFFE0E0E0),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.accent : AppColors.secondaryText,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              title,
              style: AppTextStyles.body(context).copyWith(
                color: isSelected ? AppColors.primaryText : AppColors.secondaryText,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarAbilityTextArea() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.2)),
      ),
      child: TextField(
        controller: _carAbilityController,
        maxLines: 5,
        maxLength: _maxCharacters,
        decoration: InputDecoration(
          hintText: 'Enter your car ability, durability, etc message here.........',
          hintStyle: AppTextStyles.meta(context),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(AppSpacing.sm),
          counterText: '$_characterCount/$_maxCharacters',
          counterStyle: AppTextStyles.meta(context),
        ),
        style: AppTextStyles.body(context),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _handleUpdate,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          disabledBackgroundColor: AppColors.accent.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text('Update Car', style: AppTextStyles.button(context)),
      ),
    );
  }

  Future<void> _handleUpdate() async {
    // Validate required fields
    if (_fullNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _contactController.text.isEmpty ||
        _carRegistrationController.text.isEmpty ||
        _selectedBrand == null ||
        _transmissionType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (carLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location for your car'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_drivingOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one driving option'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_rentPerDayController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the rent per day'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Determine driving options
      String drivingOptions;
      if (_drivingOptions.contains('Self Driving') && _drivingOptions.contains('With Driver')) {
        drivingOptions = 'Both';
      } else if (_drivingOptions.contains('Self Driving')) {
        drivingOptions = 'Self Driving';
      } else if (_drivingOptions.contains('With Driver')) {
        drivingOptions = 'With Driver';
      } else {
        drivingOptions = '';
      }

      double rentPerDay = double.tryParse(_rentPerDayController.text.trim()) ?? 0.0;

      // Update vehicle data
      final updateData = {
        'make': _selectedBrand ?? '',
        'features': _selectedFeatures.toList(),
        'registration_number': _carRegistrationController.text.trim(),
        'driving_options': drivingOptions,
        'rent_per_day': rentPerDay,
        'location': {
          'latitude': carLocation!.latitude,
          'longitude': carLocation!.longitude,
        },
        'transmissionType': _transmissionType ?? 'Not specified',
        'color': _selectedColor,
        'fuel_type': _selectedFuelType,
        ///'description': _carAbilityController.text.trim(),
        'car_name': _fullNameController.text.trim(),
        'owner_email': _emailController.text.trim(),
        'owner_contact': _contactController.text.trim(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('vehicles').doc(widget.vehicleId).update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Car updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating car: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
  
}