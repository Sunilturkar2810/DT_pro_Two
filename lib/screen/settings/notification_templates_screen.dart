import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../provider/notification_provider.dart';

class NotificationTemplatesScreen extends StatefulWidget {
  const NotificationTemplatesScreen({super.key});

  @override
  State<NotificationTemplatesScreen> createState() => _NotificationTemplatesScreenState();
}

class _NotificationTemplatesScreenState extends State<NotificationTemplatesScreen> {
  String _activeEvent = 'newTask';
  String _activeChannel = 'email';
  
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  bool _isActive = true;

  final Map<String, String> _events = {
    'newTask': 'New Task',
    'taskEdit': 'Task Edited',
    'taskComment': 'Task Comment',
    'taskInProgress': 'Task In-Progress',
    'taskComplete': 'Task Complete',
    'taskReOpen': 'Task Re-Open',
    'dailyPendingReminders': 'Daily Pending Reminders',
    'reminder': 'Custom',
  };

  final List<Map<String, String>> _variables = [
    {'key': '{taskTitle}', 'label': 'Task Title', 'desc': 'The title of the task'},
    {'key': '{taskDescription}', 'label': 'Description', 'desc': 'Task description'},
    {'key': '{priority}', 'label': 'Priority', 'desc': 'Task priority level'},
    {'key': '{category}', 'label': 'Category', 'desc': 'Task category'},
    {'key': '{dueDate}', 'label': 'Due Date', 'desc': 'Formatted due date'},
    {'key': '{assignerName}', 'label': 'Assigner', 'desc': 'Who assigned the task'},
    {'key': '{doerName}', 'label': 'Assignee', 'desc': 'Who is assigned'},
    {'key': '{updatedBy}', 'label': 'Updated By', 'desc': 'Who edited the task'},
    {'key': '{status}', 'label': 'Status', 'desc': 'Current task status'},
    {'key': '{remark}', 'label': 'Remark', 'desc': 'Recent comment'},
    {'key': '{commenterName}', 'label': 'Commenter', 'desc': 'Who added the remark'},
    {'key': '{taskList}', 'label': 'Task List', 'desc': 'Summary list (Daily Report)'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTemplate();
    });
  }

  void _loadTemplate() async {
    final provider = context.read<NotificationProvider>();
    await provider.fetchTemplate(_activeEvent, _activeChannel);
    if (provider.activeTemplate != null) {
      setState(() {
        _subjectController.text = provider.activeTemplate!['subject'] ?? "";
        _bodyController.text = provider.activeTemplate!['body'] ?? "";
        _isActive = provider.activeTemplate!['isActive'] ?? true;
      });
    } else {
      setState(() {
        _subjectController.clear();
        _bodyController.clear();
        _isActive = true;
      });
    }
  }

  void _saveTemplate() async {
    final provider = context.read<NotificationProvider>();
    final success = await provider.saveTemplate({
      'eventName': _activeEvent,
      'channel': _activeChannel,
      'subject': _subjectController.text,
      'body': _bodyController.text,
      'isActive': _isActive,
    });
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Template saved successfully!"), 
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        )
      );
    }
  }

  void _insertVariable(String key) {
    final text = _bodyController.text;
    final selection = _bodyController.selection;
    
    if (selection.start >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, key);
      _bodyController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + key.length),
      );
    } else {
      _bodyController.text += key;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("NOTIFICATION TEMPLATES", 
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.2)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              return Padding(
                padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                child: ElevatedButton.icon(
                  onPressed: provider.isTemplateLoading ? null : _saveTemplate,
                  icon: provider.isTemplateLoading 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(LucideIcons.save, size: 16),
                  label: Text(provider.isTemplateLoading ? "SAVING..." : "SAVE"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              );
            }
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar - Event Types
          Container(
            width: 160,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Text("EVENT TYPES", 
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1.5)
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    children: _events.entries.map((e) {
                      bool active = _activeEvent == e.key;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: InkWell(
                          onTap: () {
                            setState(() => _activeEvent = e.key);
                            _loadTemplate();
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            decoration: BoxDecoration(
                              color: active ? const Color(0xFF10B981) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: active ? [
                                BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                              ] : null,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(e.value, 
                                    style: TextStyle(
                                      fontSize: 12, 
                                      fontWeight: active ? FontWeight.bold : FontWeight.w600, 
                                      color: active ? Colors.white : const Color(0xFF64748B)
                                    )
                                  ),
                                ),
                                if (active) const Icon(LucideIcons.check, size: 14, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // Main Content
          Expanded(
            child: Consumer<NotificationProvider>(
              builder: (context, provider, _) {
                if (provider.isTemplateLoading && provider.activeTemplate == null) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header & Active Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${_events[_activeEvent]} ${_activeChannel.toUpperCase()}".toUpperCase(),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))
                              ),
                              const Text("Design how this notification will look", 
                                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFF1F5F9)),
                            ),
                            child: Row(
                              children: [
                                const Text("ACTIVE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 1)),
                                const SizedBox(width: 8),
                                Switch.adaptive(
                                  value: _isActive, 
                                  activeTrackColor: const Color(0xFF10B981),
                                  onChanged: (v) => setState(() => _isActive = v),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Channel Tabs
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _channelTab("Email", 'email', LucideIcons.mail),
                            _channelTab("WhatsApp", 'whatsapp', LucideIcons.messageSquare),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Editor Section
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_activeChannel == 'email') ...[
                                  _buildSectionLabel("EMAIL SUBJECT"),
                                  TextField(
                                    controller: _subjectController,
                                    decoration: _inputDeco("Enter email subject..."),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                                
                                _buildSectionLabel(_activeChannel == 'email' ? "EMAIL BODY (HTML SUPPORTED)" : "WHATSAPP MESSAGE"),
                                TextField(
                                  controller: _bodyController,
                                  maxLines: 12,
                                  decoration: _inputDeco("Enter content here..."),
                                  style: const TextStyle(fontSize: 13, fontFamily: 'monospace', color: Color(0xFF334155), height: 1.5),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          
                          // Variables Sidebar
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFD1FAE5)),
                                  ),
                                  child: const Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(LucideIcons.info, size: 16, color: Color(0xFF059669)),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          "Click a variable to insert it into your content.",
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF065F46)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildSectionLabel("AVAILABLE VARIABLES"),
                                Container(
                                  height: 400,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFFF1F5F9)),
                                  ),
                                  child: ListView.separated(
                                    itemCount: _variables.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final v = _variables[index];
                                      return InkWell(
                                        onTap: () => _insertVariable(v['key']!),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: const Color(0xFFF1F5F9)),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(v['key']!, 
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF059669))
                                              ),
                                              const SizedBox(height: 2),
                                              Text(v['label']!, 
                                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFF64748B))
                                              ),
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
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _channelTab(String label, String code, IconData icon) {
    bool active = _activeChannel == code;
    return InkWell(
      onTap: () {
        setState(() => _activeChannel = code);
        _loadTemplate();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: active ? [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
          ] : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: active ? const Color(0xFF10B981) : const Color(0xFF64748B)),
            const SizedBox(width: 8),
            Text(label, 
              style: TextStyle(
                color: active ? const Color(0xFF1E293B) : const Color(0xFF64748B), 
                fontWeight: FontWeight.bold, 
                fontSize: 13
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4), 
      child: Text(text, 
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1.2)
      )
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.all(20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFFF1F5F9))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFFF1F5F9))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFF10B981), width: 2)),
    );
  }
}
