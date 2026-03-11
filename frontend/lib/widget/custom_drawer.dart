import 'dart:convert' as dart_convert;
import 'package:d_table_delegate_system/provider/auth_provider.dart';
import 'package:d_table_delegate_system/provider/theme_provider.dart';
import 'package:d_table_delegate_system/screen/auth/login/login_screen.dart';
import 'package:d_table_delegate_system/screen/home/delegate_task_screen.dart';
import 'package:d_table_delegate_system/screen/home/group_task.dart';
import 'package:d_table_delegate_system/screen/home/all_tasks_screen.dart';
import 'package:d_table_delegate_system/screen/home/my_task.dart';
import 'package:d_table_delegate_system/screen/home/my_team.dart';
import 'package:d_table_delegate_system/screen/groups/my_groups.dart';
import 'package:d_table_delegate_system/screen/support/support_screen.dart';
import 'package:d_table_delegate_system/screen/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MyCustomDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final userName = user != null
        ? "${user.firstName} ${user.lastName}"
        : "Loading User...";
    final userEmail = user != null ? user.workEmail : "loading@erp.com";
    final initial = user != null && user.firstName.isNotEmpty
        ? user.firstName[0].toUpperCase()
        : "U";

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF20E19F)),
            accountName: Text(
              userName,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(userEmail),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage:
                  (user != null &&
                      user.profilePhotoUrl != null &&
                      user.profilePhotoUrl!.isNotEmpty)
                  ? MemoryImage(
                      dart_convert.base64Decode(
                        user.profilePhotoUrl!.split(',').last,
                      ),
                    )
                  : null,
              child:
                  (user == null ||
                      user.profilePhotoUrl == null ||
                      user.profilePhotoUrl!.isEmpty)
                  ? Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF20E19F),
                      ),
                    )
                  : null,
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 10),
              children: [
                _drawerTile(
                  context,
                  Icons.dashboard_outlined,
                  "Dashboard",
                  false,
                  () {
                    Navigator.pop(context); // Dashboard already home par hai
                  },
                ),
                _drawerTile(context, Icons.task_alt, "My Tasks", false, () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyTaskScreen(title: 'My Task'),
                    ),
                  );
                }),
                _drawerTile(
                  context,
                  Icons.format_list_bulleted_rounded,
                  "All Tasks",
                  false,
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const AllTasksScreen(title: 'All Tasks'),
                      ),
                    );
                  },
                ),
                _drawerTile(
                  context,
                  Icons.assignment_ind_outlined,
                  "Delegate Task",
                  false,
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DelegateTasksScreen(),
                      ),
                    );
                  },
                ),
                _drawerTile(context, Icons.people_outline, "Groups", false, () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyGroupsScreen(),
                    ),
                  );
                }),
                _drawerTile(
                  context,
                  Icons.groups_3_outlined,
                  "My Team",
                  false,
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MyTeamScreen()),
                    );
                  },
                ),
                _drawerTile(
                  context,
                  Icons.settings_outlined,
                  "Settings",
                  false,
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
                _drawerTile(
                  context,
                  Icons.support_agent_outlined,
                  "Support",
                  false,
                  () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SupportScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Divider(height: 1),
          _drawerTile(context, Icons.logout, "Logout", false, () async {
            // 1. AuthProvider ka access lo
            final auth = Provider.of<AuthProvider>(context, listen: false);

            // 2. Logout function call karo (Jo aapne dikhaya hai)
            await auth.logout();

            // 3. User ko Login Screen par dhakka de do aur purani memory clear kar do
            if (context.mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ), // Apni LoginScreen ka sahi naam likhein
                (route) =>
                    false, // Ye line piche jane ka rasta band kar deti hai
              );
            }
          }, color: Colors.redAccent),
          SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _drawerTile(
    BuildContext context,
    IconData icon,
    String title,
    bool isSelected,
    VoidCallback onTap, {
    Color? color,
  }) {
    final appColors = Theme.of(context).extension<AppColors>()!;
    return Container(
      margin: EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? ThemeProvider.primaryGreen.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected
              ? ThemeProvider.primaryGreen
              : (color ?? appColors.textMuted),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? appColors.textPrimary
                : (color ?? appColors.textSecondary),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
