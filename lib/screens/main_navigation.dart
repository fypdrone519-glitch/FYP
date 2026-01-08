import 'package:car_listing_app/screens/home_screen.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import 'trips_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0; // Tracks the screen index (0-3)
  int _selectedNavIndex = 0; // Tracks the selected nav bar item (0-4)

  final List<Widget> _screens = [
    const HomeScreenContent(), // Index 0: Home
    const TripsScreen(),        // Index 1: Trips (Map pushes a new route, so not in this list)
    const InboxScreen(),        // Index 2: Inbox
    const ProfileScreen(),      // Index 3: Profile
  ];

  final List<NavigationItem> _navigationItems = [
    NavigationItem(Icons.home_outlined, Icons.home, 'Home'),
    NavigationItem(Icons.pin_drop_outlined, Icons.pin_drop, 'Map'),
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
        opacity: 0.95, // Adjust this value between 0.0 (fully transparent) and 1.0 (fully opaque)
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
                      (_selectedNavIndex == index),
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
          if(label == 'Map'){
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const MapsScreen(),
              ),
            );
            return;
          }
          else{
            // Adjust index for screens list (Map is not in the list)
            int screenIndex = index;
            if (index > 1) screenIndex = index - 1; // Trips, Inbox, Profile shift down by 1
            
            setState(() {
              _currentIndex = screenIndex;
              _selectedNavIndex = index; // Store the actual nav bar index
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? filledIcon : outlinedIcon,
                color: isSelected ? AppColors.accent : AppColors.secondaryText,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color:
                      isSelected ? AppColors.accent : AppColors.secondaryText,
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

// Placeholder screens for other tabs
class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Inbox Screen - Coming Soon')),
    );
  }
}

