import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD), // Very light clean background
      appBar: AppBar(
        title: const Text(
          "SETTINGS",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: const Color(0xFF20E19F),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header
              const Padding(
                padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
                child: Text(
                  "SYSTEM SETTINGS",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Color(0xFF8B95A5), // Subtle grey matching the screenshot
                  ),
                ),
              ),
              
              // Settings Form/Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSettingsTile(
                      icon: Icons.settings_outlined,
                      title: "General",
                      onTap: () {},
                      isTop: true,
                    ),
                    _buildSettingsTile(
                      icon: Icons.folder_open_outlined,
                      title: "Categories",
                      onTap: () {},
                    ),
                    _buildSettingsTile(
                      icon: Icons.local_offer_outlined,
                      title: "Tags",
                      onTap: () {},
                    ),
                    _buildSettingsTile(
                      icon: Icons.calendar_today_outlined,
                      title: "Holidays",
                      onTap: () {},
                    ),
                    _buildSettingsTile(
                      icon: Icons.notifications_none_outlined,
                      title: "Notification",
                      onTap: () {},
                      isBottom: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isTop = false,
    bool isBottom = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isTop ? 16 : 0),
          topRight: Radius.circular(isTop ? 16 : 0),
          bottomLeft: Radius.circular(isBottom ? 16 : 0),
          bottomRight: Radius.circular(isBottom ? 16 : 0),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            border: isBottom 
                ? null 
                : Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF5E6B81), // Color matching the icon grey from screenshot
                size: 22,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155), // Dark slate text color
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFCBD5E1),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
