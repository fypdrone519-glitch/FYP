import 'dart:io';
import 'package:car_listing_app/screens/host_navigation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';
import 'package:geocoding/geocoding.dart';

class AddCarScreen extends StatefulWidget {
  const AddCarScreen({super.key});

  @override
  State<AddCarScreen> createState() => _AddCarScreenState();
}

class _AddCarScreenState extends State<AddCarScreen> {
  // Form controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _drivingLicenseController =
      TextEditingController();
  final TextEditingController _carRegistrationController =
      TextEditingController();
  final TextEditingController _carAbilityController = TextEditingController();
  final TextEditingController _rentPerDayController = TextEditingController();
  final TextEditingController _rentPerHourController = TextEditingController();

  // State variables
  String _selectedVehicleType = '';
  // List of vehicle types for the grid
  final List<String> _vehicleTypes = [
    'SUV',
    'Sedan',
    'Hatchback',
    'Crossover',
    'Coupe',
    'Convertible',
    'Pickup Truck',
    'Minivan/MPV',
  ];
  String? _transmissionType;
  Set<String> _drivingOptions = {};
  Set<String> _selectedFeatures = {}; // to store selected features
  //int _selectedTab = 0; // 0 = Car Brand, 1 = Car Model
  String? _selectedBrand;
  String? _selectedColor;
  String? _selectedFuelType;
  bool _termsAccepted = false;
  int _characterCount = 0;
  //final int _maxCharacters = 1000;
  //varibale to store the location of the car
  LatLng? carLocation;
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(
    33.6844,
    73.0479,
  ); // Default to Islamabad
  bool _isLoadingLocation = false;
  Set<Marker> _markers = {};
  bool _isInteractingWithMap =
      false; //to aviod scrolling when interacting with the map
  // Street Address variable
  String? _streetAddress;

  //image selection variable
  List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Loading state
  bool _isSubmitting = false;

  // Car brands data
  final List<String> regularBrands = [
    'Changan',
    'Honda',
    'Toyota',
    'Nissan',
    'Mercedes',
  ];
  final List<String> luxuryBrands = [
    'BMW',
    'Ferrari',
    'Bentley',
    'Maybach',
    'Lamborghini',
  ];

  // Colors data
  final List<Map<String, dynamic>> colors = [
    {'name': 'White', 'color': Colors.white},
    {'name': 'Gray', 'color': Colors.grey},
    {'name': 'Blue', 'color': Colors.blue},
    {'name': 'Black', 'color': Colors.black},
  ];
  // Method to get address from latitude and longitude
  Future<String> getAddressFromLatLng(double lat, double lng) async {
    print("Getting address for Lat: $lat, Lng: $lng");
    List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

    Placemark place = placemarks[0];
    print(
      "Obtained address: ${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}",
    );

    return "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
  }

  // Method to get current location
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable location services')),
        );
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied'),
          ),
        );
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _streetAddress = await getAddressFromLatLng(
        position.latitude,
        position.longitude,
      );

      setState(() {
        carLocation = LatLng(position.latitude, position.longitude);
        _currentPosition = carLocation!;

        // Add marker at current location
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId('car_location'),
            position: carLocation!,
            infoWindow: const InfoWindow(title: 'Car Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        );

        _isLoadingLocation = false;
      });

      // Animate camera to current location
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(carLocation!, 15),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location saved successfully')),
      );
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
    }
  }

  // Method to pick images from gallery
  Future<void> _pickImagesFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(
            images.map((image) => File(image.path)).toList(),
          );
        });
      }
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking images: $e')));
    }
  }

  // Method to pick image from camera (for later)
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);

      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error taking photo: $e')));
    }
  }

  // Fuel types
  final List<String> fuelTypes = ['Electric', 'Petrol', 'Diesel', 'Hybrid'];

  @override
  void initState() {
    super.initState();
    _carAbilityController.addListener(() {
      setState(() {
        _characterCount = _carAbilityController.text.length;
      });
    });
    // Set default selections
    _selectedColor = 'Blue';
    _selectedFuelType = 'Diesel';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _drivingLicenseController.dispose();
    _carRegistrationController.dispose();
    _carAbilityController.dispose();
    _rentPerDayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.hostBackground, // Light gray background
      appBar: AppBar(
        backgroundColor: AppColors.hostBackground,
        elevation: 0,
        title: Text('Add Car', style: AppTextStyles.h2(context)),
      ),
      body: SingleChildScrollView(
        physics:
            _isInteractingWithMap
                ? const NeverScrollableScrollPhysics()
                : const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Car owner information section
            _buildSectionTitle('General information'),
            const SizedBox(height: AppSpacing.sm),
            _buildTextField(_fullNameController, 'Car name'),
            const SizedBox(height: AppSpacing.sm),
            _buildTextField(_emailController, 'Email Addresses'),
            const SizedBox(height: AppSpacing.sm),
            _buildTextField(_contactController, 'Contact'),
            const SizedBox(height: AppSpacing.sm),
            // Car Registration Number
            _buildTextField(
              _carRegistrationController,
              'Car Registration Number',
            ),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(_rentPerDayController, 'Renting Price per day'),
            const SizedBox(height: AppSpacing.md),

            _buildTextField(_rentPerHourController, 'Renting Price per hour'),
            const SizedBox(height: AppSpacing.md),

            // Car information section
            _buildSectionTitle('Car information'),
            const SizedBox(height: AppSpacing.sm),

            // Car Brand / Car Model tabs
            // _buildSegmentedControl(),
            // const SizedBox(height: AppSpacing.sm),
            _buildCarType(),
            const SizedBox(height: AppSpacing.md),
            _buildCarBrandSelection(),
            const SizedBox(height: AppSpacing.md),
            _buildSectionTitle("Location"),
            const SizedBox(height: AppSpacing.sm),
            _buildLocation(),
            const SizedBox(height: AppSpacing.md),

            // Image upload area
            _buildImageUploadSection(),
            const SizedBox(height: AppSpacing.sm),

            // Colors section
            _buildColorsSection(),
            const SizedBox(height: AppSpacing.md),

            // Fuel Type section
            _buildFuelTypeSection(),
            const SizedBox(height: AppSpacing.sm),

            // Driving Options section
            _buildDrivingOptionsSection(),
            const SizedBox(height: AppSpacing.md),

            _buildTransmissionTypeSection(),
            const SizedBox(height: AppSpacing.md),

            // Carfeatures section
            _buildFeaturesSection(),
            const SizedBox(height: AppSpacing.md),

            // Terms & Continue checkbox
            _buildTermsCheckbox(),
            const SizedBox(height: AppSpacing.md),

            // Submit button
            _buildSubmitButton(),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTextStyles.h2(context));
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    TextInputType keyboardType = TextInputType.text; // Default

    if (hint.toLowerCase().contains('renting price per day') ||
        hint.toLowerCase().contains('contact') ||
        hint.toLowerCase().contains('renting price per hour')) {
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

  Widget _buildCarType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Optional: Add a label here if needed, e.g., Text("Vehicle Type")
        Container(
          padding: const EdgeInsets.all(4), // Small padding for inner spacing
          decoration: BoxDecoration(
            color: AppColors.hostBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap:
                true, // Vital for using GridView inside a Column/ListView
            physics:
                const NeverScrollableScrollPhysics(), // Disables internal scrolling
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 columns wide
              childAspectRatio:
                  5.0, // Adjust this to change button height (higher number = shorter button)
              crossAxisSpacing: 4, // Horizontal space between buttons
              mainAxisSpacing: 4, // Vertical space between buttons
            ),
            itemCount: _vehicleTypes.length,
            itemBuilder: (context, index) {
              final type = _vehicleTypes[index];
              final isSelected = _selectedVehicleType == type;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedVehicleType = type;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      type,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color:
                            isSelected
                                ? AppColors.white
                                : const Color(0xFF4A4A4A),
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Widget _buildSegmentedControl() {
  //   return Container(
  //     decoration: BoxDecoration(
  //       color: AppColors.hostBackground, // Light gray background
  //       borderRadius: BorderRadius.circular(8),
  //     ),
  //     child: Row(
  //       children: [
  //         Expanded(child: _buildTabButton(0, 'Car Brand')),
  //         Expanded(child: _buildTabButton(1, 'Car Model')),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildTabButton(int index, String label) {
  //   final isSelected = _selectedTab == index;
  //   return GestureDetector(
  //     onTap: () {
  //       setState(() {
  //         _selectedTab = index;
  //       });
  //     },
  //     child: Container(
  //       padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
  //       decoration: BoxDecoration(
  //         color: isSelected ? AppColors.accent : Colors.transparent,
  //         borderRadius: BorderRadius.circular(8),
  //       ),
  //       child: Center(
  //         child: Text(
  //           label,
  //           style: TextStyle(
  //             color: isSelected ? AppColors.white : const Color(0xFF4A4A4A),
  //             fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
  //             fontSize: 14,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildCarBrandSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Regular Cars Brand
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Text(
            'Regular Cars Brand',
            style: AppTextStyles.body(
              context,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children:
              regularBrands.map((brand) {
                return _buildBrandChip(brand, false);
              }).toList(),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Luxury Cars Brand
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Text(
            'Luxury Cars Brand',
            style: AppTextStyles.body(
              context,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children:
              luxuryBrands.map((brand) {
                return _buildBrandChip(brand, true);
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildBrandChip(String brand, bool isLuxury) {
    final isSelected = _selectedBrand == brand;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBrand = brand;
        });
      },
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
      onPointerDown: (_) {
        setState(() {
          _isInteractingWithMap = true;
        });
      },
      onPointerUp: (_) {
        setState(() {
          _isInteractingWithMap = false;
        });
      },
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxHeight <= 0 || constraints.maxWidth <= 0) {
                return const SizedBox.shrink();
              }

              return Stack(
                children: [
                  // Google Map
                  SizedBox(
                    height: constraints.maxHeight,
                    width: constraints.maxWidth,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _currentPosition,
                        zoom: 14,
                      ),
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                      },
                      markers: _markers,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      zoomGesturesEnabled: true,
                      scrollGesturesEnabled: true,
                      tiltGesturesEnabled: true,
                      rotateGesturesEnabled: true,
                      onTap: (LatLng position) {
                        setState(() {
                          carLocation = position;
                          _markers.clear();
                          _markers.add(
                            Marker(
                              markerId: const MarkerId('car_location'),
                              position: position,
                              infoWindow: const InfoWindow(
                                title: 'Car Location',
                              ),
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueRed,
                              ),
                            ),
                          );
                        });
                      },
                    ),
                  ),

                  // Current Location Button (Bottom Right)
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
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child:
                                _isLoadingLocation
                                    ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.accent,
                                      ),
                                    )
                                    : Icon(
                                      Icons.my_location,
                                      color: AppColors.accent,
                                      size: 24,
                                    ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Location Info (Top)
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
                            Icon(
                              Icons.location_on,
                              color: AppColors.accent,
                              size: 16,
                            ),
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
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Upload Cars images', style: AppTextStyles.body(context)),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.hostBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.camera_alt,
                        color: AppColors.secondaryText,
                      ),
                      onPressed: _pickImageFromCamera,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.photo_library,
                        color: AppColors.secondaryText,
                      ),
                      onPressed: _pickImagesFromGallery,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Display selected images
          if (_selectedImages.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: AppSpacing.xs),
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(_selectedImages[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImages.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDrivingOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        _buildSectionTitle('Driving Options'),
        const SizedBox(height: AppSpacing.md),
        _buildDrivingOptions(Icons.directions_car, "Self Driving"),
        const SizedBox(height: AppSpacing.sm),
        _buildDrivingOptions(Icons.person, "With Driver"),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  Widget _buildDrivingOptions(IconData icon, String title) {
    final isSelected = _drivingOptions.contains(title);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _drivingOptions.remove(title); // Deselect if already selected
          } else {
            _drivingOptions.add(title); // Add to selection
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
          //color: isSelected ? AppColors.accent.withOpacity(0.2) : Colors.transparent,
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
                color:
                    isSelected
                        ? AppColors.primaryText
                        : AppColors.secondaryText,
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
        const SizedBox(height: AppSpacing.lg),
        _buildSectionTitle('Transmission Type'),
        const SizedBox(height: AppSpacing.md),
        _buildTransmission(Icons.directions_car, "Manual"),
        const SizedBox(height: AppSpacing.sm),
        _buildTransmission(Icons.person, "Automatic"),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  Widget _buildTransmission(IconData icon, String title) {
    final isSelected =
        _transmissionType == title; // Check if this option is selected

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _transmissionType = null; // Deselect if already selected
          } else {
            _transmissionType = title; // Set as the only selected option
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
          color:
              isSelected
                  ? AppColors.accent.withOpacity(0.2)
                  : Colors.transparent,
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
                color:
                    isSelected
                        ? AppColors.primaryText
                        : AppColors.secondaryText,
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Features'),
            TextButton(
              onPressed: () {
                // Handle "See All" action
              },
              child: Text(
                'See All',
                style: AppTextStyles.body(
                  context,
                ).copyWith(color: AppColors.accent),
              ),
            ),
          ],
        ),
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

  Widget _buildColorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Colors'),
            TextButton(
              onPressed: () {
                // Handle "See All" action
              },
              child: Text(
                'See All',
                style: AppTextStyles.body(
                  context,
                ).copyWith(color: AppColors.accent),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children:
              colors.map((colorData) {
                final isSelected = _selectedColor == colorData['name'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = colorData['name'];
                      });
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: colorData['color'],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  isSelected
                                      ? AppColors.accent
                                      : Colors.grey.shade300,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                          child:
                              isSelected
                                  ? const Icon(
                                    Icons.check,
                                    color: AppColors.white,
                                    size: 24,
                                  )
                                  : null,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          colorData['name'],
                          style: AppTextStyles.meta(context),
                        ),
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
          children:
              fuelTypes.map((fuelType) {
                final isSelected = _selectedFuelType == fuelType;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFuelType = fuelType;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accent : AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.border.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      fuelType,
                      style: AppTextStyles.body(context).copyWith(
                        color:
                            isSelected
                                ? AppColors.white
                                : AppColors.primaryText,
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildFeatures(IconData icon, String title) {
    final isSelected = _selectedFeatures.contains(title);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedFeatures.remove(title); // Deselect if already selected
          } else {
            _selectedFeatures.add(title); // Add to selection
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
          //color: isSelected ? AppColors.accent.withOpacity(0.2) : Colors.transparent,
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
                color:
                    isSelected
                        ? AppColors.primaryText
                        : AppColors.secondaryText,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildCarAbilityTextArea() {
  //   return Container(
  //     decoration: BoxDecoration(
  //       color: AppColors.white,
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(color: AppColors.border.withOpacity(0.2)),
  //     ),
  //     child: TextField(
  //       controller: _carAbilityController,
  //       maxLines: 5,
  //       maxLength: _maxCharacters,
  //       decoration: InputDecoration(
  //         hintText:
  //             'Enter your car ability , durability ,etc message here.........',
  //         hintStyle: AppTextStyles.meta(context),
  //         border: InputBorder.none,
  //         contentPadding: const EdgeInsets.all(AppSpacing.sm),
  //         counterText: '$_characterCount/$_maxCharacters',
  //         counterStyle: AppTextStyles.meta(context),
  //       ),
  //       style: AppTextStyles.body(context),
  //     ),
  //   );
  // }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _termsAccepted,
          onChanged: (value) {
            setState(() {
              _termsAccepted = value ?? false;
            });
          },
          activeColor: AppColors.accent,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _termsAccepted = !_termsAccepted;
              });
            },
            child: Row(
              children: [
                Text('Ts & continue', style: AppTextStyles.body(context)),
                const SizedBox(width: AppSpacing.xs),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: AppColors.secondaryText,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: (_termsAccepted && !_isSubmitting) ? _handleSubmit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          disabledBackgroundColor: AppColors.accent.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child:
            _isSubmitting
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : Text('Submit', style: AppTextStyles.button(context)),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    // Validate form fields
    if (_fullNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _contactController.text.isEmpty ||
        _carRegistrationController.text.isEmpty ||
        _selectedBrand == null ||
        _transmissionType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate location
    if (carLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location for your car'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate driving options
    if (_drivingOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one driving option'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate rent per day
    if (_rentPerDayController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the rent per day'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate rent per hour
    if (_rentPerHourController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the rent per hour'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate images
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload at least one car image'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get current user
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to add a car'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Upload images to Firebase Storage

      List<String> imageUrls = await _uploadImages(currentUser.uid);
      print(imageUrls);

      // Create vehicle document in Firestore
      final vehicleRef = await _saveVehicleData(currentUser.uid, imageUrls);
      final user = FirebaseAuth.instance.currentUser;
      print("AUTH UID: ${user?.uid}");
      print("PASSED userId: ${currentUser.uid}");

      // Create damage_pool document (one-to-one with vehicle)
      await _createDamagePool(vehicleRef.id);

      // Update owner's vehicle count
      await _updateOwnerVehicleCount(currentUser.uid);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Car added successfully!'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green.withOpacity(0.8),
          ),
        );

        // Navigate back after successful submission
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => HostNavigation()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding car: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  /// Upload images to Firebase Storage and return their URLs
  Future<List<String>> _uploadImages(String userId) async {
    List<String> imageUrls = [];

    for (int i = 0; i < _selectedImages.length; i++) {
      final imageFile = _selectedImages[i];
      final fileName =
          'vehicle_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      final storageRef = _storage.ref().child('vehicles/$userId/$fileName');
      // print("Uploading image ${i + 1}/${_selectedImages.length}");
      // print(imageFile);
      // print(fileName);
      // print(storageRef.fullPath);

      try {
        await storageRef.putFile(imageFile);
        final downloadUrl = await storageRef.getDownloadURL();
        imageUrls.add(downloadUrl);
        print(downloadUrl);
      } catch (e) {
        throw Exception('Failed to upload image ${i + 1}: $e');
      }
    }
    //print("images uploaded: $imageUrls");

    return imageUrls;
  }

  /// Save vehicle data to Firestore
  Future<DocumentReference> _saveVehicleData(
    String ownerId,
    List<String> imageUrls,
  ) async {
    // Determine driving_options based on user selection
    String drivingOptions;
    if (_drivingOptions.contains('Self Driving') &&
        _drivingOptions.contains('With Driver')) {
      drivingOptions = 'Both';
    } else if (_drivingOptions.contains('Self Driving')) {
      drivingOptions = 'Self Driving';
    } else if (_drivingOptions.contains('With Driver')) {
      drivingOptions = 'With Driver';
    } else {
      drivingOptions = '';
    }

    // Parse rent per day
    double rentPerDay = 0.0;
    if (_rentPerDayController.text.trim().isNotEmpty) {
      rentPerDay = double.tryParse(_rentPerDayController.text.trim()) ?? 0.0;
    }
    double rentPerHour = 0.0;
    if (_rentPerHourController.text.trim().isNotEmpty) {
      rentPerHour = double.tryParse(_rentPerHourController.text.trim()) ?? 0.0;
    }

    final vehicleData = {
      'owner_id': ownerId,
      'vehicle_type': _selectedVehicleType, // <--- Added here
      'make': _selectedBrand ?? '',
      'model': '',
      'year': DateTime.now().year,
      'images': imageUrls,
      'features': _selectedFeatures.toList(),
      'registration_number': _carRegistrationController.text.trim(),
      'market_value': 0,
      'self_drive_allowed': true,
      'with_driver_only': false,
      'driving_options': drivingOptions,
      'rent_per_day': rentPerDay,
      'rent_per_hour': rentPerHour,
      'created_at': FieldValue.serverTimestamp(),
      'recorded_damages': [],
      'location': {
        'latitude': carLocation!.latitude,
        'longitude': carLocation!.longitude,
      },
      'transmissionType': _transmissionType ?? 'Not specified',
      'color': _selectedColor,
      'fuel_type': _selectedFuelType,
      'description': _carAbilityController.text.trim(),
      'car_name': _fullNameController.text.trim(),
      'owner_email': _emailController.text.trim(),
      'owner_contact': _contactController.text.trim(),
      'street_address': _streetAddress ?? '',
    };

    // Return your collection reference call here, e.g.:
    // return FirebaseFirestore.instance.collection('vehicles').add(vehicleData);
    // (Assuming you handle the actual Firestore call outside or at the end of this block)
    final vehicleRef = await _firestore.collection('vehicles').add(vehicleData);
    return vehicleRef;
  }

  /// Create damage_pool document for the vehicle
  Future<void> _createDamagePool(String vehicleId) async {
    final damagePoolData = {
      'vehicle_id': vehicleId,
      'current_balance': 0.0,
      'last_contribution_at': null,
      'payment_status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('damage_pools')
        .doc(vehicleId)
        .set(damagePoolData);
  }

  /// Update owner's vehicle count
  Future<void> _updateOwnerVehicleCount(String ownerId) async {
    final ownerRef = _firestore.collection('users').doc(ownerId);

    await _firestore.runTransaction((transaction) async {
      final ownerDoc = await transaction.get(ownerRef);

      if (ownerDoc.exists) {
        final currentCount = ownerDoc.data()?['no_of_vehicles'] ?? 0;
        transaction.update(ownerRef, {'no_of_vehicles': currentCount + 1});
      } else {
        // Create owner document if it doesn't exist
        transaction.set(ownerRef, {
          'owner_id': ownerId,
          'no_of_vehicles': 1,
          'damages_claimed': 0,
          'created_at': FieldValue.serverTimestamp(),
          'user_id': ownerId, // Link to user document
        });
      }
    });
  }
}
