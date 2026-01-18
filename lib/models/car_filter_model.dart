class CarFilterModel {
  // Price range
  final double minPrice;
  final double maxPrice;

  // Car brands (multi-select)
  final Set<String> selectedBrands;

  // Location
  final String? location;

  // Drive type (multi-select)
  final Set<String> driveTypes; // 'Self Driving', 'With Driver'

  // Transmission (single-select)
  final String? transmission; // 'Automatic', 'Manual'

  // Fuel type (multi-select)
  final Set<String> fuelTypes; // 'Hybrid', 'Petrol', 'Diesel', 'Electric'

  // Delivery options (multi-select)
  final Set<String> deliveryOptions; // 'Delivers to Me', 'Pickup'

  CarFilterModel({
    this.minPrice = 1000.0,
    this.maxPrice = 50000.0,
    Set<String>? selectedBrands,
    this.location,
    Set<String>? driveTypes,
    this.transmission,
    Set<String>? fuelTypes,
    Set<String>? deliveryOptions,
  })  : selectedBrands = selectedBrands ?? {},
        driveTypes = driveTypes ?? {},
        fuelTypes = fuelTypes ?? {},
        deliveryOptions = deliveryOptions ?? {};

  // Create a copy with updated values
  CarFilterModel copyWith({
    double? minPrice,
    double? maxPrice,
    Set<String>? selectedBrands,
    String? location,
    Set<String>? driveTypes,
    String? transmission,
    Set<String>? fuelTypes,
    Set<String>? deliveryOptions,
  }) {
    return CarFilterModel(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      selectedBrands: selectedBrands ?? this.selectedBrands,
      location: location ?? this.location,
      driveTypes: driveTypes ?? this.driveTypes,
      transmission: transmission ?? this.transmission,
      fuelTypes: fuelTypes ?? this.fuelTypes,
      deliveryOptions: deliveryOptions ?? this.deliveryOptions,
    );
  }

  // Reset all filters to default
  CarFilterModel reset() {
    return CarFilterModel(
      minPrice: 1000.0,
      maxPrice: 50000.0,
    );
  }

  // Check if any filter is active
  bool get hasActiveFilters {
    return minPrice != 1000.0 ||
        maxPrice != 50000.0 ||
        selectedBrands.isNotEmpty ||
        (location != null && location!.isNotEmpty) ||
        driveTypes.isNotEmpty ||
        transmission != null ||
        fuelTypes.isNotEmpty ||
        deliveryOptions.isNotEmpty;
  }
}