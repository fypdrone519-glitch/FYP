import 'package:car_listing_app/screens/host/edit_car_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/car.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';
import 'package:table_calendar/table_calendar.dart';

class HostCarCard extends StatefulWidget {
  final Function(Map<String, dynamic>)? onDataUpdated;
  final Car car;
  final VoidCallback? onTap;
  final Map<String, dynamic> vehicleData; 
  final VoidCallback? onEdit;

  const HostCarCard({super.key, required this.car, this.onTap,required this.vehicleData,this.onEdit,this.onDataUpdated});

  @override
  State<HostCarCard> createState() => _HostCarCardState();
}

class _HostCarCardState extends State<HostCarCard> {
  @override
  void initState() {
    super.initState();
    _loadAvailabilityDates();
  }
  //for the calendar
  Set<DateTime> _selectedDates = {};
  DateTime _focusedDay = DateTime.now();
  Future<void> _loadAvailabilityDates() async {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(widget.car.id)
            .get();
        
        if (doc.exists && doc.data()?['availability'] != null) {
          final List<dynamic> dates = doc.data()!['availability'];
          setState(() {
            _selectedDates = dates
                .map((dateStr) => DateTime.parse(dateStr))
                .toSet();
          });
        }
      } catch (e) {
        print('Error loading dates: $e');
      }
    }
     // Method to show calendar dialog
    Future<void> _showAvailabilityCalendar(BuildContext context) async {
    DateTime focusedDay = DateTime.now(); // Local variable instead of state
    final DateTime firstDay = DateTime.now();
    final DateTime lastDay = DateTime.now().add(const Duration(days: 365));
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: const EdgeInsets.all(16),
            content: SizedBox(
              width: 350,
              height: 450,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Calendar Header
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () {
                              setState(() {
                                final newMonth = DateTime(
                                  focusedDay.year,
                                  focusedDay.month - 1,
                                );
                                // Only update if within valid range
                                if (newMonth.isAfter(firstDay) || 
                                    isSameDay(newMonth, firstDay)) {
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
                              setState(() {
                                final newMonth = DateTime(
                                  focusedDay.year,
                                  focusedDay.month + 1,
                                );
                                // Only update if within valid range
                                if (newMonth.isBefore(lastDay)) {
                                  focusedDay = newMonth;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    // Calendar
                    TableCalendar(
                      firstDay: firstDay,
                      lastDay: lastDay,
                      focusedDay: focusedDay,
                      calendarFormat: CalendarFormat.month,
                      selectedDayPredicate: (day) {
                        return _selectedDates.any((selectedDay) =>
                            isSameDay(selectedDay, day));
                      },
                      onDaySelected: (selectedDay, newFocusedDay) {
                        setState(() {
                          if (_selectedDates.any((d) => isSameDay(d, selectedDay))) {
                            _selectedDates.removeWhere((d) => isSameDay(d, selectedDay));
                          } else {
                            _selectedDates.add(selectedDay);
                          }
                          focusedDay = newFocusedDay;
                        });
                      },
                      onPageChanged: (newFocusedDay) {
                        setState(() {
                          focusedDay = newFocusedDay;
                        });
                      },
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                        selectedTextStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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
                      availableGestures: AvailableGestures.none, // Disable swipe gestures
                    ),
                    const SizedBox(height: 16),
                    // Confirm Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _saveAvailabilityDates(_selectedDates, context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Confirm',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
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

  // Helper method to get month name
  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  // Method to save availability dates to database
  Future<void> _saveAvailabilityDates(Set<DateTime> dates, BuildContext context) async {
    try {
      List<String> dateStrings = dates
          .map((date) => date.toIso8601String().split('T')[0])
          .toList();
      
      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.car.id)
          .update({'availability': dateStrings});
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Availability dates updated!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Dismissible(
        key: Key(widget.car.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.all(24),
              title: Center(
                child: Text(
                  'Confirm Delete',
                  style: AppTextStyles.h2(context),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Are you sure you want to delete this vehicle?',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(context).copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        onDismissed: (direction) async {
          await FirebaseFirestore.instance
              .collection('vehicles')
              .doc(widget.car.id)
              .delete();
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Vehicle deleted')),
            );
          }
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
          child: const Icon(Icons.delete, color: Colors.white, size: 32),
        ),
        child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Car Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.cardRadius),
                topRight: Radius.circular(AppSpacing.cardRadius),
              ),
              child: Stack(
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    color: AppColors.hostBackground,
                    child:
                        widget.car.imageUrl.isNotEmpty
                            ? Image.network(
                              widget.car.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.car_rental,
                                    size: 60,
                                    color: AppColors.secondaryText,
                                  ),
                                );
                              },
                            )
                            : const Center(
                              child: Icon(
                                Icons.car_rental,
                                size: 60,
                                color: AppColors.secondaryText,
                              ),
                            ),
                  ),
                  // Badges
                  Positioned(
                    top: AppSpacing.sm,
                    left: AppSpacing.sm,
                    child: Wrap(
                      spacing: AppSpacing.xs,
                      children:
                          widget.car.badges.map((badge) {
                            Color badgeColor = AppColors.accent;
                            if (badge == 'Verified') {
                              badgeColor = Colors.blue;
                            } else if (badge == 'Instant') {
                              badgeColor = Colors.orange;
                            }
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: badgeColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                badge,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            // Car Details
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Model Name and calander button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.car.fullName, style: AppTextStyles.carModel(context)),
                      
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: const Icon(Icons.calendar_month, color: AppColors.background),
                          onPressed: () => _showAvailabilityCalendar(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // Features
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children:
                        widget.car.features.take(3).map((feature) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withAlpha(10),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.accent.withAlpha(50)),
                            ),
                            child: Text(
                              feature,
                              style: AppTextStyles.meta(context),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Rating and Trips
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: AppColors.ratingStar,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.car.rating.toStringAsFixed(1),
                        style: AppTextStyles.meta(context),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '(${widget.car.trips} trips)',
                        style: AppTextStyles.meta(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Price and CTA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rs ${widget.car.pricePerDay.toStringAsFixed(0)}/day',
                            style: AppTextStyles.price(context),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () async {
                            final result = await showModalBottomSheet<bool>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => EditCarScreen(
                                vehicleId: widget.car.id, 
                                vehicleData: widget.vehicleData 
                              ),
                            );
                            
                            if (result == true && mounted) {
                              final doc = await FirebaseFirestore.instance
                                  .collection('vehicles')
                                  .doc(widget.car.id)
                                  .get();
                              
                              if (doc.exists && widget.onDataUpdated != null) {
                                widget.onDataUpdated!(doc.data()!);
                              }
                            }
                          },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(
                            AppSpacing.minTouchTarget,
                            AppSpacing.minTouchTarget,
                          ),
                        ),
                        child: Text(
                          'Edit details',
                          style: AppTextStyles.button(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      )
    );
  }
}