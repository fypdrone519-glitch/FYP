import 'package:car_listing_app/screens/home_screen.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'home_screen.dart';
import 'map_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreenContent(), // We'll extract the content from HomeScreen
    const MapScreenContent(), // We'll extract the content from MapScreen
    const TripsScreen(), // Placeholder for trips
    const InboxScreen(), // Placeholder for inbox
    const ProfileScreen(), // Placeholder for profile
  ];

final List<NavigationItem> _navigationItems = [
  NavigationItem(Icons.home_outlined, Icons.home, 'Home'),
  NavigationItem(Icons.pin_drop_outlined, Icons.pin_drop, 'Map'),
  NavigationItem(Icons.directions_car_outlined, Icons.directions_car, 'Trips'),
  NavigationItem(Icons.inbox_outlined, Icons.inbox, 'Inbox'),
  NavigationItem(Icons.person_outline, Icons.person, 'Profile'),
];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
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
                  (_currentIndex == index),
                  index,
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
              color: isSelected
                  ? AppColors.accent
                  : AppColors.secondaryText,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? AppColors.accent
                    : AppColors.secondaryText,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
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

// Placeholder screens for other tabs
class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Trips Screen - Coming Soon')),
    );
  }
}

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Inbox Screen - Coming Soon')),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Profile Screen - Coming Soon')),
    );
  }
}
