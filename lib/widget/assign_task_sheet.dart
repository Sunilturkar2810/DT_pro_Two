import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:d_table_delegate_system/model/delegate_model.dart';
import 'package:d_table_delegate_system/model/user_model.dart';
import 'package:d_table_delegate_system/model/tag_model.dart';
import 'package:d_table_delegate_system/provider/tag_provider.dart';
import 'package:d_table_delegate_system/provider/auth_provider.dart';
import 'package:d_table_delegate_system/provider/delegation_provider.dart';
import 'package:d_table_delegate_system/provider/theme_provider.dart';
import 'package:d_table_delegate_system/provider/user_provider.dart';
import 'package:d_table_delegate_system/provider/category_provider.dart';
import 'package:d_table_delegate_system/services/local_notification_service.dart';
import 'package:d_table_delegate_system/widget/app_dropdown.dart';

class AssignTaskSheet extends StatefulWidget {
  const AssignTaskSheet({super.key});

  @override
  State<AssignTaskSheet> createState() => _AssignTaskSheetState();
}

class _AssignTaskSheetState extends State<AssignTaskSheet>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _checklistController = TextEditingController();
  final TextEditingController _remarkController =
      TextEditingController(); // ← Remark field
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _descFocus = FocusNode();

  bool _assignMoreTask = false;
  bool _repeat = false;
  String _repeatFrequency = 'Daily';
  int _customOccurCount = 1;
  String _customOccurType = 'Week';
  List<String> _customSelectedDays = [];
  int _periodicallyDaysCount = 1;
  bool _isSubmitting = false;

  UserModel? _selectedDoer;
  DateTime? _startDate;
  DateTime? _endDate;
  String _priority = 'High';
  String _category = 'General';
  String _status = 'Pending';
  List<UserModel> _selectedInLoop = [];
  List<String> _checklist = [];
  List<TagModel> _selectedTags = [];
  bool _showChecklist = false;
  bool _requiresEvidence = false;
  String? _errorMessage;

  // ── Attachments ──
  List<PlatformFile> _attachedFiles = [];

  // ── Reminder ──
  DateTime? _reminderDateTime;

  // ── Voice Recording ──
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordedPath;
  Duration _recordDuration = Duration.zero;
  // ignore: unused_field
  DateTime? _recordStart;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const Color _primary = ThemeProvider.primaryGreen;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final catProv = Provider.of<CategoryProvider>(context, listen: false);
      if (catProv.categories.isEmpty) catProv.fetchCategories();
      final userProv = Provider.of<UserProvider>(context, listen: false);
      if (userProv.users.isEmpty) userProv.fetchUsers();
    });

    _titleFocus.addListener(() => setState(() {}));
    _descFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _checklistController.dispose();
    _remarkController.dispose();
    _titleFocus.dispose();
    _descFocus.dispose();
    _recorder.dispose();
    super.dispose();
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────
  
  void _showLinkDialog() {
    final linkController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("ADD LINK", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B), letterSpacing: 1.2)),
                    InkWell(
                      onTap: () => Navigator.pop(ctx),
                      child: Icon(Icons.close, color: Colors.blueGrey[300], size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: linkController,
                  decoration: InputDecoration(
                    hintText: 'https://...',
                    hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF10B981))),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("CANCEL", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (linkController.text.isNotEmpty) {
                          setState(() {
                            // You can add your logic to save the link here
                          });
                        }
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.save_outlined, color: Colors.white, size: 18),
                      label: const Text("ADD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }



  Color _priorityColor(String p) {
    switch (p) {
      case 'High':
        return const Color(0xFFEF4444);
      case 'Medium':
        return const Color(0xFFF59E0B);
      case 'Low':
        return const Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }

  IconData _priorityIcon(String p) {
    switch (p) {
      case 'High':
        return Icons.keyboard_double_arrow_up_rounded;
      case 'Medium':
        return Icons.drag_handle_rounded;
      case 'Low':
        return Icons.keyboard_double_arrow_down_rounded;
      default:
        return Icons.flag_rounded;
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? now) : (_endDate ?? now),
      firstDate: isStart ? now.subtract(const Duration(days: 30)) : (now),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _addChecklist() {
    final text = _checklistController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _checklist.add(text);
      _checklistController.clear();
    });
  }

  void _resetForm() {
    _titleController.clear();
    _descController.clear();
    _checklistController.clear();
    _remarkController.clear();
    setState(() {
      _selectedDoer = null;
      _selectedInLoop = [];
      _startDate = null;
      _endDate = null;
      _priority = 'High';
      _category = 'General';
      _status = 'Pending';
      _checklist = [];
      _repeat = false;
      _repeatFrequency = 'Daily';
      _showChecklist = false;
    });
  }

  Future<void> _handleAssign() async {
    print('🚀 _handleAssign TRIGGERED');
    if (_titleController.text.trim().isEmpty) {
      print('❌ ERROR: Title is empty');
      setState(() => _errorMessage = 'Task Title is required');
      _showError('Please enter a task title');
      return;
    } else {
      setState(() => _errorMessage = null);
    }
    if (_selectedDoer == null) {
      print('❌ ERROR: _selectedDoer is null');
      _showError('Please select an assignee');
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final delegationProv = Provider.of<DelegationProvider>(
      context,
      listen: false,
    );

    setState(() => _isSubmitting = true);

    // ── 1. Upload voice recording ──────────────────────────────────────────
    String? voiceNoteUrl;
    if (_recordedPath != null) {
      try {
        _showSuccess('Uploading voice note...');
        voiceNoteUrl = await delegationProv.uploadFile(
          File(_recordedPath!),
          folder: 'voice-notes',
        );
        print('✅ Voice uploaded: $voiceNoteUrl');
      } catch (e) {
        print('⚠️ Voice upload failed (continuing): $e');
        // Non-fatal — task will still be created without voice
      }
    }

    // ── 2. Upload file attachments ─────────────────────────────────────────
    List<String> refDocUrls = [];
    for (final pf in _attachedFiles) {
      if (pf.path == null) continue;
      try {
        final url = await delegationProv.uploadFile(
          File(pf.path!),
          folder: 'attachments',
        );
        refDocUrls.add(url);
        print('✅ File uploaded: $url');
      } catch (e) {
        print('⚠️ File upload failed (${pf.name}): $e');
      }
    }

    // ── 3. Build the task ──────────────────────────────────────────────────
    final task = DelegationModel(
      delegationName: _titleController.text.trim(),
      description: _descController.text.trim(),
      delegatorId: auth.currentUser!.id,
      assingDoerId: _selectedDoer!.id,
      priority: _priority,
      status: _status,
      startDate: _startDate?.toIso8601String(),
      dueDate:
          _endDate?.toIso8601String() ??
          _startDate?.toIso8601String() ??
          DateTime.now().toIso8601String(),
      category: _category,
      inLoopIds: _selectedInLoop.isNotEmpty 
          ? _selectedInLoop.map((u) => u.id).toList() 
          : [auth.currentUser!.id],
      checklistItems: _checklist
          .map((t) => {'text': t, 'status': 'Pending'})
          .toList(),
      voiceNoteUrl: voiceNoteUrl,
      referenceDocs: refDocUrls,
      reminderAt: _reminderDateTime?.toIso8601String(),
      // Recurrence
      isRecurring: _repeat,
      recurringFrequency: _repeat ? _repeatFrequency : null,
      recurringInterval: (_repeat && _repeatFrequency == 'Custom') ? _customOccurCount : null,
      recurringType: (_repeat && _repeatFrequency == 'Custom') ? _customOccurType : null,
      recurringDays: (_repeat && _repeatFrequency == 'Custom') ? _customSelectedDays : [],
      periodicallyDays: (_repeat && _repeatFrequency == 'Periodically') ? _periodicallyDaysCount : null,
    );

    final createdData = await delegationProv.createAndReturn(task);
    setState(() => _isSubmitting = false);

    if (!mounted) return;

    final success = createdData != null;

    if (success) {
      // ── 4. Agar remark likha hai toh task create hone ke baad post karo ──
      final remarkText = _remarkController.text.trim();
      if (remarkText.isNotEmpty && createdData!['id'] != null) {
        try {
          await delegationProv.postRemark(
            createdData['id'].toString(),
            remarkText,
            auth.currentUser!.id,
          );
          print('✅ Remark posted with task: $remarkText');
        } catch (e) {
          print('⚠️ Remark post failed: $e');
        }
      }

      if (_reminderDateTime != null) {
        final taskTitle = _titleController.text.trim();
        final notifId = LocalNotificationService.notifIdFromTaskId(
          taskTitle + DateTime.now().toString(),
        );
        await LocalNotificationService.scheduleReminder(
          id: notifId,
          taskTitle: taskTitle,
          scheduledTime: _reminderDateTime!,
        );
      }

      if (_assignMoreTask) {
        _resetForm();
        _showSuccess('Task assigned! Add another one.');
      } else {
        Navigator.pop(context);
        _showSuccess('Task assigned successfully!');
      }
    } else {
      _showError(delegationProv.errorMessage ?? 'Something went wrong');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Flexible(child: Text(msg)),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 150,
          left: 16,
          right: 16,
        ),
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Flexible(child: Text(msg)),
          ],
        ),
        backgroundColor: _primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 150,
          left: 16,
          right: 16,
        ),
      ),
    );
  }

  // File Attachment
  void _showAttachmentPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BottomSheetWrapper(
        title: 'Add Attachment',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _attachOption(
              icon: Icons.folder_open_rounded,
              color: const Color(0xFF6366F1),
              label: 'Browse Files',
              subtitle: 'PDF, DOC, XLS, ZIP...',
              onTap: () async {
                Navigator.pop(ctx);
                final result = await FilePicker.platform.pickFiles(
                  allowMultiple: true,
                  type: FileType.any,
                );
                if (result != null) {
                  setState(() => _attachedFiles.addAll(result.files));
                  _showSuccess(
                    result.files.length.toString() + ' file(s) attached',
                  );
                }
              },
            ),
            _attachOption(
              icon: Icons.image_rounded,
              color: const Color(0xFF3B82F6),
              label: 'Pick Image',
              subtitle: 'From gallery',
              onTap: () async {
                Navigator.pop(ctx);
                final result = await FilePicker.platform.pickFiles(
                  allowMultiple: true,
                  type: FileType.image,
                );
                if (result != null) {
                  setState(() => _attachedFiles.addAll(result.files));
                  _showSuccess(
                    result.files.length.toString() + ' image(s) attached',
                  );
                }
              },
            ),
            _attachOption(
              icon: Icons.video_library_rounded,
              color: const Color(0xFF10B981),
              label: 'Pick Video',
              subtitle: 'From gallery',
              onTap: () async {
                Navigator.pop(ctx);
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.video,
                );
                if (result != null) {
                  setState(() => _attachedFiles.addAll(result.files));
                  _showSuccess('Video attached');
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _attachOption({
    required IconData icon,
    required Color color,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
    );
  }

  Widget _buildAttachmentsRow() {
    if (_attachedFiles.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'ATTACHMENTS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.grey[500],
                letterSpacing: 0.8,
              ),
            ),
            const Spacer(),
            Text(
              _attachedFiles.length.toString() + ' file(s)',
              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _attachedFiles.map((f) {
            final isImg = [
              'jpg',
              'jpeg',
              'png',
              'gif',
              'webp',
            ].contains(f.extension?.toLowerCase() ?? '');
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF6366F1).withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isImg && f.path != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.file(
                        File(f.path!),
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Icon(
                      _fileIcon(f.extension ?? ''),
                      size: 18,
                      color: const Color(0xFF6366F1),
                    ),
                  const SizedBox(width: 7),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 110),
                    child: Text(
                      f.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => setState(() => _attachedFiles.remove(f)),
                    child: Icon(
                      Icons.cancel,
                      size: 15,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _fileIcon(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'zip':
      case 'rar':
        return Icons.folder_zip_rounded;
      case 'mp4':
      case 'mov':
        return Icons.video_file_rounded;
      case 'mp3':
      case 'wav':
      case 'm4a':
        return Icons.audio_file_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  // Reminder
  Future<void> _showReminderPicker() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderDateTime ?? now,
      firstDate: now,
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reminderDateTime ?? now),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (time == null) return;
    setState(() {
      _reminderDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
    _showSuccess(
      'Reminder set for ' +
          DateFormat('dd MMM, hh:mm a').format(_reminderDateTime!),
    );
  }

  Widget _buildReminderChip() {
    if (_reminderDateTime == null) return const SizedBox.shrink();
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.alarm_on_rounded,
                size: 18,
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reminder Set',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                  Text(
                    DateFormat(
                      'EEE, dd MMM yyyy hh:mm a',
                    ).format(_reminderDateTime!),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1D23),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _reminderDateTime = null),
                child: Icon(Icons.cancel, size: 18, color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Voice Recording
  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) _showError('Microphone permission denied');
      return;
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
      path: path,
    );
    setState(() {
      _isRecording = true;
      _recordedPath = null;
      _recordDuration = Duration.zero;
      _recordStart = DateTime.now();
    });
    _tickRecording();
  }

  void _tickRecording() async {
    if (!_isRecording) return;
    await Future.delayed(const Duration(seconds: 1));
    if (!_isRecording || !mounted) return;
    setState(() => _recordDuration += const Duration(seconds: 1));
    _tickRecording();
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    setState(() {
      _isRecording = false;
      _recordedPath = path;
    });
    if (path != null) _showSuccess('Voice note recorded!');
  }

  void _discardRecording() {
    if (_recordedPath != null) {
      try {
        File(_recordedPath!).deleteSync();
      } catch (_) {}
    }
    setState(() {
      _recordedPath = null;
      _recordDuration = Duration.zero;
    });
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return m + ':' + s;
  }

  Widget _buildRecordingBar() {
    if (!_isRecording && _recordedPath == null) return const SizedBox.shrink();
    final isRec = _isRecording;
    final recColor = isRec ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
    return Column(
      children: [
        const SizedBox(height: 16),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: recColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: recColor.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: recColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isRec ? Icons.mic_rounded : Icons.mic_none_rounded,
                  color: recColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRec ? 'Recording...' : 'Voice Note',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: recColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isRec)
                      _buildWaveform()
                    else
                      Text(
                        'Duration: ' + _formatDuration(_recordDuration),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDuration(_recordDuration),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isRec ? const Color(0xFFEF4444) : Colors.grey[700],
                ),
              ),
              const SizedBox(width: 10),
              if (isRec)
                GestureDetector(
                  onTap: _stopRecording,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.stop_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    GestureDetector(
                      onTap: _startRecording,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.replay_rounded,
                          size: 16,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: _discardRecording,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWaveform() {
    final heights = [
      6.0,
      10.0,
      16.0,
      8.0,
      14.0,
      20.0,
      10.0,
      6.0,
      18.0,
      12.0,
      8.0,
      16.0,
      6.0,
      10.0,
      14.0,
      8.0,
      12.0,
      6.0,
    ];
    return SizedBox(
      height: 22,
      child: Row(
        children: List.generate(
          18,
          (i) => AnimatedContainer(
            duration: Duration(milliseconds: 200 + i * 30),
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            width: 3,
            height: _isRecording
                ? (heights[i % heights.length] +
                      (_recordDuration.inSeconds % 2 == 0 ? 3.0 : 0.0))
                : 4,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.5 + (i % 3) * 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  // --- Web-Matched UI --------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        constraints: BoxConstraints(maxHeight: size.height * 0.80),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _buildWebHeader(),
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(left: 16, right: 16, top: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Color(0xFFEF4444),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleField(),
                      const SizedBox(height: 10),
                      _buildDescField(),
                      const SizedBox(height: 20),

                      // ADD CHECKLIST
                      GestureDetector(
                        onTap: () =>
                            setState(() => _showChecklist = !_showChecklist),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.add,
                              color: Color(0xFF10B981),
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              "ADD CHECKLIST",
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              _showChecklist
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                      if (_showChecklist) ...[
                        const SizedBox(height: 16),
                        _buildChecklistSection(),
                      ],
                      const SizedBox(height: 24),

                      // ROW OF CHIPS
                      _buildWebChipsRow(),

                      const SizedBox(height: 24),
                      _buildRepeatSection(),

                      const SizedBox(height: 24),
                      if (_attachedFiles.isNotEmpty) _buildAttachmentsRow(),
                      if (_reminderDateTime != null) _buildReminderChip(),
                      if (_isRecording || _recordedPath != null)
                        _buildRecordingBar(),

                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ),
            _buildWebFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildWebHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF0FDF4),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Assign New Task",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                "NEW DELEGATION",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: Color(0xFF10B981),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      focusNode: _titleFocus,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1E293B),
      ),
      decoration: InputDecoration(
        hintText: "Task Title",
        hintStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Colors.blueGrey[300],
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        isDense: true,
      ),
    );
  }

  Widget _buildDescField() {
    return TextFormField(
      controller: _descController,
      focusNode: _descFocus,
      minLines: 4,
      maxLines: 10,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF334155),
        height: 1.5,
      ),
      decoration: InputDecoration(
        hintText: "Add description or instructions here...",
        hintStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Colors.blueGrey[300],
          height: 1.5,
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        isDense: true,
      ),
    );
  }

  Widget _buildChecklistSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _checklistController,
                decoration: InputDecoration(
                  hintText: 'Add an item...',
                  hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF10B981)),
                  ),
                ),
                onFieldSubmitted: (v) {
                  if (v.trim().isNotEmpty) {
                    setState(() {
                      _checklist.add(v.trim());
                      _checklistController.clear();
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                if (_checklistController.text.trim().isNotEmpty) {
                  setState(() {
                    _checklist.add(_checklistController.text.trim());
                    _checklistController.clear();
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
        if (_checklist.isNotEmpty) const SizedBox(height: 12),
        ..._checklist.asMap().entries.map((e) {
          int idx = e.key;
          String item = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                const Icon(
                  Icons.check_box_outline_blank,
                  color: Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.redAccent,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() => _checklist.removeAt(idx)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildWebChipsRow() {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final userProv = Provider.of<UserProvider>(context, listen: false);
    final currentUser = authProv.currentUser;

    List<UserModel> allowedUsers = userProv.users;
    if (currentUser != null && !authProv.isAdmin) {
      if (authProv.currentUser?.role?.toLowerCase() == 'manager') {
        allowedUsers = userProv.users
            .where(
              (u) =>
                  u.role.toLowerCase() == 'manager' ||
                  u.role.toLowerCase() == 'user' ||
                  u.id == currentUser.id,
            )
            .toList();
      } else {
        allowedUsers = userProv.users
            .where(
              (u) => u.role.toLowerCase() == 'user' || u.id == currentUser.id,
            )
            .toList();
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildWebChip(
            icon: Icons.person_outline,
            label: _selectedDoer != null ? "ASSIGNEE" : "ASSIGNEE",
            value: _selectedDoer?.fullName,
            onTap: () => _showUserPicker(allowedUsers, isInLoop: false),
          ),
          _buildWebChip(
            icon: Icons.calendar_today_outlined,
            label: "DUE DATE",
            value: _endDate != null
                ? DateFormat('MMM dd').format(_endDate!)
                : null,
            onTap: () => _pickDate(false),
          ),
          _buildWebChip(
            icon: Icons.flag_outlined,
            label: _priority.toUpperCase(),
            isFilled: true,
            color: _priorityColor(_priority),
            onTap: () => _showPriorityPicker(),
          ),
          _buildWebChip(
            icon: Icons.check_box_outlined,
            label: "CATEGORY",
            value: _category,
            onTap: () => _showCategoryPicker(),
          ),
          _buildWebChip(
            icon: Icons.group_outlined,
            label: "IN LOOP",
            value: _selectedInLoop.isNotEmpty ? "\ Added" : null,
            onTap: () => _showUserPicker(allowedUsers, isInLoop: true),
          ),
          _buildWebChip(
            icon: _requiresEvidence ? Icons.check_circle : Icons.upload_file,
            label: "EVIDENCE",
            isFilled: _requiresEvidence,
            color: const Color(0xFF10B981),
            onTap: () => setState(() => _requiresEvidence = !_requiresEvidence),
          ),
        ],
      ),
    );
  }

  Widget _buildWebChip({
    required IconData icon,
    required String label,
    String? value,
    bool isFilled = false,
    Color? color,
    VoidCallback? onTap,
  }) {
    Color baseColor = color ?? Colors.grey[700]!;
    bool hasValue = value != null && value.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isFilled ? baseColor.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isFilled || hasValue ? baseColor : Colors.grey[300]!,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isFilled || hasValue ? baseColor : Colors.grey[500],
            ),
            const SizedBox(width: 6),
            if (hasValue)
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: baseColor,
                ),
              )
            else
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isFilled ? baseColor : Colors.grey[600],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepeatSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            GestureDetector(
              onTap: () {
                setState(() => _repeat = !_repeat);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _repeat ? Icons.check_circle : Icons.radio_button_off,
                    color: _repeat ? const Color(0xFF10B981) : Colors.grey[400],
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "REPEAT",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _repeat ? const Color(0xFF10B981) : Colors.blueGrey[400],
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            if (_repeat) ...[
              AppDropdown<String>(
                value: _repeatFrequency,
                items: const ['Daily', 'Weekly', 'Monthly', 'Yearly', 'Periodically', 'Custom'],
                labelBuilder: (v) => v.toUpperCase(),
                onChanged: (v) {
                  if (v != null) setState(() => _repeatFrequency = v);
                },
                isCompact: true,
                accentColor: const Color(0xFF334155),
              ),
              _buildDatePill(
                icon: Icons.calendar_today_outlined,
                text: _startDate != null ? DateFormat('MMM dd, yyyy').format(_startDate!) : "START DATE",
                onTap: () => _pickDate(true),
              ),
              _buildDatePill(
                icon: Icons.calendar_today_outlined,
                text: _endDate != null ? DateFormat('MMM dd, yyyy').format(_endDate!) : "END DATE",
                onTap: () => _pickDate(false),
              ),
            ]
          ],
        ),
        if (_repeat && _repeatFrequency == 'Custom') ...[
          const SizedBox(height: 16),
          _buildCustomRepeatSection(),
        ],
        if (_repeat && _repeatFrequency == 'Periodically') ...[
          const SizedBox(height: 16),
          Divider(color: Colors.grey[100], thickness: 1.5),
          const SizedBox(height: 16),
          _buildPeriodicallySection(),
        ]
      ],
    );
  }

  Widget _buildPeriodicallySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "REPEAT EVERY",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.blueGrey[400],
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5), width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "$_periodicallyDaysCount",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() => _periodicallyDaysCount++);
                      },
                      child: const Icon(Icons.arrow_drop_up, size: 18, color: Colors.grey),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (_periodicallyDaysCount > 1) {
                          setState(() => _periodicallyDaysCount--);
                        }
                      },
                      child: const Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                const Text(
                  "DAYS",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF10B981),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDatePill({required IconData icon, required String text, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[200]!, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.blueGrey[300]),
            const SizedBox(width: 8),
            Text(
              text.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.blueGrey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomRepeatSection() {
    List<String> days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              Text(
                "OCCUR EVERY",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.blueGrey[400],
                  letterSpacing: 1.2,
                ),
              ),
              AppDropdown<int>(
                value: _customOccurCount,
                items: List.generate(30, (i) => i + 1),
                labelBuilder: (v) => v.toString(),
                onChanged: (v) {
                  if (v != null) setState(() => _customOccurCount = v);
                },
                isCompact: true,
                accentColor: const Color(0xFF334155),
              ),
              AppDropdown<String>(
                value: _customOccurType,
                items: const ['Day', 'Week', 'Month', 'Year'],
                labelBuilder: (v) => v,
                onChanged: (v) {
                  if (v != null) setState(() => _customOccurType = v);
                },
                isCompact: true,
                accentColor: const Color(0xFF334155),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            "SELECT DAYS :",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.blueGrey[400],
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: days.map((day) {
              final isSelected = _customSelectedDays.contains(day);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _customSelectedDays.remove(day);
                    } else {
                      _customSelectedDays.add(day);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF334155) : Colors.white,
                    border: Border.all(color: isSelected ? const Color(0xFF334155) : Colors.grey[200]!, width: 1.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : Colors.blueGrey[400],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWebFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildFooterIconBtn(
            icon: Icons.attach_file,
            color: Colors.grey[600]!,
            onTap: _showAttachmentPicker,
            badge: _attachedFiles.isNotEmpty
                ? _attachedFiles.length.toString()
                : null,
          ),
          const SizedBox(width: 4),
          _buildFooterIconBtn(
            icon: Icons.access_time,
            color: _reminderDateTime != null
                ? const Color(0xFF10B981)
                : Colors.grey[600]!,
            onTap: _showReminderPicker,
            badge: _reminderDateTime != null ? "?" : null,
          ),
          const SizedBox(width: 4),
          _buildFooterIconBtn(
            icon: _isRecording ? Icons.stop_circle : Icons.mic_none,
            color: _isRecording
                ? Colors.red
                : (_recordedPath != null
                      ? const Color(0xFF10B981)
                      : Colors.grey[600]!),
            onTap: _isRecording ? _stopRecording : _startRecording,
          ),
          const SizedBox(width: 4),
          _buildFooterIconBtn(
            icon: Icons.more_horiz,
            color: Colors.grey[600]!,
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (ctx) => Container(
                  margin: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 80,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 10),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "EXTRA OPTIONS",
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.blueGrey[300], size: 20),
                              onPressed: () => Navigator.pop(ctx),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      _extraOptionItem(Icons.link, "Add Link", () {
                        Navigator.pop(ctx);
                        _showLinkDialog();
                      }),
                      _extraOptionItem(Icons.attach_file, "Add Attachment", () {
                        Navigator.pop(ctx);
                        _showAttachmentPicker();
                      }),
                      _extraOptionItem(
                        Icons.image_outlined,
                        "Upload Image",
                        () {
                          Navigator.pop(ctx);
                        },
                      ),
                      _extraOptionItem(
                        Icons.local_offer_outlined,
                        "Add Tags",
                        () {
                          Navigator.pop(ctx);
                          _showTagsDialog();
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              );
            },
          ),
          const Spacer(),
          Flexible(
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleAssign,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: const Size(double.infinity, 44),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "ASSIGN TASK",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterIconBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            if (badge != null)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 7,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _extraOptionItem(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.blueGrey[300]),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTagsDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return Container(
                width: 400,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "TASK TAGS",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF1E293B),
                            letterSpacing: 1.2,
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(ctx),
                          child: Icon(
                            Icons.close,
                            color: Colors.blueGrey[300],
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 16),

                    Consumer<TagProvider>(
                      builder: (context, tagProv, _) {
                        if (tagProv.isLoading)
                          return const Center(
                            child: CircularProgressIndicator(),
                          );

                        final allTags = tagProv.tags;
                        if (allTags.isEmpty)
                          return const Text(
                            "No tags available",
                            style: TextStyle(color: Colors.grey),
                          );

                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: allTags.map((tag) {
                            final isSelected = _selectedTags.any(
                              (t) => t.id == tag.id,
                            );
                            return InkWell(
                              onTap: () {
                                setDialogState(() {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedTags.removeWhere(
                                        (t) => t.id == tag.id,
                                      );
                                    } else {
                                      _selectedTags.add(tag);
                                    }
                                  });
                                });
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.blueGrey[50]
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.blueGrey[300]!
                                        : Colors.grey[200]!,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.local_offer_outlined,
                                      size: 14,
                                      color: isSelected
                                          ? Colors.blueGrey[700]
                                          : Colors.blueGrey[400],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      tag.name.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? Colors.blueGrey[700]
                                            : Colors.blueGrey[400],
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),

                    const SizedBox(height: 48),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            "CANCEL",
                            style: TextStyle(
                              color: Colors.blueGrey,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _showCreateTagDialog,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFF10B981),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          icon: const Icon(
                            Icons.add,
                            color: Color(0xFF10B981),
                            size: 18,
                          ),
                          label: const Text(
                            "ADD MORE",
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF97316),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(
                            Icons.save_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: const Text(
                            "DONE",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showCreateTagDialog() {
    final nameController = TextEditingController();
    final List<String> colors = [
      '#EF4444', '#F97316', '#F59E0B', '#10B981', '#3B82F6', '#6366F1', '#8B5CF6', '#EC4899', '#64748B'
    ];
    String selectedColor = colors.first;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 350,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "CREATE NEW TAG",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(ctx),
                          child: Icon(Icons.close, color: Colors.blueGrey[300], size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: "Tag Name",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color(0xFF10B981)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: colors.map((c) {
                        final isSelected = selectedColor == c;
                        return InkWell(
                          onTap: () => setDialogState(() => selectedColor = c),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Color(int.parse(c.replaceAll('#', '0xFF'))),
                              shape: BoxShape.circle,
                              border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
                            ),
                            child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.trim().isEmpty) return;
                          
                          final auth = Provider.of<AuthProvider>(context, listen: false);
                          final tagProv = Provider.of<TagProvider>(context, listen: false);
                          
                          final success = await tagProv.createTag(
                            name: nameController.text.trim(),
                            color: selectedColor,
                            auth: auth,
                          );
                          
                          if (success) {
                            Navigator.pop(ctx);
                          } else {
                            if (tagProv.errorMessage != null && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(tagProv.errorMessage!)),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text("SAVE TAG", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPriorityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BottomSheetWrapper(
        title: 'Set Priority',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['High', 'Medium', 'Low'].map((p) {
            final isSelected = _priority == p;
            return ListTile(
              onTap: () {
                setState(() => _priority = p);
                Navigator.pop(ctx);
              },
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _priorityColor(p).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _priorityIcon(p),
                  size: 18,
                  color: _priorityColor(p),
                ),
              ),
              title: Text(
                p,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
              trailing: isSelected
                  ? Icon(Icons.check_circle_rounded, color: _priorityColor(p))
                  : null,
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer<CategoryProvider>(
        builder: (_, catProv, __) {
          final cats = catProv.categories.isNotEmpty
              ? catProv.categories.map((c) => c['name'] as String).toList()
              : ['General', 'Urgent', 'Maintenance', 'Sales', 'Support'];
          return _BottomSheetWrapper(
            title: 'Select Category',
            child: catProv.isLoading
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cats.length,
                    itemBuilder: (_, i) {
                      final isSelected = _category == cats[i];
                      return ListTile(
                        dense: true,
                        onTap: () {
                          setState(() => _category = cats[i]);
                          Navigator.pop(ctx);
                        },
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF20E19F,
                            ).withOpacity(0.1), // Toolbar color logic here
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.category_rounded,
                            size: 16,
                            color: Color(0xFF20E19F),
                          ), // Toolbar color logic here
                        ),
                        title: Text(
                          cats[i],
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF20E19F),
                              ) // Toolbar color logic here
                            : null,
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  void _showUserPicker(List<UserModel> users, {required bool isInLoop}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return _BottomSheetWrapper(
            title: isInLoop ? 'Add In Loop' : 'Assign To',
            child: users.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        'No users found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.45,
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: users.length,
                          itemBuilder: (_, idx) {
                            final user = users[idx];
                            final isSelected = isInLoop
                                ? _selectedInLoop.contains(user)
                                : _selectedDoer == user;
                            final color = isInLoop
                                ? const Color(0xFF6366F1)
                                : _primary;
                            return ListTile(
                              onTap: () {
                                if (isInLoop) {
                                  setModalState(() {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedInLoop.remove(user);
                                      } else {
                                        _selectedInLoop.add(user);
                                      }
                                    });
                                  });
                                } else {
                                  setState(() => _selectedDoer = user);
                                  Navigator.pop(ctx);
                                }
                              },
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundColor: color.withOpacity(0.12),
                                child: Text(
                                  user.fullName[0].toUpperCase(),
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              title: Text(
                                user.fullName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                user.designation.isNotEmpty
                                    ? user.designation
                                    : user.workEmail,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                              trailing: isSelected
                                  ? Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.check_rounded,
                                        size: 16,
                                        color: color,
                                      ),
                                    )
                                  : null,
                            );
                          },
                        ),
                      ),
                      if (isInLoop) ...[
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Done (${_selectedInLoop.length} selected)',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          );
        },
      ),
    );
  }
}

// ─── Reusable Bottom Sheet Wrapper ────────────────────────────────────────────

class _BottomSheetWrapper extends StatelessWidget {
  final String title;
  final Widget child;

  const _BottomSheetWrapper({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1D23),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey[100], height: 20),
          child,
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 12),
        ],
      ),
    );
  }
}
