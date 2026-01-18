import 'package:flutter/material.dart';
import '../models/car_filter_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';

class CarFilterBottomSheet extends StatefulWidget {
  final CarFilterModel initialFilters;

  const CarFilterBottomSheet({
    super.key,
    required this.initialFilters,
  });

  @override
  State<CarFilterBottomSheet> createState() => _CarFilterBottomSheetState();
}

class _CarFilterBottomSheetState extends State<CarFilterBottomSheet> {
  late CarFilterModel _filters;

  // Predefined brand list for Pakistan
  static const List<String> _brands = [
    'Toyota',
    'Honda',
    'Suzuki',
    'Hyundai',
    'Kia',
    'Nissan',
    'Changan',
    'MG',
    'Audi',
    'BMW',
    'Mercedes-Benz',
  ];

  static const List<String> _driveTypes = ['Self-drive', 'With driver'];
  static const List<String> _transmissionTypes = ['Automatic', 'Manual'];
  static const List<String> _fuelTypes = ['Hybrid', 'Petrol', 'Diesel', 'Electric'];
  static const List<String> _deliveryOptions = ['Delivers to Me', 'Pickup'];

  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  RangeValues _priceRange = const RangeValues(1000, 50000);

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
    _priceRange = RangeValues(_filters.minPrice, _filters.maxPrice);
    _locationController.text = _filters.location ?? '';
    _minPriceController.text = _filters.minPrice.toInt().toString();
    _maxPriceController.text = _filters.maxPrice.toInt().toString();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _filters = CarFilterModel().reset();
      _priceRange = const RangeValues(1000, 50000);
      _locationController.clear();
      _minPriceController.text = '1000';
      _maxPriceController.text = '50000';
    });
  }

  void _applyFilters() {
    final updatedFilters = _filters.copyWith(
      minPrice: _priceRange.start,
      maxPrice: _priceRange.end,
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
    );
    Navigator.of(context).pop(updatedFilters);
  }

  String _formatPrice(double price) {
    return 'PKR ${price.toInt().toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.xs),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: AppTextStyles.h2(context),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.primaryText),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Price Per Day
                  _buildPriceSection(),
                  const SizedBox(height: AppSpacing.lg),

                  // 2. Car Brand
                  _buildBrandSection(),
                  const SizedBox(height: AppSpacing.lg),

                  // 3. Location
                  _buildLocationSection(),
                  const SizedBox(height: AppSpacing.lg),

                  // 4. Drive Type
                  _buildDriveTypeSection(),
                  const SizedBox(height: AppSpacing.lg),

                  // 5. Transmission
                  _buildTransmissionSection(),
                  const SizedBox(height: AppSpacing.lg),

                  // 6. Fuel Type
                  _buildFuelTypeSection(),
                  const SizedBox(height: AppSpacing.lg),

                  // 7. Delivery Options
                  _buildDeliveryOptionsSection(),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),

          // Sticky Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom:18.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _resetFilters,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: Text(
                        'Reset',
                        style: AppTextStyles.body(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: Text(
                        'Apply Filters',
                        style: AppTextStyles.button(context).copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Per Day',
          style: AppTextStyles.h2(context),
        ),
        const SizedBox(height: AppSpacing.md),
        
        // Price range display
        Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Text(
            '${_formatPrice(_priceRange.start)} – ${_formatPrice(_priceRange.end)} / day',
            style: AppTextStyles.body(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
        ),
        
        // Range Slider with histogram-like visualization
        _buildRangeSliderWithHistogram(),
        
        const SizedBox(height: AppSpacing.md),
        
        // Min/Max Input Fields
        Row(
          children: [
            Expanded(
              child: _buildPriceInput(
                label: 'Minimum (PKR)',
                controller: _minPriceController,
                onChanged: (value) {
                  final price = double.tryParse(value) ?? 1000.0;
                  if (price >= 1000 && price <= 50000 && price <= _priceRange.end) {
                    setState(() {
                      _priceRange = RangeValues(
                        price.clamp(1000.0, _priceRange.end),
                        _priceRange.end,
                      );
                      _maxPriceController.text = _priceRange.end.toInt().toString();
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildPriceInput(
                label: 'Maximum (PKR)',
                controller: _maxPriceController,
                onChanged: (value) {
                  final price = double.tryParse(value) ?? 50000.0;
                  if (price >= 1000 && price <= 50000 && price >= _priceRange.start) {
                    setState(() {
                      _priceRange = RangeValues(
                        _priceRange.start,
                        price.clamp(_priceRange.start, 50000.0),
                      );
                      _minPriceController.text = _priceRange.start.toInt().toString();
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

Widget _buildRangeSliderWithHistogram() {
  return Column(
    children: [
      // Price labels above handles
      Stack(
        children: [
          // Histogram visualization background
          SizedBox(
            height: 80,
            child: CustomPaint(
              painter: _HistogramPainter(
                priceRange: _priceRange,
                minPrice: 1000,
                maxPrice: 50000,
              ),
              size: Size.infinite,
            ),
          ),
          // Range slider with custom theme
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.background.withAlpha(90), // Line between thumbs
                inactiveTrackColor: Colors.transparent, // Line outside range
                thumbColor: AppColors.background, // Circle color
                overlayColor: AppColors.background.withOpacity(0.2), // Ripple effect
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
                rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 14),
                trackHeight: 4,
                valueIndicatorColor: AppColors.accent,
              ),
              child: RangeSlider(
                values: _priceRange,
                min: 1000,
                max: 50000,
                divisions: 490,
                onChanged: (RangeValues values) {
                  setState(() {
                    _priceRange = values;
                    _minPriceController.text = values.start.toInt().toString();
                    _maxPriceController.text = values.end.toInt().toString();
                  });
                },
              ),
            ),
          ),
          // Custom labels positioned above handles
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            height: 30,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final leftPosition = ((_priceRange.start - 1000) / (50000 - 1000)) * constraints.maxWidth;
                final rightPosition = ((_priceRange.end - 1000) / (50000 - 1000)) * constraints.maxWidth;
                
                return Stack(
                  children: [
                    Positioned(
                      left: leftPosition.clamp(0.0, constraints.maxWidth - 80),
                      child: _buildPriceLabel(_priceRange.start),
                    ),
                    Positioned(
                      left: (rightPosition - 80).clamp(0.0, constraints.maxWidth - 80),
                      child: _buildPriceLabel(_priceRange.end),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ],
  );
}
  Widget _buildPriceLabel(double price) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryText,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _formatPrice(price),
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPriceInput({
    required String label,
    required TextEditingController controller,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.meta(context),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          decoration: BoxDecoration(
            color: AppColors.foreground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withOpacity(0.2)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              //prefixIcon: const Icon(Icons.price, color: AppColors.secondaryText),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
            ),
            style: AppTextStyles.body(context),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

 Widget _buildBrandSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Car Brand',
        style: AppTextStyles.h2(context),
      ),
      const SizedBox(height: AppSpacing.md),
      Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: _brands.map((brand) {
          final isSelected = _filters.selectedBrands.contains(brand);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _filters = _filters.copyWith(
                    selectedBrands: {..._filters.selectedBrands}..remove(brand),
                  );
                } else {
                  _filters = _filters.copyWith(
                    selectedBrands: {..._filters.selectedBrands}..add(brand),
                  );
                }
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
        }).toList(),
      ),
    ],
  );
}

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: AppTextStyles.h2(context),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: AppColors.foreground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withOpacity(0.2)),
          ),
          child: TextField(
            controller: _locationController,
            decoration: InputDecoration(
              hintText: 'Enter city or area',
              hintStyle: AppTextStyles.meta(context),
              prefixIcon: const Icon(Icons.location_on, color: AppColors.secondaryText),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
            ),
            style: AppTextStyles.body(context),
          ),
        ),
      ],
    );
  }

  Widget _buildDriveTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Drive Type',
          style: AppTextStyles.h2(context),
        ),
        const SizedBox(height: AppSpacing.md),
        ..._driveTypes.map((type) {
          // Map UI label to database format for checking
          final dbType = type == 'Self-drive' ? 'Self Driving' : 'With Driver';
          final isSelected = _filters.driveTypes.contains(dbType);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _buildSelectableOption(
              label: type,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  // Map UI labels to database format
                  final dbType = type == 'Self-drive' ? 'Self Driving' : 'With Driver';
                  
                  if (isSelected) {
                    _filters = _filters.copyWith(
                      driveTypes: {..._filters.driveTypes}..remove(dbType),
                    );
                  } else {
                    _filters = _filters.copyWith(
                      driveTypes: {..._filters.driveTypes}..add(dbType),
                    );
                  }
                });
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTransmissionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transmission',
          style: AppTextStyles.h2(context),
        ),
        const SizedBox(height: AppSpacing.md),
        ..._transmissionTypes.map((type) {
          final isSelected = _filters.transmission == type;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _buildSelectableOption(
              label: type,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _filters = _filters.copyWith(
                    transmission: isSelected ? null : type,
                  );
                });
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFuelTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fuel Type',
          style: AppTextStyles.h2(context),
        ),
        const SizedBox(height: AppSpacing.md),
        ..._fuelTypes.map((type) {
          final isSelected = _filters.fuelTypes.contains(type);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _buildSelectableOption(
              label: type,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _filters = _filters.copyWith(
                      fuelTypes: {..._filters.fuelTypes}..remove(type),
                    );
                  } else {
                    _filters = _filters.copyWith(
                      fuelTypes: {..._filters.fuelTypes}..add(type),
                    );
                  }
                });
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDeliveryOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Options',
          style: AppTextStyles.h2(context),
        ),
        const SizedBox(height: AppSpacing.md),
        ..._deliveryOptions.map((option) {
          final isSelected = _filters.deliveryOptions.contains(option);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _buildSelectableOption(
              label: option,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _filters = _filters.copyWith(
                      deliveryOptions: {..._filters.deliveryOptions}..remove(option),
                    );
                  } else {
                    _filters = _filters.copyWith(
                      deliveryOptions: {..._filters.deliveryOptions}..add(option),
                    );
                  }
                });
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.foreground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.body(context).copyWith(
            color: isSelected ? AppColors.white : AppColors.primaryText,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectableOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withOpacity(0.1) : AppColors.foreground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? AppColors.accent : AppColors.secondaryText,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body(context).copyWith(
                  color: isSelected ? AppColors.accent : AppColors.primaryText,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for histogram visualization
class _HistogramPainter extends CustomPainter {
  final RangeValues priceRange;
  final double minPrice;
  final double maxPrice;

  _HistogramPainter({
    required this.priceRange,
    required this.minPrice,
    required this.maxPrice,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Draw base line (thinner and more subtle)
    paint.color = AppColors.accent.withAlpha(70);
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      paint..strokeWidth = 1,
    );

    // Draw histogram bars
    final barCount = 40; // More bars for smoother look
    final barWidth = size.width / barCount;
    final maxBarHeight = size.height * 0.9;
    
    for (int i = 0; i < barCount; i++) {
      final barStart = i * barWidth;
      final barPriceStart = minPrice + (i * (maxPrice - minPrice) / barCount);
      final barPriceEnd = minPrice + ((i + 1) * (maxPrice - minPrice) / barCount);
      
      // Check if bar is in selected range
      final isInRange = barPriceEnd >= priceRange.start && barPriceStart <= priceRange.end;
      
      // Create a more natural distribution (bell curve-like)
      final centerDistance = ((i - barCount / 2).abs() / (barCount / 2));
      final heightMultiplier = 1 - (centerDistance * 0.7);
      final randomVariation = (i % 3) * 0.1;
      final height = (maxBarHeight * heightMultiplier * (0.5 + randomVariation)).toDouble();
      
      paint.color = isInRange
          ? AppColors.accent.withOpacity(0.7)
          : AppColors.accent.withAlpha(70);
      
      // Draw thinner bars with less spacing
     canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            barStart + 2,  // Increase from 1 to 2 or 3
            size.height - height - 1, 
            barWidth - 4,  // Increase from -2 to -4 or -6
            height,
          ),
          const Radius.circular(3.5),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_HistogramPainter oldDelegate) {
    return oldDelegate.priceRange != priceRange;
  }
}