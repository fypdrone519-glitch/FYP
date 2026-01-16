import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';

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
  final TextEditingController _drivingLicenseController = TextEditingController();
  final TextEditingController _carRegistrationController = TextEditingController();
  final TextEditingController _carAbilityController = TextEditingController();

  // State variables
  Set<String> _selectedFeatures = {}; // Changed from String? to Set<String>
  int _selectedTab = 0; // 0 = Car Brand, 1 = Car Model
  String? _selectedBrand;
  String? _selectedColor;
  String? _selectedFuelType;
  bool _termsAccepted = false;
  int _characterCount = 0;
  final int _maxCharacters = 1000;

  //image selection variable
  List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

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
  
  // Method to pick images from gallery
  Future<void> _pickImagesFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((image) => File(image.path)).toList());
        });
      }
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking photo: $e')),
      );
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.hostBackground, // Light gray background
      appBar: AppBar(
        backgroundColor: AppColors.hostBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Add Car',
          style: AppTextStyles.h2(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Car owner information section
            _buildSectionTitle('Car owner information'),
            const SizedBox(height: AppSpacing.sm),
            _buildTextField(_fullNameController, 'Full Name'),
            const SizedBox(height: AppSpacing.sm),
            _buildTextField(_emailController, 'Email Addresses'),
            const SizedBox(height: AppSpacing.sm),
            _buildTextField(_contactController, 'Contact'),
            const SizedBox(height: AppSpacing.sm),
            // Car Registration Number
            _buildTextField(_carRegistrationController, 'Car Registration Number'),
            const SizedBox(height: AppSpacing.md),

            // Car information section
            _buildSectionTitle('Car information'),
            const SizedBox(height: AppSpacing.sm),
            
            // Car Brand / Car Model tabs
            _buildSegmentedControl(),
            const SizedBox(height: AppSpacing.sm),

            // Car Brand selection (when tab 0 is selected)
            if (_selectedTab == 0) _buildCarBrandSelection(),
            const SizedBox(height: AppSpacing.sm),

            // Image upload area
            _buildImageUploadSection(),
            const SizedBox(height: AppSpacing.sm),

            // Colors section
            _buildColorsSection(),
            const SizedBox(height: AppSpacing.md),

            // Fuel Type section
            _buildFuelTypeSection(),
            const SizedBox(height: AppSpacing.sm),

            // Carfeatures section
            _buildFeatuers(),
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
    return Text(
      title,
      style: AppTextStyles.h2(context),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.2)),
      ),
      child: TextField(
        controller: controller,
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
        color: AppColors.hostBackground, // Light gray background
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(0, 'Car Brand'),
          ),
          Expanded(
            child: _buildTabButton(1, 'Car Model'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
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
        // Regular Cars Brand
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Text(
            'Regular Cars Brand',
            style: AppTextStyles.body(context).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: regularBrands.map((brand) {
            return _buildBrandChip(brand, false);
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.sm),
        
        // Luxury Cars Brand
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Text(
            'Luxury Cars Brand',
            style: AppTextStyles.body(context).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: luxuryBrands.map((brand) {
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
            Text(
              'Upload Cars images',
              style: AppTextStyles.body(context),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.hostBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.camera_alt, color: AppColors.secondaryText),
                    onPressed: _pickImageFromCamera,
                  ),
                  IconButton(
                    icon: const Icon(Icons.photo_library, color: AppColors.secondaryText),
                    onPressed: _pickImagesFromGallery,
                  ),
                ],
              ),
            )
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

  Widget _buildFeatuers(){
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
                style: AppTextStyles.body(context).copyWith(
                  color: AppColors.accent,
                ),
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
                style: AppTextStyles.body(context).copyWith(
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: colors.map((colorData) {
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
                          color: isSelected ? AppColors.accent : Colors.grey.shade300,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: AppColors.white, size: 24)
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
          children: fuelTypes.map((fuelType) {
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
      width: MediaQuery.of( context).size.width*0.9,
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
          hintText: 'Enter your car ability , durability ,etc message here.........',
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
                Text(
                  'Trams & continue',
                  style: AppTextStyles.body(context),
                ),
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
        onPressed: _termsAccepted ? _handleSubmit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          disabledBackgroundColor: AppColors.accent.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Submit',
          style: AppTextStyles.button(context),
        ),
      ),
    );
  }

  void _handleSubmit() {
    // Handle form submission
    if (_fullNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _contactController.text.isEmpty ||
        _drivingLicenseController.text.isEmpty ||
        _carRegistrationController.text.isEmpty ||
        _selectedBrand == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // TODO: Implement actual submission logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Car added successfully!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
