import 'package:d_table_delegate_system/provider/auth_provider.dart';
import 'package:d_table_delegate_system/provider/theme_provider.dart';
import 'package:d_table_delegate_system/screen/home/delegate_task_screen.dart';
import 'package:d_table_delegate_system/screen/home/home_screen.dart';
import 'package:d_table_delegate_system/screen/home/my_task.dart';
import 'package:d_table_delegate_system/screen/profile/profile_settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  _MainWrapperState createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColors>()!;
    final primary = ThemeProvider.primaryGreen;
    final isDark = theme.brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);
    final bool isMobile = MediaQuery.of(context).size.width < 800;

    // ── Pages ──────────────────────────────────────────────────────
    final List<Widget> pages = [
      // 0: Dashboard — sare tasks ka overview (admin/manager/user sab dekhte hain)
      const DynamicDashboard(),

      // 1: My Tasks — MUJHE assign kiye gaye tasks
      const MyTaskScreen(title: 'My Tasks'),

      // 2: Delegated Tasks — MAINE assign kiye gaye tasks
      const DelegateTasksScreen(),

      // 3: Profile
      const ProfileSettingsScreen(),
    ];

    // ── Nav items ─────────────────────────────────────────────────
    const navDestinations = [
      NavigationRailDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard_rounded),
        label: Text('Dashboard'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.task_alt_outlined),
        selectedIcon: Icon(Icons.task_alt_rounded),
        label: Text('My Tasks'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.send_outlined),
        selectedIcon: Icon(Icons.send_rounded),
        label: Text('Delegated'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.person_outline_rounded),
        selectedIcon: Icon(Icons.person_rounded),
        label: Text('Profile'),
      ),
    ];

    const bottomItems = [
      BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_outlined),
        activeIcon: Icon(Icons.dashboard_rounded),
        label: 'Dashboard',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.task_alt_outlined),
        activeIcon: Icon(Icons.task_alt_rounded),
        label: 'My Tasks',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.send_outlined),
        activeIcon: Icon(Icons.send_rounded),
        label: 'Delegated',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline_rounded),
        activeIcon: Icon(Icons.person_rounded),
        label: 'Profile',
      ),
    ];

    return Scaffold(
      body: Row(
        children: [
          // ── Side Rail (tablet/desktop) ─────────────────────────
          if (!isMobile)
            NavigationRail(
              selectedIndex: _currentIndex,
              backgroundColor:
                  isDark ? appColors.toolbarBackground : primary,
              selectedIconTheme: IconThemeData(
                color: isDark ? primary : Colors.black,
              ),
              unselectedIconTheme: IconThemeData(
                color: isDark ? Colors.white54 : Colors.black54,
              ),
              selectedLabelTextStyle: TextStyle(
                color: isDark ? primary : Colors.black,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelTextStyle: TextStyle(
                color: isDark ? Colors.white54 : Colors.black54,
              ),
              labelType: NavigationRailLabelType.all,
              onDestinationSelected: (int index) {
                setState(() => _currentIndex = index);
              },
              destinations: navDestinations,
            ),

          if (!isMobile)
            VerticalDivider(
              thickness: 1,
              width: 1,
              color: appColors.divider,
            ),

          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: pages,
            ),
          ),
        ],
      ),

      // ── Bottom Nav (mobile) ────────────────────────────────────
      bottomNavigationBar: isMobile
          ? BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor:
                  isDark ? appColors.toolbarBackground : primary,
              selectedItemColor: isDark ? primary : Colors.black,
              unselectedItemColor:
                  isDark ? Colors.white54 : Colors.black54,
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              items: bottomItems,
            )
          : null,
    );
  }
}
