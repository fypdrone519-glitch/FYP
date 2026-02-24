import 'package:car_listing_app/screens/car_details.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/car.dart';
import '../widgets/cars_map.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  // Fallback location — change to your preferred city center
  static const LatLng _defaultLocation = LatLng(33.6844, 73.0479); // Rawalpindi
  GoogleMapController? _mapController;
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  int _currentIndex = 0;
  List<Car> _cars = [];
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _loadCars();
    // _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    //print('Attempting to get user location...');
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      //print('Location permission status: $permission');

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        // Fall back to default location
        _moveCameraTo(_defaultLocation);
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      //print('User location obtained: ${position.latitude}, ${position.longitude}');

      _moveCameraTo(LatLng(position.latitude, position.longitude));
    } catch (e) {
      // Any error → fall back to default
      _moveCameraTo(_defaultLocation);
    }
  }

  void _moveCameraTo(LatLng target) {
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, 13));
  }

  Future<String> _getaddressFromLatLng(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        return '${place.locality}, ${place.country}';
      }
    } catch (e) {
      // print('Error in reverse geocoding: $e');
    }
    return 'Unknown location';
  }

  Future<void> _loadCars() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final QuerySnapshot vehiclesSnapshot =
          await _firestore.collection('vehicles').get();

      // Create a list of futures to fetch all addresses
      final List<Future<Car>> carFutures =
          vehiclesSnapshot.docs.map((doc) async {
            final data = doc.data() as Map<String, dynamic>;

            // Get features - take first 3
            List<String> features = [];
            if (data['features'] != null && data['features'] is List) {
              features = List<String>.from(data['features']).take(3).toList();
            }

            // Get location
            double? latitude;
            double? longitude;
            if (data['location'] != null) {
              final location = data['location'] as Map<String, dynamic>;
              latitude = (location['latitude'] as num?)?.toDouble();
              longitude = (location['longitude'] as num?)?.toDouble();
            }

            // ✅ AWAIT the address fetch
            String address = 'Unknown location';
            if (latitude != null && longitude != null) {
              address = await _getaddressFromLatLng(latitude, longitude);
              // print('Resolved address for ${data['car_name']}: $address');
            }

            // Get rent per day
            double rentPerDay = 0.0;
            if (data['rent_per_day'] != null) {
              rentPerDay = (data['rent_per_day'] as num).toDouble();
            }

            // Get rent per hour
            double rentPerHour = 0.0;
            if (data['rent_per_hour'] != null) {
              rentPerHour = (data['rent_per_hour'] as num).toDouble();
            }

            // Get images
            String imageUrl = '';
            if (data['images'] != null && data['images'] is List) {
              final images = List<String>.from(data['images']);
              if (images.isNotEmpty) {
                imageUrl = images[0];
              }
            }

            return Car(
              id: doc.id,
              make: data['make'] ?? '',
              model: data['car_name'] ?? '',
              imageUrl: imageUrl,
              rating: 4.5,
              trips: 0,
              pricePerDay: rentPerDay,
              pricePerHour: rentPerHour,
              features: features,
              badges: [],
              latitude: latitude,
              longitude: longitude,
              street_address: address, // ✅ Now has the actual address
            );
          }).toList();

      // ✅ Wait for all cars to be created with their addresses
      final List<Car> cars = await Future.wait(carFutures);

      // Filter out cars without valid location
      final validCars =
          cars
              .where((car) => car.latitude != null && car.longitude != null)
              .toList();

      setState(() {
        _cars = validCars;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading cars: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading cars: $e')));
      }
    }
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _onPinTapped(Car car) {
    // Find the index of the tapped car
    final carIndex = _cars.indexWhere((c) => c.id == car.id);
    if (carIndex != -1) {
      // Animate the carousel to the selected car
      _carouselController.animateToPage(carIndex);

      // Animate map to car location
      if (car.latitude != null && car.longitude != null) {
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(car.latitude!, car.longitude!), 15),
        );
      }
    }
  }

  void _openCarSheet(Car car) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) =>
                CarDetails(vehicleId: car.id, fromMap: true),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0); // Start from bottom
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    if (_cars.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.car_rental, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No cars available',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      body: Stack(
        children: [
          CarsMap(
            cars: _cars,
            onCarTap: _onPinTapped,
            onBoundsChanged: (_) {},
            onMapReady: (controller) {
              _mapController = controller;
              _getUserLocation();
            },
            selectedCarId: _cars[_currentIndex].id,
          ),

          /// BACK
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FloatingActionButton(
                  heroTag: null,
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: Colors.black),
                ),
              ),
            ),
          ),

          /// BOTTOM CARDS
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            height:
                MediaQuery.of(context).size.height *
                0.32, // Slightly taller for better visuals
            child: CarouselSlider.builder(
              carouselController: _carouselController,
              itemCount: _cars.length,
              itemBuilder: (context, index, realIndex) {
                final car = _cars[index];
                return AnimatedOpacity(
                  opacity: _currentIndex == index ? 1.0 : 0.9,
                  duration: const Duration(milliseconds: 100),
                  child: GestureDetector(
                    onTap: () => _openCarSheet(car),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// IMAGE with overlay rating
                          Stack(
                            children: [
                              // Image
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 160,
                                  child:
                                      car.imageUrl.isNotEmpty
                                          ? Image.network(
                                            car.imageUrl,
                                            fit: BoxFit.cover,
                                          )
                                          : Container(
                                            color: Colors.grey.shade200,
                                            child: const Icon(
                                              Icons.car_rental,
                                              size: 40,
                                              color: Colors.grey,
                                            ),
                                          ),
                                ),
                              ),

                              // Rating overlay
                              Positioned(
                                top: 12,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${car.rating.toStringAsFixed(1)} 2466 reviews',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          /// CONTENT
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        car.fullName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        car.street_address ??
                                            'Unknown location',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),

                                  /// Bottom row with date and duration
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          '6-13 May  From Rs ${car.pricePerDay}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const Text(
                                        '7 Nights',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
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
              },
              options: CarouselOptions(
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentIndex = index;
                  });

                  // Animate map to the selected car's location
                  final selectedCar = _cars[index];
                  if (selectedCar.latitude != null &&
                      selectedCar.longitude != null) {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(selectedCar.latitude!, selectedCar.longitude!),
                        15, // Zoom level (adjust as needed: 10-20, higher = more zoomed in)
                      ),
                    );
                  }
                },
                height: MediaQuery.of(context).size.height,
                viewportFraction: 0.85, // How much of the card is visible
                enlargeCenterPage: true, // Makes center card larger
                enlargeFactor: 0.15, // How much to enlarge (subtle)
                enlargeStrategy:
                    CenterPageEnlargeStrategy.scale, // Scale animation
                enableInfiniteScroll: false,
                initialPage: 0,
                autoPlay: false,
                padEnds: true, // Adds padding at start/end
              ),
            ),
          ),
        ],
      ),
    );
  }
}
