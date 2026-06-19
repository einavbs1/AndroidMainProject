import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';
import 'edit_profile_screen.dart';

// Global key is removed to avoid duplicate key assertions on logout/login re-creation.

class MainShellScreen extends StatefulWidget {
  final int initialIndex;
  const MainShellScreen({super.key, this.initialIndex = 0});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late int _currentIndex;
  late final List<Widget> _pages;
  late final MyRouteObserver _routeObserver;
  late final GlobalKey<NavigatorState> _homeNavigatorKey;

  @override
  void initState() {
    super.initState();
    _homeNavigatorKey = GlobalKey<NavigatorState>();
    _currentIndex = widget.initialIndex;
    
    // Create a navigator observer to trigger bottom bar updates on navigation pushes/pops
    _routeObserver = MyRouteObserver(onRouteChanged: () {
      if (mounted) {
        setState(() {}); // Rebuild to re-evaluate active indicators dynamically!
      }
    });

    _pages = [
      HomeTabNavigator(observer: _routeObserver, navigatorKey: _homeNavigatorKey),
      const SettingsScreen(),
      const EditProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (_currentIndex == 0) {
          final navigator = _homeNavigatorKey.currentState;
          if (navigator != null && navigator.canPop()) {
            navigator.pop();
            return;
          }
        }
        final NavigatorState rootNavigator = Navigator.of(context);
        if (rootNavigator.canPop()) {
          rootNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildHomeNavItem(),
                  _buildNavItem(1, Icons.settings_rounded, Icons.settings_outlined, 'Settings'),
                  _buildNavItem(2, Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Specialized Home Item that dynamically reacts to subpage pushes
  Widget _buildHomeNavItem() {
    final bool isAtDashboardRoot = !(_homeNavigatorKey.currentState?.canPop() ?? false);
    final bool isHomeSelected = _currentIndex == 0 && isAtDashboardRoot;
    final themeColor = const Color(0xFF6C63FF);

    return InkWell(
      onTap: () {
        if (_currentIndex == 0) {
          // If already on Home tab but on a subpage, clicking Home pops back to Dashboard!
          if (!isAtDashboardRoot) {
            _homeNavigatorKey.currentState?.popUntil((route) => route.isFirst);
            setState(() {});
          }
        } else {
          // Switch to Home tab
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isHomeSelected ? themeColor.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isHomeSelected ? Icons.home_rounded : Icons.home_outlined,
              color: isHomeSelected ? themeColor : Colors.grey[500],
              size: 24,
            ),
            if (isHomeSelected) ...[
              const SizedBox(width: 8),
              Text(
                'Home',
                style: TextStyle(
                  color: themeColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _currentIndex == index;
    final themeColor = const Color(0xFF6C63FF);

    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? themeColor.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? themeColor : Colors.grey[500],
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: themeColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class HomeTabNavigator extends StatelessWidget {
  final NavigatorObserver observer;
  final GlobalKey<NavigatorState> navigatorKey;
  const HomeTabNavigator({
    super.key,
    required this.observer,
    required this.navigatorKey,
  });

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      initialRoute: '/',
      observers: [observer],
      onGenerateRoute: (RouteSettings settings) {
        Widget builder;
        switch (settings.name) {
          case '/':
            builder = const DashboardScreen();
            break;
          default:
            builder = const DashboardScreen();
        }
        return MaterialPageRoute(
          builder: (context) => builder,
          settings: settings,
        );
      },
    );
  }
}

// Custom route observer to trigger bottom bar updates on navigation actions safely after the build frame
class MyRouteObserver extends NavigatorObserver {
  final VoidCallback onRouteChanged;
  MyRouteObserver({required this.onRouteChanged});

  void _notify() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onRouteChanged();
    });
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    _notify();
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    _notify();
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    super.didRemove(route, previousRoute);
    _notify();
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _notify();
  }
}
