import 'package:car_listing_app/screens/host/host_home_screen.dart';
import 'package:car_listing_app/screens/host/add_car.dart';
import 'package:car_listing_app/screens/host/host_profile_screen.dart';
import 'package:car_listing_app/screens/inbox_screen.dart';
import 'package:car_listing_app/screens/trips_screen.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class HostNavigation extends StatefulWidget {
  const HostNavigation({super.key});

  @override
  State<HostNavigation> createState() => _HostNavigationState();
}

class _HostNavigationState extends State<HostNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HostHomeScreen(),
    TripsScreen(viewAsHost: true),
    const AddCarScreen(),
    const InboxScreen(),
    const HostProfileScreen(),
  ];

  final List<NavigationItem> _navigationItems = [
    NavigationItem(Icons.home_outlined, Icons.home, 'Home'),
    NavigationItem(Icons.directions_car_outlined,Icons.directions_car, 'Trips'),
    NavigationItem(Icons.add_box_outlined, Icons.add_box_rounded, 'Add Car'),
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
                color: Colors.black.withValues(alpha: 0.05),
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
                  color: isSelected ? AppColors.background : AppColors.secondaryText,
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

// Placeholder screens
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Insights Screen - Coming Soon')),
    );
  }
}

