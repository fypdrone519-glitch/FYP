class Car {
  final String id;
  final String model;
  final String make;
  final String imageUrl;
  final double rating;
  final int trips;
  final double pricePerDay;
  final List<String> features;
  final List<String> badges; // e.g., "Instant", "Delivery", "Verified"
  final double? latitude;
  final double? longitude;

  Car({
    required this.id,
    required this.model,
    required this.make,
    required this.imageUrl,
    required this.rating,
    required this.trips,
    required this.pricePerDay,
    required this.features,
    required this.badges,
    this.latitude,
    this.longitude,
  });

  String get fullName => '$make $model';
}

