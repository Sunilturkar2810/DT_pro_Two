import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/notification_provider.dart';

class NotificationsRemindersScreen extends StatefulWidget {
  const NotificationsRemindersScreen({super.key});

  @override
  State<NotificationsRemindersScreen> createState() => _NotificationsRemindersScreenState();
}

class _NotificationsRemindersScreenState extends State<NotificationsRemindersScreen> with SingleTickerProviderStateMixin {
  late TabController _mainTabController;
  int _activeRoleTab = 0; // 0: Admin, 1: Manager, 2: Member

  // Template State
  String _activeEventTemplate = 'newTask';
  String _activeChannel = 'email'; // 'email' or 'whatsapp'
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  bool _isTemplateActive = true;

  final List<String> _roles = ['Admin', 'Manager', 'Member'];
  final Map<String, String> _eventLabels = {
    'newTask': 'New Task',
    'taskEdit': 'Task Edited',
    'taskComment': 'Task Comment',
    'taskInProgress': 'Task In-Progress',
    'taskComplete': 'Task Complete',
    'taskReOpen': 'Task Re-Open',
    'dailyPendingReminders': 'Daily Pending Reminders',
    'custom': 'Custom',
    'inLoopNewTask': 'In Loop: New Task',
    'inLoopTaskEdit': 'In Loop: Task Edited',
    'inLoopTaskComment': 'In Loop: Task Comment',
    'inLoopTaskInProgress': 'In Loop: Task In-Progress',
    'inLoopTaskComplete': 'In Loop: Task Complete',
    'inLoopTaskReOpen': 'In Loop: Task Re-Open',
  };

  final List<String> _templateVariables = [
    '{taskTitle}',
    '{taskDescription}',
    '{priority}',
    '{category}',
    '{dueDate}',
    '{assignerName}',
    '{userName}',
  ];

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _mainTabController.addListener(() {
      setState(() {});
      if (_mainTabController.index == 1 && _mainTabController.indexIsChanging) {
        _fetchCurrentTemplate();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotificationSettings();
    });
  }

  void _fetchCurrentTemplate() async {
    final provider = context.read<NotificationProvider>();
    await provider.fetchTemplate(_activeEventTemplate, _activeChannel);
    if (provider.activeTemplate != null) {
      _subjectController.text = provider.activeTemplate!['subject'] ?? '';
      _bodyController.text = provider.activeTemplate!['body'] ?? '';
      setState(() {
        _isTemplateActive = provider.activeTemplate!['isActive'] ?? true;
      });
    } else {
      _subjectController.clear();
      _bodyController.clear();
      setState(() {
        _isTemplateActive = true;
      });
    }
  }
  
  void _saveCurrentTemplate() async {
    final provider = context.read<NotificationProvider>();
    final success = await provider.saveTemplate({
      'eventName': _activeEventTemplate,
      'channel': _activeChannel,
      'subject': _subjectController.text.trim(),
      'body': _bodyController.text.trim(),
      'isActive': _isTemplateActive,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Template saved successfully' : 'Failed to save template'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _insertVariable(String variable) {
    int cursorPosition = _bodyController.selection.base.offset;
    if (cursorPosition == -1) cursorPosition = _bodyController.text.length;

    String currentText = _bodyController.text;
    String newText = currentText.substring(0, cursorPosition) + variable + currentText.substring(cursorPosition);
    
    _bodyController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursorPosition + variable.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: const Text("NOTIFICATIONS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2)),
        backgroundColor: const Color(0xFF20E19F),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _mainTabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: "PREFERENCES"),
            Tab(text: "TEMPLATES"),
          ],
        ),
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && _mainTabController.index == 0) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return TabBarView(
            controller: _mainTabController,
            physics: const NeverScrollableScrollPhysics(), // complex nested scrolling
            children: [
              _buildPreferencesTab(provider),
              _buildTemplatesTab(provider),
            ],
          );
        },
      ),
      bottomNavigationBar: _mainTabController.index == 0 ? _buildBottomSaveBar() : null,
    );
  }

  // ==========================================
  // TEMPLATES TAB LOGIC
  // ==========================================
  Widget _buildTemplatesTab(NotificationProvider provider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Rail: Events
        Container(
          width: 160,
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("EVENT TYPES", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 11, letterSpacing: 1.1)),
              ),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _eventLabels.length,
                  itemBuilder: (context, index) {
                    final entry = _eventLabels.entries.elementAt(index);
                    final isSelected = _activeEventTemplate == entry.key;
                    
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _activeEventTemplate = entry.key;
                        });
                        _fetchCurrentTemplate();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                entry.value,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            if (isSelected) const Icon(Icons.check, color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        
        // Right Side: Editor
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Channel Tabs
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: Colors.white,
                child: Row(
                  children: [
                    _buildChannelTab('email', 'Email', Icons.mail_outline),
                    const SizedBox(width: 12),
                    _buildChannelTab('whatsapp', 'WhatsApp', Icons.smartphone_outlined),
                  ],
                ),
              ),
              const Divider(height: 1),
              
              // Editor Space
              Expanded(
                child: provider.isTemplateLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildTemplateEditor(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChannelTab(String key, String label, IconData icon) {
    final isSelected = _activeChannel == key;
    return InkWell(
      onTap: () {
        setState(() {
          _activeChannel = key;
        });
        _fetchCurrentTemplate();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFFF8F9FD),
          border: Border.all(color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateEditor() {
    String eventTitle = _eventLabels[_activeEventTemplate]!.toUpperCase();
    String channelTitle = _activeChannel.toUpperCase();
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("$eventTitle $channelTitle TEMPLATE", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const Text("Design how this notification will look", style: TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
              Row(
                children: [
                  const Text("ACTIVE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  const SizedBox(width: 8),
                  Switch.adaptive(
                    value: _isTemplateActive,
                    activeColor: const Color(0xFF10B981),
                    onChanged: (val) {
                      setState(() {
                        _isTemplateActive = val;
                      });
                    },
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _saveCurrentTemplate,
                    icon: const Icon(Icons.save, size: 16, color: Colors.white),
                    label: const Text('Save Template', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Main Editor vs Variables Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Editor
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_activeChannel == 'email') ...[
                      const Text("EMAIL SUBJECT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey, letterSpacing: 1.1)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _subjectController,
                        decoration: InputDecoration(
                          hintText: "Enter email subject...",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    Text("${_activeChannel == 'email' ? 'EMAIL' : 'WHATSAPP'} BODY", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey, letterSpacing: 1.1)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _bodyController,
                      maxLines: 15,
                      decoration: InputDecoration(
                        hintText: "Enter your content here...",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 20),
              
              // Variables side panel
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.05),
                        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Click on a variable to insert it into your body at the current cursor position.",
                              style: TextStyle(color: Colors.green.shade800, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text("AVAILABLE VARIABLES (${_templateVariables.length})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey, letterSpacing: 1.1)),
                    const SizedBox(height: 8),
                    Container(
                      height: 400,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: _templateVariables.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          String variable = _templateVariables[index];
                          return InkWell(
                            onTap: () => _insertVariable(variable),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(variable, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981), fontSize: 12)),
                            ),
                          );
                        },
                      ),
                    )
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // ==========================================
  // PREFERENCES TAB LOGIC
  // ==========================================
  Widget _buildPreferencesTab(NotificationProvider provider) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("GLOBAL CHANNELS"),
          _buildGlobalToggles(provider),
          const SizedBox(height: 30),
          
          _buildSectionHeader("REMINDER SCHEDULE"),
          _buildReminderSettings(provider),
          const SizedBox(height: 30),

          _buildSectionHeader("WEEKLY OFFS"),
          _buildWeeklyOffs(provider),
          const SizedBox(height: 30),

          _buildSectionHeader("NOTIFICATION CHANNELS"),
          _buildChannelsMatrix(provider),
          const SizedBox(height: 30),

          _buildSectionHeader("NOTIFICATION FREQUENCY"),
          _buildFrequencyMatrix(provider),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.2)),
    );
  }

  Widget _buildGlobalToggles(NotificationProvider provider) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _toggleCard("WhatsApp Notifications", Icons.chat_bubble_outline, provider.whatsappNotifications, (v) => provider.updateGlobal('whatsappNotifications', v), Colors.green)),
            const SizedBox(width: 12),
            Expanded(child: _toggleCard("Email Notifications", Icons.mail_outline, provider.emailNotifications, (v) => provider.updateGlobal('emailNotifications', v), Colors.redAccent)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Row(
            children: [
              const Icon(Icons.public, color: Colors.blueGrey),
              const SizedBox(width: 16),
              const Expanded(child: Text("Timezone", style: TextStyle(fontWeight: FontWeight.bold))),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: provider.timezone.isEmpty ? 'Asia/Kolkata' : provider.timezone,
                  items: const [
                    DropdownMenuItem(value: 'Asia/Kolkata', child: Text('Asia/Kolkata')),
                    DropdownMenuItem(value: 'UTC', child: Text('UTC')),
                    DropdownMenuItem(value: 'America/New_York', child: Text('America/New_York')),
                    DropdownMenuItem(value: 'Europe/London', child: Text('Europe/London')),
                  ],
                  onChanged: (val) {
                    if (val != null) provider.updateGlobal('timezone', val);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _toggleCard(String title, IconData icon, bool value, Function(bool) onChanged, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Switch.adaptive(value: value, activeColor: const Color(0xFF10B981), onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildReminderSettings(NotificationProvider provider) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.access_time_filled, color: Color(0xFF10B981))),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Daily Reminder Time", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    Text(provider.dailyReminderTime, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if (time != null) provider.updateReminderTime("${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}");
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF1F5F9), elevation: 0, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text("Edit"),
              )
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _toggleCard("WhatsApp Reminders", Icons.chat_bubble_outline, provider.whatsappReminders, (v) => provider.updateGlobal('whatsappReminders', v), Colors.green)),
            const SizedBox(width: 12),
            Expanded(child: _toggleCard("Email Reminders", Icons.mail_outline, provider.emailReminders, (v) => provider.updateGlobal('emailReminders', v), Colors.redAccent)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _toggleCard("Daily Task Report", Icons.analytics_outlined, provider.dailyTaskReport, (v) => provider.updateGlobal('dailyTaskReport', v), Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: Container()), 
          ],
        )
      ],
    );
  }

  Widget _buildWeeklyOffs(NotificationProvider provider) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final fullDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          bool isOff = provider.weeklyOffs.contains(fullDays[index]);
          return GestureDetector(
            onTap: () => provider.toggleWeeklyOff(fullDays[index]),
            child: Column(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: isOff ? const Color(0xFF10B981) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isOff ? const Color(0xFF10B981) : Colors.grey.shade300),
                  ),
                  child: Center(child: Icon(Icons.check, size: 16, color: isOff ? Colors.white : Colors.transparent)),
                ),
                const SizedBox(height: 8),
                Text(days[index], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isOff ? const Color(0xFF10B981) : Colors.grey)),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildChannelsMatrix(NotificationProvider provider) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(const Color(0xFFF8F9FD)),
          columns: const [
            DataColumn(label: Text("Events", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text("Admin", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text("Manager", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text("Member", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          ],
          rows: _eventLabels.entries.map((entry) {
            return DataRow(cells: [
              DataCell(Text(entry.value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
              DataCell(_buildMatrixCheck(provider, entry.key, 'admin')),
              DataCell(_buildMatrixCheck(provider, entry.key, 'manager')),
              DataCell(_buildMatrixCheck(provider, entry.key, 'member')),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFrequencyMatrix(NotificationProvider provider) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: List.generate(3, (index) => Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _activeRoleTab = index),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _activeRoleTab == index ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: _activeRoleTab == index ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
                  ),
                  child: Center(child: Text(_roles[index], style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _activeRoleTab == index ? const Color(0xFF10B981) : Colors.grey))),
                ),
              ),
            )),
          ),
        ),
        const SizedBox(height: 15),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(const Color(0xFF10B981)),
              columns: const [
                DataColumn(label: Text("Events", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                DataColumn(label: Text("Once", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                DataColumn(label: Text("Daily", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                DataColumn(label: Text("Weekly", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
                DataColumn(label: Text("Monthly", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11))),
              ],
              rows: _eventLabels.entries.map((entry) {
                return DataRow(cells: [
                  DataCell(Text(entry.value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                  DataCell(_buildFreqCheck(provider, entry.key, 'once')),
                  DataCell(_buildFreqCheck(provider, entry.key, 'daily')),
                  DataCell(_buildFreqCheck(provider, entry.key, 'weekly')),
                  DataCell(_buildFreqCheck(provider, entry.key, 'monthly')),
                ]);
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMatrixCheck(NotificationProvider provider, String event, String role) {
    bool isChecked = provider.notificationChannels[event]?[role] ?? false;
    return Center(
      child: GestureDetector(
        onTap: () => provider.toggleChannel(event, role),
        child: Container(
          width: 22, height: 22,
          decoration: BoxDecoration(color: isChecked ? const Color(0xFF10B981) : Colors.transparent, borderRadius: BorderRadius.circular(6), border: Border.all(color: isChecked ? const Color(0xFF10B981) : Colors.grey.shade300)),
          child: isChecked ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
        ),
      ),
    );
  }

  Widget _buildFreqCheck(NotificationProvider provider, String event, String freq) {
    String role = _roles[_activeRoleTab].toLowerCase();
    bool isChecked = provider.notificationFrequency[role]?[event]?[freq] ?? false;
    return Center(
      child: GestureDetector(
        onTap: () => provider.toggleFrequency(event, freq, role),
        child: Container(
          width: 22, height: 22,
          decoration: BoxDecoration(color: isChecked ? const Color(0xFF10B981) : Colors.transparent, borderRadius: BorderRadius.circular(6), border: Border.all(color: isChecked ? const Color(0xFF10B981) : Colors.grey.shade300)),
          child: isChecked ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
        ),
      ),
    );
  }

  Widget _buildBottomSaveBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
      child: ElevatedButton.icon(
        onPressed: () => context.read<NotificationProvider>().saveSettings(),
        icon: const Icon(Icons.save, color: Colors.white),
        label: const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      ),
    );
  }
}
