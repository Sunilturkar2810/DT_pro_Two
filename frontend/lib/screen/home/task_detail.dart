import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:d_table_delegate_system/model/delegate_model.dart';
import 'package:d_table_delegate_system/provider/auth_provider.dart';
import 'package:d_table_delegate_system/provider/delegation_provider.dart';
import 'package:d_table_delegate_system/provider/user_provider.dart';
import 'package:d_table_delegate_system/widget/app_dropdown.dart';

class TaskDetailScreen extends StatefulWidget {
  final dynamic task;
  final bool allowEdit;

  const TaskDetailScreen({
    super.key,
    required this.task,
    this.allowEdit = false,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TextEditingController remarkController = TextEditingController();
  String selectedStatus = "Pending";
  DateTime? _holdTillDate;
  bool _isDetailLoading = true;
  DelegationModel? _currentTask; // ← Local state: direct backend se fresh data
  
  // Audio Player State
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  final List<String> availableStatuses = [
    "Pending",
    "In Progress",
    "Completed",
    "Need Revision",
    "Hold",
    "Overdue"
  ];

  @override
  void initState() {
    super.initState();
    // Initial state se start karo (title/status etc)
    _currentTask = widget.task is DelegationModel ? widget.task as DelegationModel : null;
    selectedStatus = widget.task.status ?? 'Pending';
    if (!availableStatuses.contains(selectedStatus)) {
      selectedStatus = "Pending";
    }
    
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) setState(() => _duration = newDuration);
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) setState(() => _position = newPosition);
    });
    
    // Backend se fresh data load karo (remarks, voice, images sab aa jaenge)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTaskDetail();
    });
  }

  // Direct backend se fresh task data fetch karo
  Future<void> _loadTaskDetail() async {
    final taskId = widget.task.id?.toString();
    if (taskId == null || taskId.isEmpty) {
      setState(() => _isDetailLoading = false);
      return;
    }
    setState(() => _isDetailLoading = true);
    try {
      final service = Provider.of<DelegationProvider>(context, listen: false);
      // getDelegationById directly call karo
      final rawResponse = await service.fetchTaskDetail(taskId);
      if (rawResponse != null && mounted) {
        setState(() {
          _currentTask = rawResponse;
          selectedStatus = rawResponse.status;
          if (!availableStatuses.contains(selectedStatus)) {
            selectedStatus = 'Pending';
          }
          _isDetailLoading = false;
        });
        print('✅ Task detail loaded: remarks=${rawResponse.remarks.length}, voice=${rawResponse.voiceNoteUrl}, docs=${rawResponse.referenceDocs.length}');
      } else {
        setState(() => _isDetailLoading = false);
      }
    } catch (e) {
      print('❌ Load Task Detail Error: $e');
      if (mounted) setState(() => _isDetailLoading = false);
    }
  }

  @override
  void dispose() {
    remarkController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio(String url) async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(UrlSource(url));
    }
  }

  Future<void> _openAttachment(String url) async {
    final lower = url.toLowerCase();
    final isImage = lower.contains('.jpg') || lower.contains('.jpeg') ||
        lower.contains('.png') || lower.contains('.gif') ||
        lower.contains('.webp');

    if (isImage) {
      // Image ke liye in-app viewer dikhao — reliable on all Android versions
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
              title: const Text('Image', style: TextStyle(color: Colors.white)),
            ),
            body: Center(
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const Center(child: CircularProgressIndicator(color: Colors.white)),
                  errorBuilder: (_, __, ___) => const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, color: Colors.white54, size: 60),
                        SizedBox(height: 12),
                        Text('Could not load image', style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      return;
    }

    // Non-image files ke liye browser/external app mein open karo
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // Fallback: browser mein kholo
      try {
        await launchUrl(Uri.parse(url), mode: LaunchMode.platformDefault);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open file')),
          );
        }
      }
    }
  }

  Future<void> _updateStatusOnly(
      DelegationProvider prov, AuthProvider auth, String taskId, DelegationModel currentTask) async {
    final userId = auth.currentUser?.id ?? "";

    if (selectedStatus != currentTask.status) {
      bool success = await prov.updateStatus(taskId, selectedStatus, "Status updated from detail screen", userId);
      if (success) {
        // Local state bhi refresh karo
        await _loadTaskDetail();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Status updated successfully!", style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.green));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("Failed to update status."), backgroundColor: Colors.red));
        }
      }
    }
  }

  Future<void> _addRemarkOnly(DelegationProvider prov, AuthProvider auth, String taskId) async {
    final userId = auth.currentUser?.id ?? "";
    if (remarkController.text.trim().isNotEmpty) {
      bool success = await prov.postRemark(taskId, remarkController.text.trim(), userId);
      if (success) {
        // Local state refresh karo taaki naye remark dikhe
        await _loadTaskDetail();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Remark added!", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
          remarkController.clear();
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Please enter a remark.", style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.orange));
      }
    }
  }

  String _resolveName(String id, DelegationModel task, BuildContext context) {
    if (id == task.assingDoerId && task.assigneeName.isNotEmpty) return task.assigneeName;
    if (id == task.delegatorId && task.delegatorName.isNotEmpty) return task.delegatorName;
    try {
      final userProv = Provider.of<UserProvider>(context, listen: false);
      final user = userProv.users.firstWhere((u) => u.id == id);
      return user.fullName;
    } catch (e) {
      return id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    // Local _currentTask use karo — widget.task fallback ke saath
    final task = _currentTask ?? (widget.task is DelegationModel ? widget.task as DelegationModel : null);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text("Task Details", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 18)),
        backgroundColor: const Color(0xFF20E19F),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isDetailLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              onPressed: _loadTaskDetail,
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: task == null
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF20E19F)))
          : SafeArea(
        child: Consumer<DelegationProvider>(
          builder: (context, delegationProv, child) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTopCard(task, constraints),
                              const SizedBox(height: 20),
                              _buildExtraDetailsCard(task),
                              const SizedBox(height: 20),
                              if (widget.allowEdit) ...[
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFE5E7EB)),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                                    ]
                                  ),
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                        const Row(
                                          children: [
                                            Icon(Icons.edit_note, size: 22, color: Color(0xFF111827)),
                                            SizedBox(width: 8),
                                            Text("UPDATE STATUS",
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w900,
                                                    color: Color(0xFF111827),
                                                    letterSpacing: 1.0)),
                                          ],
                                        ),
                                        const SizedBox(height: 24),
                                        _buildUpdateStatusSection(task, delegationProv, auth),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                              ],
                              // ADD REMARK — visible for everyone
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                                  ]
                                ),
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.chat_bubble_outline, size: 22, color: Color(0xFF111827)),
                                        SizedBox(width: 8),
                                        Text("ADD REMARK",
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFF111827),
                                                letterSpacing: 1.0)),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    _buildAddRemarkSection(task, delegationProv, auth),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                  boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                                  ]
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.history, size: 22, color: Color(0xFF111827)),
                                        SizedBox(width: 8),
                                        Text("REMARK HISTORY",
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFF111827),
                                                letterSpacing: 1.0)),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    _buildRemarkHistory(task, context),
                                  ],
                                ),
                              )
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============== TOP CARD (Core Info + Involved Parties) ==============

  Widget _buildTopCard(DelegationModel task, BoxConstraints constraints) {
    bool isWeb = constraints.maxWidth > 800;

    Widget coreInfo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(task.delegationName.toUpperCase(),
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF111827), letterSpacing: 0.5)),
        if (task.description.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text("DESCRIPTION", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 1.0)),
          const SizedBox(height: 6),
          Text(task.description, style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563))),
        ],
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Divider(color: Color(0xFFF3F4F6)),
        ),
        const Row(
          children: [
            Icon(Icons.info_outline, size: 20, color: Color(0xFF111827)),
            SizedBox(width: 8),
            Text("CORE INFORMATION",
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF111827), letterSpacing: 1.0)),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 24,
          runSpacing: 16,
          children: [
            _infoBlock("CATEGORY", Icons.check_circle_outline, Colors.blue,
                task.category.isNotEmpty ? task.category : "General"),
            _infoBlock("PRIORITY", Icons.circle, Colors.grey, task.priority, iconSize: 12),
            _infoBlock("DEADLINE", Icons.calendar_today_outlined, Colors.orange,
                task.dueDate.isNotEmpty ? task.dueDate : "N/A"),
            _infoBlock("EVIDENCE REQUIRED", Icons.check_circle_outline, Colors.green,
                task.evidenceRequired ? "Yes" : "No"),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Divider(color: Color(0xFFF3F4F6)),
        ),
        const Text("TASK TAGS",
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 1.0)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_offer_outlined, size: 14, color: Color(0xFF4F46E5)),
              const SizedBox(width: 6),
              Text(task.department.isNotEmpty ? task.department.toUpperCase() : "GENERAL",
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF4F46E5))),
            ],
          ),
        ),
      ],
    );

    Widget involvedParties = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.people_alt_outlined, size: 20, color: Color(0xFF111827)),
            SizedBox(width: 8),
            Text("PARTICIPANTS",
                style: TextStyle(
                    fontWeight: FontWeight.w900, color: Color(0xFF111827), fontSize: 13, letterSpacing: 1.0)),
          ],
        ),
        const SizedBox(height: 16),
        _involvedPartyRow(
            "ASSIGNED BY",
            _resolveName(task.delegatorId, task, context),
            Icons.outbox_rounded,
            const Color(0xFF3B82F6)),
        const SizedBox(height: 12),
        _involvedPartyRow(
            "ASSIGNED TO",
            _resolveName(task.assingDoerId, task, context),
            Icons.inbox_rounded,
            const Color(0xFFF97316)),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Divider(color: Color(0xFFF3F4F6)),
        ),
        const Text("IN LOOP",
            style: TextStyle(
                fontWeight: FontWeight.w800, color: Color(0xFF6B7280), fontSize: 11, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        if (task.inLoopIds.isEmpty)
          const Text("No users in loop", style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13))
        else
          Text(task.inLoopIds.map((id) => _resolveName(id, task, context)).join(", "),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("CREATED ON",
                    style: TextStyle(
                        fontWeight: FontWeight.w900, color: Color(0xFF111827), fontSize: 11, letterSpacing: 1.0)),
                const SizedBox(height: 4),
                Text(task.dueDate.isNotEmpty ? task.dueDate : "N/A",
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF4B5563), fontSize: 12)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("DELEGATION ID",
                    style: TextStyle(
                        fontWeight: FontWeight.w900, color: Color(0xFF111827), fontSize: 11, letterSpacing: 1.0)),
                const SizedBox(height: 4),
                Text(
                    task.id != null
                        ? "#${task.id!.substring(task.id!.length > 8 ? task.id!.length - 8 : 0)}"
                        : "N/A",
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF4B5563), fontSize: 12)),
              ],
            ),
          ],
        )
      ],
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
          ]),
      padding: const EdgeInsets.all(20),
      child: isWeb
          ? IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 5, child: coreInfo),
                  const VerticalDivider(color: Color(0xFFF3F4F6), thickness: 1, width: 32),
                  Expanded(flex: 4, child: involvedParties),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                coreInfo,
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(color: Color(0xFFF3F4F6)),
                ),
                involvedParties,
              ],
            ),
    );
  }

  Widget _infoBlock(String label, IconData icon, Color iconColor, String value, {double iconSize = 16}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 1.0)),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize, color: iconColor),
            const SizedBox(width: 8),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
          ],
        )
      ],
    );
  }

  // ============== EXTRA DETAILS CARD ==============

  Widget _buildExtraDetailsCard(DelegationModel task) {
    final bool hasChecklist = task.checklistItems.isNotEmpty;
    final bool hasRepeat = task.isRepeat;
    final bool hasAsset = task.asset != null && task.asset!.isNotEmpty;
    final bool hasStartDate = task.repeatStartDate != null && task.repeatStartDate!.isNotEmpty;
    final bool hasVoice = task.voiceNoteUrl != null && task.voiceNoteUrl!.isNotEmpty;
    final bool hasFiles = task.referenceDocs.isNotEmpty;
    final bool hasReminder = task.reminderAt != null && task.reminderAt!.isNotEmpty;

    if (!hasChecklist && !hasRepeat && !hasAsset && !hasStartDate &&
        !hasVoice && !hasFiles && !hasReminder) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          const Row(
            children: [
              Icon(Icons.format_list_bulleted_rounded, size: 20, color: Color(0xFF111827)),
              SizedBox(width: 8),
              Text("TASK DETAILS",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                      letterSpacing: 1.0)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF3F4F6)),
          const SizedBox(height: 16),

          // ── Start & End Dates Row ──
          if (hasStartDate) ...[
            Row(
              children: [
                Expanded(
                  child: _detailInfoTile(
                    icon: Icons.play_circle_outline_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    label: "START DATE",
                    value: _formatDisplayDate(task.repeatStartDate ?? ''),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _detailInfoTile(
                    icon: Icons.stop_circle_outlined,
                    iconColor: const Color(0xFFF59E0B),
                    label: "END DATE",
                    value: _formatDisplayDate(task.repeatEndDate ?? ''),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // ── Reminder ──
          if (hasReminder) ...[
            _detailInfoTile(
              icon: Icons.alarm_on_rounded,
              iconColor: const Color(0xFFF59E0B),
              label: "REMINDER",
              value: _formatDisplayDateTime(task.reminderAt!),
            ),
            const SizedBox(height: 16),
          ],

          // ── Voice Recording ──
          if (hasVoice) ...[
            const Text("VOICE NOTE",
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6B7280),
                    letterSpacing: 1.0)),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _toggleAudio(task.voiceNoteUrl!),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.25)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.mic_rounded, size: 18, color: Color(0xFFEF4444)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Voice Recording',
                                  style: TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                              const SizedBox(height: 2),
                              Text(
                                task.voiceNoteUrl!.split('/').last,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                              ),
                            ],
                          ),
                        ),
                        Icon(_isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded, color: const Color(0xFFEF4444), size: 28),
                      ],
                    ),
                    if (_duration > Duration.zero) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _position.inMilliseconds / _duration.inMilliseconds,
                        backgroundColor: const Color(0xFFEF4444).withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── File Attachments ──
          if (hasFiles) ...[
            const Text("ATTACHMENTS",
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6B7280),
                    letterSpacing: 1.0)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: task.referenceDocs.map((url) {
                final name = url.split('/').last;
                final ext = name.contains('.') ? name.split('.').last.toLowerCase() : 'file';
                return InkWell(
                  onTap: () => _openAttachment(url),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_extIcon(ext), size: 16, color: const Color(0xFF6366F1)),
                        const SizedBox(width: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 130),
                          child: Text(
                            name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4338CA)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // ── Asset / Reference ──
          if (hasAsset) ...[
            _detailInfoTile(
              icon: Icons.link_rounded,
              iconColor: const Color(0xFF8B5CF6),
              label: "ASSET / REFERENCE",
              value: task.asset!,
            ),
            const SizedBox(height: 16),
          ],

          // ── Repeat Info ──
          if (hasRepeat) ...[
            _detailInfoTile(
              icon: Icons.repeat_rounded,
              iconColor: const Color(0xFF20E19F),
              label: "REPEAT SCHEDULE",
              value: task.repeatFrequency ?? 'Yes',
            ),
            const SizedBox(height: 16),
          ],

          // ── Checklist Items ──
          if (hasChecklist) ...[
            const Text("CHECKLIST",
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6B7280),
                    letterSpacing: 1.0)),
            const SizedBox(height: 12),
            ...task.checklistItems.asMap().entries.map((entry) {
              final item = entry.value;
              final text = item['text']?.toString() ?? '';
              final status = item['status']?.toString() ?? 'Pending';
              final itemId = item['id']?.toString() ?? ''; // Make sure DB provides 'id'
              final isDone = status.toLowerCase() == 'completed' || status.toLowerCase() == 'done';
              
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final canToggle = auth.currentUser?.id == task.assingDoerId;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isDone
                      ? const Color(0xFF20E19F).withOpacity(0.06)
                      : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDone
                        ? const Color(0xFF20E19F).withOpacity(0.3)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: (canToggle && itemId.isNotEmpty) ? () async {
                    final newStatus = isDone ? 'Pending' : 'Completed';
                    final prov = Provider.of<DelegationProvider>(context, listen: false);
                    bool success = await prov.updateChecklistStatus(task.id!, itemId, newStatus);
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Checklist item updated to $newStatus")));
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(prov.errorMessage ?? "Failed to update status")));
                    }
                  } : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                          size: 18,
                          color: isDone ? const Color(0xFF20E19F) : const Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            text,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDone ? const Color(0xFF6B7280) : const Color(0xFF111827),
                              decoration: isDone ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDone
                                ? const Color(0xFF20E19F).withOpacity(0.12)
                                : const Color(0xFFF59E0B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isDone ? const Color(0xFF20E19F) : const Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  IconData _extIcon(String ext) {
    switch (ext) {
      case 'pdf': return Icons.picture_as_pdf_rounded;
      case 'doc': case 'docx': return Icons.description_rounded;
      case 'xls': case 'xlsx': return Icons.table_chart_rounded;
      case 'zip': case 'rar': return Icons.folder_zip_rounded;
      case 'mp4': case 'mov': return Icons.video_file_rounded;
      case 'mp3': case 'wav': case 'm4a': return Icons.audio_file_rounded;
      case 'jpg': case 'jpeg': case 'png': case 'gif': return Icons.image_rounded;
      default: return Icons.insert_drive_file_rounded;
    }
  }

  Widget _detailInfoTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6B7280),
                        letterSpacing: 0.8)),
                const SizedBox(height: 4),
                Text(value.isNotEmpty ? value : 'N/A',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDisplayDate(String rawDate) {
    if (rawDate.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(rawDate);
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return rawDate;
    }
  }

  // ============== UPDATE STATUS SECTION ==============

  Widget _buildUpdateStatusSection(DelegationModel task, DelegationProvider prov, AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("SELECT STATUS",
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 1.0)),
        const SizedBox(height: 12),

        // Custom Dropdown for State
        AppDropdown<String>(
          value: selectedStatus,
          items: availableStatuses,
          labelBuilder: (v) => v,
          onChanged: (val) {
            if (val != null) setState(() => selectedStatus = val);
          },
          label: "TASK STATUS",
          isCompact: false,
          prefixIcon: selectedStatus == "Hold"
              ? Icons.access_time_filled
              : (selectedStatus == "Completed" ? Icons.check_circle : Icons.change_circle_rounded),
          accentColor: const Color(0xFF20E19F),
        ),

        const SizedBox(height: 24),

        if (selectedStatus == "Hold") ...[
          const Text("HOLD TILL DATE",
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6B7280), letterSpacing: 1.0)),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _holdTillDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setState(() => _holdTillDate = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _holdTillDate != null ? DateFormat('dd-MM-yyyy').format(_holdTillDate!) : "Select Date",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _holdTillDate != null ? const Color(0xFF111827) : const Color(0xFF9CA3AF)),
                  ),
                  const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF111827)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF111827),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _updateStatusOnly(prov, auth, task.id!, task),
            child: const Text("Update Status",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildAddRemarkSection(DelegationModel task, DelegationProvider prov, AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: remarkController,
          maxLines: 4,
          style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
          decoration: InputDecoration(
            hintText: "Enter your remark details here...",
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontStyle: FontStyle.italic),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF20E19F))),
          ),
        ),

        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF20E19F),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _addRemarkOnly(prov, auth, task.id!),
            child: const Text("Post Remark",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildRemarkHistory(DelegationModel task, BuildContext context) {
    if (task.remarks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Center(
          child: Text("No remarks logged yet.",
              style: TextStyle(color: Color(0xFF6B7280), fontStyle: FontStyle.italic)),
        ),
      );
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = auth.currentUser?.id;

    return Column(
      children: task.remarks.map((r) {
        String resolvedName = _resolveName(r.assignedUserId, task, context);
        bool isMyRemark = currentUserId == r.assignedUserId;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: const Color(0xFFE5E7EB),
                          child: Text(
                            _getInitial(resolvedName),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(resolvedName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF111827), fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(r.date,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600)),
                      if (isMyRemark)
                        InkWell(
                          onTap: () {
                            _showRemarkOptions(context, task, r);
                          },
                          child: const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Icon(Icons.more_horiz, size: 16, color: Color(0xFF6B7280)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(r.remark, style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563), height: 1.5)),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showRemarkOptions(BuildContext context, DelegationModel task, RemarkModel remark) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Color(0xFF3B82F6)),
                title: const Text('Edit Remark'),
                onTap: () {
                  Navigator.pop(ctx);
                  _editRemarkDialog(context, task, remark);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Color(0xFFEF4444)),
                title: const Text('Delete Remark', style: TextStyle(color: Color(0xFFEF4444))),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteRemark(context, task.id!, remark.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _editRemarkDialog(BuildContext context, DelegationModel task, RemarkModel remark) {
    final TextEditingController editController = TextEditingController(text: remark.remark);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit Remark', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: TextField(
            controller: editController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Update your remark...",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF20E19F)),
              onPressed: () async {
                final newText = editController.text.trim();
                if (newText.isEmpty) return;
                Navigator.pop(ctx);
                final prov = Provider.of<DelegationProvider>(context, listen: false);
                FocusScope.of(context).unfocus();
                bool success = await prov.updateRemark(task.id!, remark.id, newText);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Remark updated")));
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(prov.errorMessage ?? "Failed to update remark")));
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _deleteRemark(BuildContext context, String taskId, String remarkId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Remark'),
        content: const Text('Are you sure you want to delete this remark?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final prov = Provider.of<DelegationProvider>(context, listen: false);
              bool success = await prov.deleteRemark(taskId, remarkId);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Remark deleted")));
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(prov.errorMessage ?? "Failed to delete remark")));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  Widget _involvedPartyRow(String label, String name, IconData icon, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Text("$label: ", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
        Expanded(child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF111827)))),
      ],
    );
  }

  String _getInitial(String text) {
    if (text.isEmpty) return "?";
    return text.trim().substring(0, 1).toUpperCase();
  }

  String _formatDisplayDateTime(String rawDate) {
    if (rawDate.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(rawDate);
      return DateFormat('EEE, dd MMM yyyy • hh:mm a').format(dt);
    } catch (_) {
      return rawDate;
    }
  }
}
