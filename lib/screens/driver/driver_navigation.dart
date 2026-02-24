import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../screens/driver/driver_home_screen.dart';
import '../../screens/driver/driver_trips_screen.dart';
import '../../screens/driver/driver_profile_screen.dart';
import '../../screens/driver/driver_inbox_screen.dart';

class DriverNavigation extends StatefulWidget {
  const DriverNavigation({super.key});

  @override
  State<DriverNavigation> createState() => _DriverNavigationState();
}

class _DriverNavigationState extends State<DriverNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DriverHomeScreen(),
    const DriverTripsScreen(),
    const DriverInboxScreen(),
    const DriverProfileScreen(),
  ];

  final List<NavigationItem> _navigationItems = [
    NavigationItem(Icons.home_outlined, Icons.home, 'Home'),
    NavigationItem(
      Icons.directions_car_outlined,
      Icons.directions_car,
      'Trips',
    ),
    NavigationItem(Icons.inbox_outlined, Icons.inbox, 'Inbox'),
    NavigationItem(Icons.person_outline, Icons.person, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Opacity(
        opacity: 0.95,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(
                  _navigationItems.length,
                  (index) => Expanded(
                    child: _buildNavItem(
                      _navigationItems[index].outlinedIcon,
                      _navigationItems[index].filledIcon,
                      _navigationItems[index].label,
                      _currentIndex == index,
                      index,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData outlinedIcon,
    IconData filledIcon,
    String label,
    bool isSelected,
    int index,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? filledIcon : outlinedIcon,
                color: isSelected ? Color(0xFF09111C) : AppColors.secondaryText,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color:
                      isSelected
                          ? AppColors.primaryText
                          : AppColors.secondaryText,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData outlinedIcon;
  final IconData filledIcon;
  final String label;

  NavigationItem(this.outlinedIcon, this.filledIcon, this.label);
}
