import 'package:flutter/material.dart';

class NotificationsRemindersScreen extends StatefulWidget {
  const NotificationsRemindersScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsRemindersScreen> createState() => _NotificationsRemindersScreenState();
}

class _NotificationsRemindersScreenState extends State<NotificationsRemindersScreen> with SingleTickerProviderStateMixin {
  // Notification Settings
  bool _informaticsNotificationsEnabled = true;
  bool _emailNotificationsEnabled = false;

  // Reminder Settings
  bool _dailyReminderEnabled = true;
  bool _emailRemindersEnabled = false;

  // Task Reminder
  final _reminderTimeController = TextEditingController(text: '09:00');
  bool _weeklyOnlyEnabled = false;
  Map<String, bool> _selectedDays = {
    'Mon': true,
    'Tue': true,
    'Wed': true,
    'Thu': true,
    'Fri': true,
    'Sat': false,
    'Sun': false,
  };

  // Notification Channels
  late TabController _tabController;

  final List<String> _notificationTypes = [
    'New Task',
    'Task Edit',
    'Task Assigned',
    'Task In Progress',
    'Task Complete',
    'Task No Start',
  ];

  Map<String, Map<String, bool>> _notificationChannels = {
    'New Task': {'Admin': true, 'Manager': true, 'Member': true},
    'Task Edit': {'Admin': true, 'Manager': true, 'Member': false},
    'Task Assigned': {'Admin': true, 'Manager': true, 'Member': true},
    'Task In Progress': {'Admin': true, 'Manager': false, 'Member': true},
    'Task Complete': {'Admin': true, 'Manager': true, 'Member': true},
    'Task No Start': {'Admin': true, 'Manager': true, 'Member': false},
  };

  Map<String, Map<String, String>> _notificationFrequency = {
    'New Task': {'Admin': 'Real-time', 'Manager': 'Real-time', 'Member': 'Daily'},
    'Task Edit': {'Admin': 'Real-time', 'Manager': 'Hourly', 'Member': 'Daily'},
    'Task Assigned': {'Admin': 'Real-time', 'Manager': 'Real-time', 'Member': 'Real-time'},
    'Task In Progress': {'Admin': 'Real-time', 'Manager': 'Daily', 'Member': 'Weekly'},
    'Task Complete': {'Admin': 'Real-time', 'Manager': 'Real-time', 'Member': 'Daily'},
    'Task No Start': {'Admin': 'Daily', 'Manager': 'Daily', 'Member': 'Weekly'},
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text(
          "NOTIFICATIONS & REMINDERS",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2),
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
              // Notification Settings
              const _SectionHeader(title: 'Notification Settings', subtitle: 'Manage how you receive notifications'),
              _buildNotificationSettingsCard(),
              const SizedBox(height: 28),

              // Reminder Settings
              const _SectionHeader(title: 'Reminder Settings', subtitle: 'Manage your reminders'),
              _buildReminderSettingsCard(),
              const SizedBox(height: 28),

              // Task Reminder
              const _SectionHeader(title: 'Task Reminder', subtitle: 'Set up task reminders'),
              _buildTaskReminderCard(),
              const SizedBox(height: 28),

              // Notification Channels
              const _SectionHeader(title: 'Notification Channels', subtitle: 'Select platforms where you receive notifications'),
              _buildNotificationChannelsTable(),
              const SizedBox(height: 28),

              // Notification Frequency
              const _SectionHeader(title: 'Notification Frequency', subtitle: 'Choose how often you receive notifications'),
              _buildNotificationFrequencyTable(),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notification settings saved successfully'),
                        backgroundColor: Color(0xFF20E19F),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF20E19F),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Save Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildToggleTileWithTabs('Informatics Notifications', _informaticsNotificationsEnabled, (value) {
            setState(() => _informaticsNotificationsEnabled = value);
          }, ['Timestamps', 'In Pro Details']),
          const SizedBox(height: 16),
          _buildToggleTile('Email Notifications', _emailNotificationsEnabled, (value) {
            setState(() => _emailNotificationsEnabled = value);
          }),
        ],
      ),
    );
  }

  Widget _buildReminderSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildToggleTile('Daily Reminder-Every Knows when time', _dailyReminderEnabled, (value) {
            setState(() => _dailyReminderEnabled = value);
          }),
          const SizedBox(height: 16),
          _buildToggleTile('Email Reminders', _emailRemindersEnabled, (value) {
            setState(() => _emailRemindersEnabled = value);
          }),
        ],
      ),
    );
  }

  Widget _buildTaskReminderCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Time Input
          TextFormField(
            controller: _reminderTimeController,
            decoration: InputDecoration(
              labelText: 'Reminder Time',
              hintText: 'HH:MM',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              floatingLabelStyle: const TextStyle(color: Color(0xFF20E19F)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF20E19F), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Weekly Only Checkbox
          _buildCheckboxTile('Weekly Only', _weeklyOnlyEnabled, (value) {
            setState(() => _weeklyOnlyEnabled = value ?? false);
          }),
          const SizedBox(height: 16),

          // Days Selection
          const Text('Select days:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedDays.keys.map((day) {
              return FilterChip(
                label: Text(day),
                selected: _selectedDays[day] ?? false,
                onSelected: (selected) {
                  setState(() => _selectedDays[day] = selected);
                },
                selectedColor: const Color(0xFF20E19F),
                labelStyle: TextStyle(
                  color: _selectedDays[day] ?? false ? Colors.white : Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: Colors.grey.shade100,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationChannelsTable() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
        children: [
          // Header
          Container(
            color: const Color(0xFF20E19F),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text('Type', style: _tableHeaderStyle())),
                Expanded(child: Text('Admin', style: _tableHeaderStyle())),
                Expanded(child: Text('Manager', style: _tableHeaderStyle())),
                Expanded(child: Text('Member', style: _tableHeaderStyle())),
              ],
            ),
          ),
          // Rows
          ..._notificationTypes.asMap().entries.map((entry) {
            int index = entry.key;
            String type = entry.value;
            bool isLast = index == _notificationTypes.length - 1;
            return Container(
              decoration: BoxDecoration(
                border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text(type, style: _tableRowStyle())),
                  Expanded(child: _buildTableCheckbox(_notificationChannels[type]?['Admin'] ?? false, (value) {
                    setState(() => _notificationChannels[type]!['Admin'] = value ?? false);
                  })),
                  Expanded(child: _buildTableCheckbox(_notificationChannels[type]?['Manager'] ?? false, (value) {
                    setState(() => _notificationChannels[type]!['Manager'] = value ?? false);
                  })),
                  Expanded(child: _buildTableCheckbox(_notificationChannels[type]?['Member'] ?? false, (value) {
                    setState(() => _notificationChannels[type]!['Member'] = value ?? false);
                  })),
                ],
              ),
            );
          }).toList(),
        ],
      ),
      ),
    );
  }

  Widget _buildNotificationFrequencyTable() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
        children: [
          // Header
          Container(
            color: const Color(0xFF20E19F),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text('Type', style: _tableHeaderStyle())),
                Expanded(child: Text('Admin', style: _tableHeaderStyle())),
                Expanded(child: Text('Manager', style: _tableHeaderStyle())),
                Expanded(child: Text('Member', style: _tableHeaderStyle())),
              ],
            ),
          ),
          // Rows
          ..._notificationTypes.asMap().entries.map((entry) {
            int index = entry.key;
            String type = entry.value;
            bool isLast = index == _notificationTypes.length - 1;
            return Container(
              decoration: BoxDecoration(
                border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text(type, style: _tableRowStyle())),
                  Expanded(child: _buildFrequencyDropdown(_notificationFrequency[type]?['Admin'] ?? 'Daily', (value) {
                    setState(() => _notificationFrequency[type]!['Admin'] = value ?? 'Daily');
                  })),
                  Expanded(child: _buildFrequencyDropdown(_notificationFrequency[type]?['Manager'] ?? 'Daily', (value) {
                    setState(() => _notificationFrequency[type]!['Manager'] = value ?? 'Daily');
                  })),
                  Expanded(child: _buildFrequencyDropdown(_notificationFrequency[type]?['Member'] ?? 'Daily', (value) {
                    setState(() => _notificationFrequency[type]!['Member'] = value ?? 'Daily');
                  })),
                ],
              ),
            );
          }).toList(),
        ],
      ),
      ),
    );
  }

  Widget _buildToggleTile(String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
        Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFF20E19F)),
      ],
    );
  }

  Widget _buildToggleTileWithTabs(String label, bool value, Function(bool) onChanged, List<String> tabs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
            Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFF20E19F)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: tabs.asMap().entries.map((entry) {
            int index = entry.key;
            String tab = entry.value;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index == tabs.length - 1 ? 0 : 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(tab, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCheckboxTile(String label, bool value, Function(bool?) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF20E19F),
        ),
      ],
    );
  }

  Widget _buildTableCheckbox(bool value, Function(bool?) onChanged) {
    return Checkbox(
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF20E19F),
    );
  }

  Widget _buildFrequencyDropdown(String value, Function(String?) onChanged) {
    final frequencies = ['Real-time', 'Hourly', 'Daily', 'Weekly'];
    return DropdownButton<String>(
      value: value,
      items: frequencies.map((freq) {
        return DropdownMenuItem(value: freq, child: Text(freq, style: const TextStyle(fontSize: 12)));
      }).toList(),
      onChanged: onChanged,
      underline: const SizedBox(),
      isDense: true,
    );
  }

  TextStyle _tableHeaderStyle() {
    return const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12);
  }

  TextStyle _tableRowStyle() {
    return const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155));
  }

  @override
  void dispose() {
    _reminderTimeController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Color(0xFF8B95A5), fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }
}
