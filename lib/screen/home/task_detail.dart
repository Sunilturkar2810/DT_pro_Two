import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:d_table_delegate_system/model/delegate_model.dart';
import 'package:d_table_delegate_system/provider/auth_provider.dart';
import 'package:d_table_delegate_system/provider/delegation_provider.dart';
import 'package:d_table_delegate_system/provider/user_provider.dart';
import 'package:d_table_delegate_system/widget/assign_task_sheet.dart';

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
  final FocusNode _remarkFocusNode = FocusNode();
  bool _isDetailLoading = true;
  bool _isActionLoading = false;
  DelegationModel? _currentTask;
  
  // Audio Player State
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    
    // Handle both DelegationModel and Map inputs
    if (widget.task is DelegationModel) {
      _currentTask = widget.task as DelegationModel;
    }

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTaskDetail());
  }

  Future<void> _loadTaskDetail() async {
    String? taskId;
    if (widget.task is DelegationModel) {
      taskId = (widget.task as DelegationModel).id;
    } else if (widget.task is Map) {
      taskId = widget.task['id']?.toString() ?? widget.task['_id']?.toString();
    }

    if (taskId == null || taskId.isEmpty) {
      if (mounted) setState(() => _isDetailLoading = false);
      return;
    }

    setState(() => _isDetailLoading = true);
    try {
      final service = Provider.of<DelegationProvider>(context, listen: false);
      final rawResponse = await service.fetchTaskDetail(taskId);
      if (rawResponse != null && mounted) {
        setState(() {
          _currentTask = rawResponse;
          _isDetailLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isDetailLoading = false);
    }
  }

  @override
  void dispose() {
    remarkController.dispose();
    _remarkFocusNode.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _deleteTask() async {
    final taskId = _currentTask?.id;
    if (taskId == null || taskId.isEmpty || _isActionLoading) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('This task will be moved to trash. Do you want to continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isActionLoading = true);
    final success = await context.read<DelegationProvider>().delete(taskId);
    if (!mounted) return;

    setState(() => _isActionLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Task moved to trash' : 'Failed to delete task'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _submitRemark() async {
    final taskId = _currentTask?.id;
    final userId = context.read<AuthProvider>().currentUser?.id ?? '';
    final remark = remarkController.text.trim();

    if (taskId == null ||
        taskId.isEmpty ||
        userId.isEmpty ||
        remark.isEmpty ||
        _isActionLoading) {
      return;
    }

    setState(() => _isActionLoading = true);
    final success = await context.read<DelegationProvider>().postRemark(
      taskId,
      remark,
      userId,
    );
    if (!mounted) return;

    setState(() => _isActionLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Update added successfully' : 'Failed to submit update'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      remarkController.clear();
      await _loadTaskDetail();
    }
  }

  Future<void> _changeStatus(String newStatus, {String reason = ''}) async {
    final taskId = _currentTask?.id;
    final userId = context.read<AuthProvider>().currentUser?.id ?? '';
    if (taskId == null || taskId.isEmpty || userId.isEmpty || _isActionLoading) {
      return;
    }

    setState(() => _isActionLoading = true);
    final success = await context.read<DelegationProvider>().updateStatus(
      taskId,
      newStatus,
      reason,
      userId,
    );
    if (!mounted) return;

    setState(() => _isActionLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Status updated to $newStatus' : 'Failed to update status'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      await _loadTaskDetail();
    }
  }

  void _focusRemarkBox() {
    FocusScope.of(context).requestFocus(_remarkFocusNode);
  }

  void _showReminderInfo(DelegationModel task) {
    final reminderAt = task.reminderAt;
    final reminderText = (reminderAt != null && reminderAt.isNotEmpty)
        ? _formatDate(reminderAt)
        : 'No reminder is configured for this task.';

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reminder'),
        content: Text(reminderText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  bool _isChecklistItemDone(Map<String, dynamic> item) {
    final completed = item['completed'];
    final status = item['status']?.toString().toLowerCase();
    return completed == true || status == 'completed' || status == 'done';
  }

  String _checklistItemLabel(Map<String, dynamic> item) {
    return (item['itemName'] ?? item['text'] ?? item['title'] ?? '')
        .toString()
        .trim();
  }

  Future<void> _toggleChecklistItem(
    DelegationModel task,
    Map<String, dynamic> item,
    int index,
  ) async {
    final taskId = task.id;
    if (taskId == null || taskId.isEmpty || _isActionLoading) return;

    final checklistId = item['id']?.toString() ?? index.toString();
    final newStatus = _isChecklistItemDone(item) ? 'Pending' : 'Completed';

    setState(() => _isActionLoading = true);
    final success = await context
        .read<DelegationProvider>()
        .updateChecklistStatus(taskId, checklistId, newStatus);
    if (!mounted) return;

    setState(() => _isActionLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Checklist updated'
            : 'Failed to update checklist'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) {
      await _loadTaskDetail();
    }
  }

  String _resolveUserName(String userId) {
    final users = context.read<UserProvider>().users;
    for (final user in users) {
      if (user.id == userId) {
        final name = user.fullName.trim();
        return name.isEmpty ? userId : name;
      }
    }
    return userId.isEmpty ? 'Unknown' : userId;
  }

  Future<void> _openExternalLink(String url) async {
    final parsed = Uri.tryParse(url);
    if (parsed == null) return;
    await launchUrl(parsed, mode: LaunchMode.externalApplication);
  }

  Future<void> _toggleVoicePlayback(String url) async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        return;
      }
      await _audioPlayer.play(UrlSource(url));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to play voice note'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openSubTaskSheet(DelegationModel task) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => AssignTaskSheet(
        parentTaskId: task.id,
        parentTaskTitle: task.delegationName,
        groupId: task.groupId,
      ),
    );

    if (created == true && mounted) {
      await _loadTaskDetail();
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed':
        return const Color(0xFF10B981);
      case 'In Progress':
        return Colors.orange;
      case 'Overdue':
        return Colors.redAccent;
      case 'Pending':
        return Colors.blueGrey;
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'Urgent':
        return Colors.redAccent;
      case 'High':
        return Colors.orange;
      case 'Medium':
        return Colors.blue;
      case 'Low':
        return Colors.green;
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading if we don't have task data yet (especially when coming from Map)
    if (_isDetailLoading && _currentTask == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF20E19F))),
      );
    }

    final task = _currentTask;
    if (task == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Colors.black)),
        body: const Center(child: Text("Task not found or failed to load")),
      );
    }

    final currentUserId = context.read<AuthProvider>().currentUser?.id;
    final isAssigner = currentUserId != null && currentUserId == task.delegatorId;
    final isDoer = currentUserId != null && currentUserId == task.assingDoerId;
    final canAct = isAssigner || isDoer;
    final completedChecklistCount =
        task.checklistItems.where(_isChecklistItemDone).length;
    final completedSubtasksCount =
        task.subtasks.where((item) => item.status == 'Completed').length;
    final attachmentUrls = [
      ...task.referenceDocs,
      if (task.evidenceUrl != null && task.evidenceUrl!.trim().isNotEmpty)
        task.evidenceUrl!.trim(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Flexible(
                        child: Text("DELEGATIONS", overflow: TextOverflow.ellipsis, style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w900)),
                      ),
                      const Icon(Icons.chevron_right, size: 16, color: Color(0xFFCBD5E1)),
                      const Flexible(
                        child: Text("DETAILS", overflow: TextOverflow.ellipsis, style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _statusPill(task.status),
                    if (canAct)
                      IconButton(
                        icon: const Icon(LucideIcons.trash2,
                            color: Colors.red, size: 20),
                        onPressed: _isActionLoading ? null : _deleteTask,
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(task.delegationName, 
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
            const SizedBox(height: 24),

            _buildSectionCard(
              title: "CORE INFORMATION",
              icon: LucideIcons.info,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 32,
                    runSpacing: 20,
                    children: [
                      _infoTile("CATEGORY", LucideIcons.tag, Colors.indigo,
                          task.category.isEmpty ? "General" : task.category),
                      _infoTile("PRIORITY", LucideIcons.circle,
                          _priorityColor(task.priority), task.priority),
                      _infoTile(
                        "DEADLINE",
                        LucideIcons.calendar,
                        Colors.redAccent,
                        task.dueDate.isEmpty ? "Not set" : _formatDate(task.dueDate),
                      ),
                      _infoTile(
                        "EVIDENCE",
                        LucideIcons.shieldCheck,
                        Colors.teal,
                        task.evidenceRequired ? "Required" : "Optional",
                      ),
                    ],
                  ),
                  if (task.tagsList.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFF1F5F9), height: 1),
                    const SizedBox(height: 16),
                    const Text(
                      "TASK TAGS",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: task.tagsList.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFBBF7D0),
                            ),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (task.description.trim().isNotEmpty) ...[
              _buildSectionCard(
                title: "DESCRIPTION",
                icon: LucideIcons.alignLeft,
                child: Text(
                  task.description.trim(),
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            _buildInvolvedPartiesCard(task),
            const SizedBox(height: 16),

            _buildMetadataCard(task),
            const SizedBox(height: 16),

            _buildSectionCard(
              title: "CHECKLIST",
              icon: LucideIcons.checkSquare,
              trailing:
                  _countBadge("$completedChecklistCount/${task.checklistItems.length}"),
              child: task.checklistItems.isEmpty
                ? Center(
                    child: const Text(
                      "NO CHECKLIST ITEMS",
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  )
                : Column(
                    children: List.generate(task.checklistItems.length, (index) {
                      final item = task.checklistItems[index];
                      final isDone = _isChecklistItemDone(item);
                      final label = _checklistItemLabel(item);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: isDoer
                              ? () => _toggleChecklistItem(task, item, index)
                              : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isDone
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  size: 18,
                                  color: isDone ? Colors.green : Colors.grey,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    label.isEmpty ? "Checklist Item" : label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: const Color(0xFF334155),
                                      decoration: isDone
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              title: "SUB TASKS",
              icon: LucideIcons.layers,
              trailing: _countBadge(
                  "$completedSubtasksCount/${task.subtasks.length}"),
              child: task.subtasks.isEmpty
                  ? const Center(
                      child: Text(
                        "NO SUB TASKS YET",
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    )
                  : Column(
                      children: task.subtasks.map((subtask) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      subtask.delegationName,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                  _statusBadge(
                                      subtask.status, _statusColor(subtask.status)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 10,
                                runSpacing: 6,
                                children: [
                                  if (subtask.dueDate.isNotEmpty)
                                    _miniMeta(
                                        LucideIcons.clock, _formatDate(subtask.dueDate)),
                                  _miniMeta(
                                    LucideIcons.user,
                                    subtask.getAssignedToName(
                                        context.read<UserProvider>().users),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 16),

            if (task.voiceNoteUrl != null ||
                attachmentUrls.isNotEmpty) ...[
              _buildSectionCard(
                title: "ATTACHMENTS",
                icon: LucideIcons.paperclip,
                child: Column(
                  children: [
                    if (task.voiceNoteUrl != null &&
                        task.voiceNoteUrl!.trim().isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.mic,
                                size: 18, color: Color(0xFF10B981)),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                "Voice Note",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  _toggleVoicePlayback(task.voiceNoteUrl!.trim()),
                              child: Text(_isPlaying ? "Pause" : "Play"),
                            ),
                            IconButton(
                              onPressed: () =>
                                  _openExternalLink(task.voiceNoteUrl!.trim()),
                              icon: const Icon(Icons.open_in_new_rounded, size: 18),
                            ),
                          ],
                        ),
                      ),
                    ...attachmentUrls.map((url) {
                      final parsed = Uri.tryParse(url);
                      final last = parsed?.pathSegments.isNotEmpty == true
                          ? parsed!.pathSegments.last
                          : url;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.fileText,
                                size: 18, color: Color(0xFF0F766E)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                last,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _openExternalLink(url),
                              icon: const Icon(Icons.open_in_new_rounded, size: 18),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            if (canAct) ...[
            const Text("QUICK ACTIONS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.5)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (isDoer)
                  _quickActionButton(
                    "IN PROGRESS",
                    LucideIcons.playCircle,
                    Colors.orange,
                    onTap: _isActionLoading
                        ? null
                        : () => _changeStatus(
                              "In Progress",
                              reason: 'Updated from task detail',
                            ),
                  ),
                if (isDoer)
                  _quickActionButton(
                    "COMPLETE",
                    LucideIcons.checkCircle,
                    Colors.green,
                    onTap: _isActionLoading
                        ? null
                        : () => _changeStatus(
                              "Completed",
                              reason: 'Completed from task detail',
                            ),
                  ),
                if (isDoer)
                  _quickActionButton(
                    "REMINDERS",
                    LucideIcons.bell,
                    Colors.blue,
                    onTap: () => _showReminderInfo(task),
                  ),
                _quickActionButton(
                  "COMMENT",
                  LucideIcons.messageCircle,
                  Colors.indigo,
                  onTap: _focusRemarkBox,
                ),
                _quickActionButton(
                  "SUB TASK",
                  LucideIcons.layers,
                  Colors.cyan,
                  onTap: task.id == null ? null : () => _openSubTaskSheet(task),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text("QUICK REMARK", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.5)),
            const SizedBox(height: 12),
            TextField(
              controller: remarkController,
              focusNode: _remarkFocusNode,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Focus on specific details or updates...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isActionLoading ? null : _submitRemark,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF20E19F),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isActionLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "SUBMIT UPDATE",
                        style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            ],

            _buildSectionCard(
              title: "REVISION HISTORY",
              icon: LucideIcons.history,
              child: task.revisionHistory.isEmpty 
                ? const Center(child: Text("NO REVISIONS YET", style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w800, fontSize: 12)))
                : Column(
                    children: task.revisionHistory.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildHistoryItem(
                        r.newStatus.isEmpty ? task.status : r.newStatus,
                        r.createdAt,
                        r.reason.isEmpty ? "Update" : r.reason,
                        _resolveUserName(r.changedBy),
                        r.oldStatus.isEmpty ? "" : "OLD: ${r.oldStatus}",
                      ),
                    )).toList(),
                  ),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: "REMARK HISTORY",
              icon: LucideIcons.messageSquare,
              child: task.remarks.isEmpty
                  ? const Center(child: Text("NO REMARKS YET", style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w800, fontSize: 12)))
                  : Column(
                      children: task.remarks.map((remark) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildHistoryItem(
                          "Remark",
                          remark.date,
                          remark.remark,
                          _resolveUserName(remark.assignedUserId),
                          "",
                        ),
                      )).toList(),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF20E19F),
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        "DELEGATION DETAIL",
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2),
      ),
    );
  }

  Widget _statusPill(String status) {
    final color = _statusColor(status);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 12, color: color),
          const SizedBox(width: 6),
          Text(status.toUpperCase(), style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w900, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child, Widget? trailing}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.5)),
              if (trailing != null) ...[const Spacer(), trailing],
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _infoTile(String label, IconData icon, Color color, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8))),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
          ],
        ),
      ],
    );
  }

  Widget _miniMeta(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionButton(String label, IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(String status, String date, String comment, String user, String oldStatus) {
    final statusColor =
        status == 'Remark' ? Colors.indigo : _statusColor(status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statusBadge(status, statusColor),
              Text(date, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(comment, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF475569))),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("BY: $user", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF64748B))),
              if (oldStatus.isNotEmpty)
                Text(oldStatus, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 9)),
    );
  }

  Widget _countBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w900, fontSize: 10)),
    );
  }

  Widget _buildInvolvedPartiesCard(DelegationModel task) {
    var users = Provider.of<UserProvider>(context, listen: false).users;
    String assignedBy = task.getAssignedByName(users);
    String assignedTo = task.getAssignedToName(users);

    List<String> inLoopNames = task.inLoopIds.map((id) {
       try {
         return users.firstWhere((u) => u.id == id).fullName.toUpperCase();
       } catch(e) {
         return "USER";
       }
    }).toList();

    return _buildSectionCard(
      title: "INVOLVED PARTIES",
      icon: LucideIcons.users,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _userRow("ASSIGNED BY", assignedBy, 'G', const Color(0xFFEEF2FF), const Color(0xFF4F46E5)),
          const SizedBox(height: 16),
          _userRow("ASSIGNED TO", assignedTo, 'S', const Color(0xFFFFFBEB), const Color(0xFFD97706)),
          if (inLoopNames.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text("IN LOOP", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: inLoopNames.map((name) => _inLoopBadge(name)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _userRow(String label, String name, String initial, Color bgColor, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
        const SizedBox(height: 8),
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: bgColor,
              child: Text(
                 name.isNotEmpty ? name[0].toUpperCase() : initial, 
                 style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)
              ),
            ),
            const SizedBox(width: 10),
            Text(name.isNotEmpty ? name : "Unknown", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
          ],
        )
      ],
    );
  }

  Widget _inLoopBadge(String name) {
     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
       decoration: BoxDecoration(
         color: Colors.white,
         borderRadius: BorderRadius.circular(20),
         border: Border.all(color: const Color(0xFFE2E8F0)),
       ),
       child: Row(
         mainAxisSize: MainAxisSize.min,
         children: [
            CircleAvatar(
              radius: 10,
              backgroundColor: const Color(0xFFEEF2FF),
              child: Text(
                 name.isNotEmpty ? name[0].toUpperCase() : 'U', 
                 style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 10)
              ),
            ),
            const SizedBox(width: 6),
            Text(name.isNotEmpty ? name : "USER", style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 10)),
         ],
       ),
     );
  }

  Widget _buildMetadataCard(DelegationModel task) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("CREATED ON", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
              Text(
                task.createdAt.isNotEmpty ? _formatDate(task.createdAt) : "N/A", 
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("DELEGATION ID", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
              Text(
                task.id != null ? "#${task.id!.substring(0, task.id!.length > 8 ? 8 : task.id!.length)}" : "N/A", 
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('dd MMM, HH:mm').format(dt);
    } catch (_) { return raw; }
  }
}
