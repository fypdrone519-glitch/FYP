import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/car.dart';
import '../widgets/cars_map.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'package:carousel_slider/carousel_slider.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  GoogleMapController? _mapController;
  final CarouselSliderController _carouselController = CarouselSliderController();
  int _currentIndex = 0;
  final List<Car> _cars = [
    Car(
      id: '1',
      make: 'Toyota',
      model: 'Corolla',
      imageUrl: '',
      rating: 4.8,
      trips: 120,
      pricePerDay: 5000,
      features: ['Automatic'],
      badges: ['Instant'],
      latitude: 24.8607,
      longitude: 67.0011,
    ),
    Car(
      id: '2',
      make: 'Honda',
      model: 'Civic',
      imageUrl: '',
      rating: 4.9,
      trips: 80,
      pricePerDay: 6000,
      features: ['Automatic'],
      badges: ['Verified'],
      latitude: 24.865,
      longitude: 67.01,
    ),
  ];

  void _onPinTapped(Car car) {
    // Find the index of the tapped car
    final carIndex = _cars.indexWhere((c) => c.id == car.id);
    if (carIndex != -1) {
      // Animate the carousel to the selected car
      _carouselController.animateToPage(carIndex);
    }
  }

  void _openCarSheet(Car car) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          maxChildSize: 0.85,
          builder: (context, controller) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.foreground,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.cardRadius),
                ),
              ),
              child: ListView(
                controller: controller,
                children: [
                  const SizedBox(height: 12),

                  /// HANDLE
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// IMAGE (FULL WIDTH – FIXED)
                  SizedBox(
                    width: double.infinity,
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child:
                            car.imageUrl.isNotEmpty
                                ? Image.network(car.imageUrl, fit: BoxFit.cover)
                                : Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(
                                    Icons.car_rental,
                                    size: 90,
                                    color: Colors.grey,
                                  ),
                                ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          car.fullName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Karachi, Pakistan',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.lightGreen,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Available • Rs ${car.pricePerDay}/day',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CarsMap(
            cars: _cars,
            onCarTap: _onPinTapped,
            onBoundsChanged: (_) {},
            onMapReady: (controller) {
              _mapController = controller;
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
          height: MediaQuery.of(context).size.height * 0.32, // Slightly taller for better visuals
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
                                child: car.imageUrl.isNotEmpty
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                    const Text(
                                      'Karachi, Pakistan',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                
                                /// Bottom row with date and duration
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(8),
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
              },
              height: MediaQuery.of(context).size.height,
              viewportFraction: 0.85, // How much of the card is visible
              enlargeCenterPage: true, // Makes center card larger
              enlargeFactor: 0.15, // How much to enlarge (subtle)
              enlargeStrategy: CenterPageEnlargeStrategy.scale, // Scale animation
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
