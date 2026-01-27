import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';

class BookingDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> vehicleData;
  
  const BookingDetailsScreen({
    super.key,
    required this.vehicleData,
  });

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  int _currentStep = 0;
  bool _bookWithDriver = false;
  String _selectedGender = 'Male';
  String _selectedRentalPeriod = 'Day';
  DateTime? _pickupDate;
  DateTime? _returnDate;
  
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  String get _drivingOptions => widget.vehicleData['driving_options'] ?? 'Self Driving';
  bool get _canToggleDriver => _drivingOptions == 'Both';
  bool get _onlyWithDriver => _drivingOptions == 'With Driver';
  
  // Parse availability dates from vehicleData
  Set<DateTime> get _availableDates {
    final Set<DateTime> availableDates = {};
    if (widget.vehicleData['availability'] != null) {
      final List<dynamic> availabilityList = widget.vehicleData['availability'];
      for (var dateString in availabilityList) {
        if (dateString is String) {
          try {
            final parts = dateString.split('-');
            if (parts.length == 3) {
              final year = int.parse(parts[0]);
              final month = int.parse(parts[1]);
              final day = int.parse(parts[2]);
              availableDates.add(_normalizeDate(DateTime(year, month, day)));
            }
          } catch (e) {
            print('Error parsing availability date: $dateString');
          }
        }
      }
    }
    return availableDates;
  }
  
  // Check if a date is available
  bool _isDateAvailable(DateTime date) {
    final normalizedDate = _normalizeDate(date);
    return _availableDates.contains(normalizedDate);
  }
  
  // Get the earliest available date
  DateTime? get _earliestAvailableDate {
    if (_availableDates.isEmpty) return null;
    return _availableDates.reduce((a, b) => a.isBefore(b) ? a : b);
  }
  
  // Get the latest available date
  DateTime? get _latestAvailableDate {
    if (_availableDates.isEmpty) return null;
    return _availableDates.reduce((a, b) => a.isAfter(b) ? a : b);
  }
  
  // Calculate number of days between pickup and return dates
  int get _numberOfDays {
    if (_pickupDate == null || _returnDate == null) {
      return 0;
    }
    final normalizedPickup = _normalizeDate(_pickupDate!);
    final normalizedReturn = _normalizeDate(_returnDate!);
    return normalizedReturn.difference(normalizedPickup).inDays + 1; // +1 to include both start and end dates
  }
  
  // Calculate total price
  double get _totalPrice {
    final rentPerDay = (widget.vehicleData['rent_per_day'] as num?)?.toDouble() ?? 0.0;
    return rentPerDay * _numberOfDays;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Booking Details',
          style: AppTextStyles.h2(context),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Stepper
          _buildProgressStepper(),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book with driver toggle
                  _buildDriverSection(),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Full Name
                  _buildTextField(
                    controller: _fullNameController,
                    icon: Icons.person_outline,
                    hint: 'Full Name*',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  
                  // Email
                  _buildTextField(
                    controller: _emailController,
                    icon: Icons.email_outlined,
                    hint: 'Email Address*',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  
                  // Contact
                  _buildTextField(
                    controller: _contactController,
                    icon: Icons.phone_outlined,
                    hint: 'Contact*',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Gender
                  Text('Gender', style: AppTextStyles.h2(context)),
                  const SizedBox(height: AppSpacing.sm),
                  _buildGenderSelection(),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Rental Date & Time
                  Text('Rental Date &Time', style: AppTextStyles.h2(context)),
                  const SizedBox(height: AppSpacing.sm),
                  _buildRentalPeriodSelection(),
                  const SizedBox(height: AppSpacing.sm),
                  _buildDateSelection(),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Car Location
                  Text('Car Location', style: AppTextStyles.h2(context)),
                  const SizedBox(height: AppSpacing.sm),
                  _buildLocationField(),
                  const SizedBox(height: AppSpacing.xl),
                  
                  // Pay Now Button
                  _buildPayButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStepper() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          _buildStep(0, 'Booking details'),
          _buildStepLine(0),
          _buildStep(1, 'Payment methods'),
          _buildStepLine(1),
          _buildStep(2, 'confirmation'),
        ],
      ),
    );
  }

  Widget _buildStep(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive ? AppColors.accent : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: isActive
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? Colors.black : Colors.grey,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int step) {
    final isActive = _currentStep > step;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: isActive ? AppColors.accent : Colors.grey[300],
      ),
    );
  }

  Widget _buildDriverSection() {
    if (_onlyWithDriver) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.accent, size: 20),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                'This vehicle is only available with driver',
                style: AppTextStyles.body(context),
              ),
            ),
          ],
        ),
      );
    }
    
    if (!_canToggleDriver) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.accent, size: 20),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                'This vehicle is only for self driving',
                style: AppTextStyles.body(context),
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Book with driver',
                style: AppTextStyles.body(context).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                "Don't have a driver? book with driver.",
                style: AppTextStyles.meta(context).copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
          Switch(
            value: _bookWithDriver,
            onChanged: (value) => setState(() => _bookWithDriver = value),
            activeColor: AppColors.accent,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey),
          hintText: hint,
          hintStyle: AppTextStyles.meta(context),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
        ),
      ),
    );
  }

  Widget _buildGenderSelection() {
    return Row(
      children: [
        _buildGenderChip('Male', Icons.male),
        const SizedBox(width: AppSpacing.xs),
        _buildGenderChip('Female', Icons.female),
        const SizedBox(width: AppSpacing.xs),
        _buildGenderChip('Others', Icons.transgender),
      ],
    );
  }

  Widget _buildGenderChip(String gender, IconData icon) {
    final isSelected = _selectedGender == gender;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = gender),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? AppColors.accent : Colors.grey[300]!,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                gender,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRentalPeriodSelection() {
    return Row(
      children: [
        _buildPeriodChip('Hour'),
        const SizedBox(width: AppSpacing.xs),
        _buildPeriodChip('Day'),
        const SizedBox(width: AppSpacing.xs),
        _buildPeriodChip('Weekly'),
        const SizedBox(width: AppSpacing.xs),
        _buildPeriodChip('Monthly'),
      ],
    );
  }

  Widget _buildPeriodChip(String period) {
    final isSelected = _selectedRentalPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRentalPeriod = period),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.accent : Colors.grey[300]!,
            ),
          ),
          child: Center(
            child: Text(
              period,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelection() {
    return Row(
      children: [
        Expanded(
          child: _buildDateField(
            'Pick up Date',
            _pickupDate,
            true,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildDateField(
            'Return Date',
            _returnDate,
            false,
          ),
        ),
      ],
    );
  }

 Widget _buildDateField(String label, DateTime? date, bool isPickup) {
  return GestureDetector(
    onTap: () => _showDatePickerDialog(label, date, isPickup),
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.meta(context).copyWith(
              color: AppColors.secondaryText,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                date != null 
                    ? '${date.day}/ ${date.month}/ ${date.year}'
                    : 'Select date',
                style: AppTextStyles.body(context),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Future<void> _showDatePickerDialog(String label, DateTime? currentDate, bool isPickup) async {
  // Use availability range if available, otherwise use default range
  final DateTime baseFirstDay = _earliestAvailableDate ?? _normalizeDate(DateTime.now());
  final DateTime baseLastDay = _latestAvailableDate ?? DateTime.now().add(const Duration(days: 365));
  
  final DateTime firstDay = isPickup 
      ? baseFirstDay 
      : (_pickupDate != null ? _normalizeDate(_pickupDate!) : baseFirstDay);
  final DateTime lastDay = baseLastDay;
  
  // Ensure focusedDay is at least equal to firstDay
  DateTime focusedDay;
  if (currentDate != null) {
    final normalizedCurrent = _normalizeDate(currentDate);
    focusedDay = normalizedCurrent.isBefore(firstDay) ? firstDay : normalizedCurrent;
  } else {
    focusedDay = firstDay;
  }
  
  DateTime? selectedDateInDialog = currentDate != null ? _normalizeDate(currentDate) : null;
  
  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(16),
          content: SizedBox(
            width: 350,
            height: MediaQuery.of(context).size.height * 0.5,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () {
                            setDialogState(() {
                              final newMonth = DateTime(
                                focusedDay.year,
                                focusedDay.month - 1,
                              );
                              if (newMonth.isAfter(firstDay) ||
                                  newMonth.month == firstDay.month) {
                                focusedDay = newMonth;
                              }
                            });
                          },
                        ),
                        Text(
                          '${_getMonthName(focusedDay.month)} ${focusedDay.year}',
                          style: AppTextStyles.h2(context),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () {
                            setDialogState(() {
                              final newMonth = DateTime(
                                focusedDay.year,
                                focusedDay.month + 1,
                              );
                              if (newMonth.isBefore(lastDay)) {
                                focusedDay = newMonth;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  TableCalendar(
                    firstDay: firstDay,
                    lastDay: lastDay,
                    focusedDay: focusedDay,
                    calendarFormat: CalendarFormat.month,
                    selectedDayPredicate: (day) {
                      final isPickup = _isSameDate(day, _pickupDate);
                      final isReturn = _isSameDate(day, _returnDate);
                      final isDialogSelected = selectedDateInDialog != null && _isSameDate(day, selectedDateInDialog);
                      return isPickup || isReturn || isDialogSelected;
                    },
                    onDaySelected: (selectedDay, newFocusedDay) {
                      final normalizedSelected = _normalizeDate(selectedDay);
                      
                      // Check if the selected date is available
                      if (!_isDateAvailable(normalizedSelected)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('This date is not available for booking'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }
                      
                      // For return date, also check that all dates in the range are available
                      if (!isPickup && _pickupDate != null) {
                        final normalizedPickup = _normalizeDate(_pickupDate!);
                        if (normalizedSelected.isBefore(normalizedPickup)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Return date must be after pickup date'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }
                        
                        // Check if all dates in the range are available
                        bool allDatesAvailable = true;
                        DateTime checkDate = normalizedPickup.add(const Duration(days: 1));
                        while (checkDate.isBefore(normalizedSelected)) {
                          if (!_isDateAvailable(checkDate)) {
                            allDatesAvailable = false;
                            break;
                          }
                          checkDate = checkDate.add(const Duration(days: 1));
                        }
                        
                        if (!allDatesAvailable) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Some dates in the selected range are not available'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }
                      }
                      
                      setDialogState(() {
                        // If selecting return date and clicking the same date again, clear it
                        if (!isPickup && selectedDateInDialog != null && normalizedSelected == selectedDateInDialog) {
                          selectedDateInDialog = null;
                        } else {
                          selectedDateInDialog = normalizedSelected;
                        }
                      });
                    },
                    onPageChanged: (newFocusedDay) {
                      setDialogState(() {
                        focusedDay = newFocusedDay;
                      });
                    },
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, date, focused) {
                        final normalizedDate = _normalizeDate(date);
                        final normalizedPickup = _pickupDate != null ? _normalizeDate(_pickupDate!) : null;
                        final normalizedReturn = _returnDate != null ? _normalizeDate(_returnDate!) : null;
                        
                        // Check if date is available
                        final isAvailable = _isDateAvailable(normalizedDate);
                        
                        // For return date selection dialog, use selectedDateInDialog for preview
                        // For pickup date selection dialog, use selectedDateInDialog for preview
                        DateTime? effectivePickupDate = normalizedPickup;
                        DateTime? effectiveReturnDate = normalizedReturn;
                        
                        if (isPickup && selectedDateInDialog != null) {
                          effectivePickupDate = selectedDateInDialog;
                        } else if (!isPickup && selectedDateInDialog != null) {
                          effectiveReturnDate = selectedDateInDialog;
                        }
                        
                        final isPickupDate = effectivePickupDate != null && normalizedDate == effectivePickupDate;
                        final isReturnDate = effectiveReturnDate != null && normalizedDate == effectiveReturnDate;
                        
                        // Check if date is in the range (excluding start and end dates)
                        final isInRange = effectivePickupDate != null && 
                                         effectiveReturnDate != null &&
                                         normalizedDate.isAfter(effectivePickupDate) &&
                                         normalizedDate.isBefore(effectiveReturnDate);
                        
                        // Check if date is start or end of range
                        final isStartOrEnd = isPickupDate || isReturnDate;
                        
                        return Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: isInRange ? 0 : 2,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            // Start and end dates get accent circle
                            color: isStartOrEnd
                                ? AppColors.accent 
                                : (isInRange
                                    ? AppColors.accent.withOpacity(0.3)
                                    : Colors.transparent),
                            // Circle for start/end, rectangle for in-between
                            shape: isStartOrEnd ? BoxShape.circle : BoxShape.rectangle,
                            borderRadius: isStartOrEnd ? null : BorderRadius.circular(30),
                          ),
                          child: Opacity(
                            opacity: isAvailable ? 1.0 : 0.3,
                            child: Center(
                              child: Text(
                                '${date.day}',
                                style: AppTextStyles.body(context).copyWith(
                                  color: isStartOrEnd
                                      ? Colors.white 
                                      : (isInRange
                                          ? AppColors.accent
                                          : null),
                                  fontWeight: (isStartOrEnd || isInRange)
                                      ? FontWeight.bold 
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                      ),
                      defaultTextStyle: AppTextStyles.body(context),
                      weekendTextStyle: AppTextStyles.body(context),
                      outsideDaysVisible: false,
                    ),
                    headerVisible: false,
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: AppTextStyles.meta(context).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      weekendStyle: AppTextStyles.meta(context).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    availableGestures: AvailableGestures.none,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (selectedDateInDialog != null) {
                          setState(() {
                            if (isPickup) {
                              _pickupDate = selectedDateInDialog;
                              // Reset return date if it's before the new pickup date
                              if (_returnDate != null && _normalizeDate(_returnDate!).isBefore(selectedDateInDialog!)) {
                                _returnDate = null;
                              }
                            } else {
                              _returnDate = selectedDateInDialog;
                            }
                          });
                        }
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      ),
                      child: Text(
                        'Save',
                        style: AppTextStyles.button(context).copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

String _getMonthName(int month) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  return months[month - 1];
}

DateTime _normalizeDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

bool _isSameDate(DateTime? date1, DateTime? date2) {
  if (date1 == null || date2 == null) return false;
  return _normalizeDate(date1) == _normalizeDate(date2);
}

  Widget _buildLocationField() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, color: Colors.grey),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              widget.vehicleData['street_address'],
              style: AppTextStyles.body(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    final rentPerDay = (widget.vehicleData['rent_per_day'] as num?)?.toDouble() ?? 0.0;
    final String priceText;
    
    if (_pickupDate == null || _returnDate == null) {
      // Show base price if dates not selected
      priceText = 'PKR ${rentPerDay.toStringAsFixed(0)}  Pay Now';
    } else {
      // Show calculated total price
      priceText = 'PKR ${_totalPrice.toStringAsFixed(0)}  Pay Now';
    }
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          // Handle payment
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
        ),
        child: Text(
          priceText,
          style: AppTextStyles.button(context).copyWith(fontSize: 18),
        ),
      ),
    );
  }
}