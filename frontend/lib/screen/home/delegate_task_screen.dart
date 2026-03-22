import 'package:d_table_delegate_system/model/delegate_model.dart';
import 'package:d_table_delegate_system/model/user_model.dart';
import 'package:d_table_delegate_system/provider/auth_provider.dart';
import 'package:d_table_delegate_system/provider/delegation_provider.dart';
import 'package:d_table_delegate_system/provider/theme_provider.dart';
import 'package:d_table_delegate_system/provider/user_provider.dart';
import 'package:d_table_delegate_system/provider/category_provider.dart';
import 'package:d_table_delegate_system/provider/tag_provider.dart';
import 'package:d_table_delegate_system/screen/home/task_detail.dart';
import 'package:d_table_delegate_system/widget/assign_task_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:d_table_delegate_system/widget/app_dropdown.dart';
import 'package:d_table_delegate_system/widget/custom_date_range_picker.dart';

class DelegateTasksScreen extends StatefulWidget {
  const DelegateTasksScreen({super.key});

  @override
  State<DelegateTasksScreen> createState() => _DelegateTasksScreenState();
}

class _DelegateTasksScreenState extends State<DelegateTasksScreen> {
  final Color primaryColor = const Color(0xFF00D094);
  final TextEditingController searchController = TextEditingController();

  String searchQuery = "";
  String selectedDateRange = "All Time";
  int _viewMode = 0; // 0=list, 1=grid, 2=calendar
  String _activeStatusTab = "All";

  // Filter states
  String _assignedToFilter = "Anyone";
  String _priorityFilter = "All Priority";
  String _categoryFilter = "All Categories";
  String _tagFilter = "All Tags";
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  // Custom Slate Colors
  final Color slate50 = const Color(0xFFF8FAFC);
  final Color slate100 = const Color(0xFFF1F5F9);
  final Color slate200 = const Color(0xFFE2E8F0);
  final Color slate400 = const Color(0xFF94A3B8);
  final Color slate600 = const Color(0xFF475569);
  final Color slate800 = const Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      setState(() => searchQuery = searchController.text.toLowerCase());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final delegationProv = Provider.of<DelegationProvider>(context, listen: false);
      final userProv = Provider.of<UserProvider>(context, listen: false);
      final catProv = Provider.of<CategoryProvider>(context, listen: false);
      final tagProv = Provider.of<TagProvider>(context, listen: false);

      await delegationProv.fetchAll();
      await userProv.fetchUsers();
      await catProv.fetchCategories();
      await tagProv.fetchTags();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<DelegationModel> _applyFilters(List<DelegationModel> all, String? myId, List<UserModel> users) {
    // Debug print taaki pata chale kitne tasks aa rahe hain
    print("DEBUG: Total tasks in provider: ${all.length}");
    print("DEBUG: My User ID: $myId");

    return all.where((task) {
      // ✅ LOGIC: Delegated tasks are those where I am the delegator
      bool isDelegatedByMe = (task.delegatorId == myId);
      
      if (!isDelegatedByMe) return false;

      bool matchesSearch = searchQuery.isEmpty ||
          task.delegationName.toLowerCase().contains(searchQuery) ||
          task.description.toLowerCase().contains(searchQuery);

      bool matchesStatus = _activeStatusTab == "All" || 
          (_activeStatusTab == "OverDue" && task.status == "Overdue") ||
          task.status == _activeStatusTab;

      // Filter: Assigned To
      bool matchesAssignedTo = true;
      if (_assignedToFilter != "Anyone") {
        final doer = users.firstWhere((u) => u.id == task.assingDoerId, orElse: () => UserModel.empty());
        matchesAssignedTo = doer.fullName == _assignedToFilter;
      }

      // Filter: Priority
      bool matchesPriority = true;
      if (_priorityFilter != "All Priority") {
        matchesPriority = task.priority == _priorityFilter;
      }

      // Filter: Category
      bool matchesCategory = true;
      if (_categoryFilter != "All Categories") {
        matchesCategory = task.category == _categoryFilter;
      }

      // Filter: Tags
      bool matchesTags = true;
      if (_tagFilter != "All Tags") {
        matchesTags = task.tagsList.contains(_tagFilter);
      }

      // Filter: Date Range
      bool matchesDate = true;
      final now = DateTime.now();
      try {
        final due = DateTime.parse(task.dueDate.split('T')[0]);
        final today = DateTime(now.year, now.month, now.day);
        final taskDate = DateTime(due.year, due.month, due.day);
        
        if (selectedDateRange == "Today") {
          matchesDate = taskDate.isAtSameMomentAs(today);
        } else if (selectedDateRange == "Yesterday") {
          final yesterday = today.subtract(const Duration(days: 1));
          matchesDate = taskDate.isAtSameMomentAs(yesterday);
        } else if (selectedDateRange == "This Week") {
          final weekStart = today.subtract(Duration(days: today.weekday - 1));
          final weekEnd = weekStart.add(const Duration(days: 6));
          matchesDate = taskDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
                        taskDate.isBefore(weekEnd.add(const Duration(days: 1)));
        } else if (selectedDateRange == "Last Week") {
          final lastWeekStart = today.subtract(Duration(days: today.weekday - 1 + 7));
          final lastWeekEnd = lastWeekStart.add(const Duration(days: 6));
          matchesDate = taskDate.isAfter(lastWeekStart.subtract(const Duration(days: 1))) &&
                        taskDate.isBefore(lastWeekEnd.add(const Duration(days: 1)));
        } else if (selectedDateRange == "This Month") {
          matchesDate = taskDate.year == today.year && taskDate.month == today.month;
        } else if (selectedDateRange == "Last Month") {
          final lastMonth = today.month == 1 ? 12 : today.month - 1;
          final lastMonthYear = today.month == 1 ? today.year - 1 : today.year;
          matchesDate = taskDate.year == lastMonthYear && taskDate.month == lastMonth;
        } else if (selectedDateRange == "This Year") {
          matchesDate = taskDate.year == today.year;
        } else if (selectedDateRange == "Custom") {
          if (_customStartDate != null && _customEndDate != null) {
            final start = DateTime(_customStartDate!.year, _customStartDate!.month, _customStartDate!.day);
            final end = DateTime(_customEndDate!.year, _customEndDate!.month, _customEndDate!.day);
            matchesDate = (taskDate.isAtSameMomentAs(start) || taskDate.isAfter(start)) &&
                          (taskDate.isAtSameMomentAs(end) || taskDate.isBefore(end));
          } else {
            matchesDate = true;
          }
        }
      } catch (_) {}

      return matchesSearch && matchesStatus && matchesAssignedTo && matchesPriority && matchesCategory && matchesTags && matchesDate;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final delegationProv = Provider.of<DelegationProvider>(context);
    final userProv = Provider.of<UserProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final myId = auth.currentUser?.id;
    final filtered = _applyFilters(delegationProv.delegations, myId, userProv.users);

    // Status counts based on delegated tasks
    final delegatedByMe = delegationProv.delegations.where((t) => t.delegatorId == myId).toList();
    
    final counts = {
      "All": delegatedByMe.length,
      "OverDue": delegatedByMe.where((t) => t.status == "Overdue").length,
      "Pending": delegatedByMe.where((t) => t.status == "Pending").length,
      "In Progress": delegatedByMe.where((t) => t.status == "In Progress").length,
      "Completed": delegatedByMe.where((t) => t.status == "Completed").length,
    };

    return Scaffold(
      backgroundColor: const Color(0xFFE6F9F1),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            backgroundColor: primaryColor,
            expandedHeight: 120,
            pinned: true,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Text("DELEGATED TASKS", 
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)
              ),
              background: Container(color: primaryColor),
            ),
          ),
        ],
        body: RefreshIndicator(
          color: primaryColor,
          onRefresh: () async => await delegationProv.fetchAll(),
          child: ListView(
            padding: const EdgeInsets.only(top: 0),
            children: [
              _buildHeader(primaryColor),
              _buildQuickStats(counts),
              _buildToolbar(primaryColor),
              _buildStatusTabs(counts),

              // ── Task List / Empty ────────────────────────────────────
              delegationProv.isLoading
                  ? Center(child: CircularProgressIndicator(color: primaryColor))
                  : filtered.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.only(
                        top: 12,
                        bottom: 80,
                        left: 0,
                        right: 0,
                      ),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) => _buildTaskCard(
                        filtered[i],
                        userProv.users,
                        primaryColor,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color primary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: primary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: const Icon(Icons.outbox_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Delegated Tasks",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Tasks you've assigned to others",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            height: 40,
            child: ElevatedButton(
              onPressed: () => _showAssignBottomSheet(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Icon(Icons.add_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(Map<String, int> counts) {
    int inTime = 0; // Optional/Placeholder if not in API
    int delayed = 0; // Optional/Placeholder if not in API

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStatCard("OVERDUE", counts['OverDue'] ?? 0, Colors.red),
          const SizedBox(width: 12),
          _buildStatCard("PENDING", counts['Pending'] ?? 0, Colors.orange),
          const SizedBox(width: 12),
          _buildStatCard("IN PROGRESS", counts['In Progress'] ?? 0, Colors.blue),
          const SizedBox(width: 12),
          _buildStatCard("COMPLETED", counts['Completed'] ?? 0, Colors.green),
          const SizedBox(width: 12),
          _buildStatCard("IN TIME", inTime, Colors.teal),
          const SizedBox(width: 12),
          _buildStatCard("DELAYED", delayed, Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Container(
      width: 140, // Fixed width for horizontal scrolling
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border(bottom: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value.toString(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1E1E1E))),
        ],
      ),
    );
  }

  Widget _buildToolbar(Color primary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 150,
                height: 40,
                child: AppDropdown<String>(
                  isCompact: true,
                  value: selectedDateRange,
                  items: const [
                    "All Time", "Today", "Yesterday", "This Week",
                    "Last Week", "This Month", "Last Month", "This Year", "Custom"
                  ],
                  labelBuilder: (v) => v,
                  accentColor: primary,
                  onChanged: (v) async {
                    if (v == "Custom") {
                      final picked = await showStylishDateRangePicker(context, primary);
                      if (picked != null) {
                        setState(() {
                          _customStartDate = picked.start;
                          _customEndDate = picked.end;
                          selectedDateRange = "Custom";
                        });
                      }
                    } else {
                      setState(() {
                        selectedDateRange = v!;
                        _customStartDate = null;
                        _customEndDate = null;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: () => _showFilterDialog(false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  icon: const Icon(Icons.filter_alt_outlined, size: 16, color: Colors.white),
                  label: const Text("Filter",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 200,
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: Colors.grey.shade500, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        decoration: const InputDecoration(
                          hintText: "Search tasks...",
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                height: 40,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      searchController.clear();
                      searchQuery = "";
                      selectedDateRange = "All Time";
                      _activeStatusTab = "All";
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Icon(Icons.refresh_rounded, size: 18),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 40,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _viewToggleBtn(Icons.view_list_rounded, 0, primary),
                    _viewToggleBtn(Icons.view_module_rounded, 1, primary),
                    _viewToggleBtn(Icons.calendar_month_rounded, 2, primary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _viewToggleBtn(IconData icon, int index, Color primary) {
    bool active = _viewMode == index;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = index),
      child: Container(
        width: 32,
        height: 34,
        decoration: BoxDecoration(
          color: active ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: active ? Colors.white : Colors.grey, size: 16),
      ),
    );
  }

  Widget _buildStatusTabs(Map<String, int> counts) {
    final tabs = [
      {"key": "All", "color": Colors.grey.shade500},
      {"key": "Overdue", "color": Colors.redAccent},
      {"key": "Pending", "color": Colors.grey.shade400},
      {"key": "In Progress", "color": Colors.orangeAccent},
      {"key": "Completed", "color": const Color(0xFF10B981)},
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: tabs.map((tab) {
              final key = tab["key"] as String;
              final color = tab["color"] as Color;
              final internalKey = key == "Overdue" ? "OverDue" : key;
              final isActive = _activeStatusTab == internalKey;
              final count = counts[internalKey] ?? 0;
              final isPending = key == 'Pending';

              return GestureDetector(
                onTap: () => setState(() => _activeStatusTab = internalKey),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isActive ? const Color(0xFF00D094) : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isPending ? Colors.transparent : color,
                          border: isPending ? Border.all(color: Colors.grey.shade400, width: 2) : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${key.toUpperCase()} — $count",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: isActive ? Colors.blueGrey.shade700 : Colors.blueGrey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(DelegationModel task, List<UserModel> users, Color primary) {
    final String assignedToName = task.getAssignedToName(users);
    final String initial = assignedToName.isNotEmpty ? assignedToName[0].toUpperCase() : "U";
    final Color statusColor = _getStatusColor(task.status);
    final String timeAgo = _getTimeAgo(task.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 20, right: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => TaskDetailScreen(task: task))),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: Checkbox + Avatar + Title/To ──
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: false,
                      onChanged: (v) {},
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: primary.withOpacity(0.1),
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.delegationName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "To: $assignedToName",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.more_vert_rounded, size: 18, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 10),
              // ── Bottom row: Status + Date + Priority + Time ──
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  _statusBadge(task.status, statusColor),
                  _dateTag(task.dueDate),
                  _priorityTag(task.priority),
                  if (timeAgo.isNotEmpty)
                    Text(
                      timeAgo,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "";
    try {
      final dt = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 0) return "${diff.inDays}d ago";
      if (diff.inHours > 0) return "${diff.inHours}h ago";
      if (diff.inMinutes > 0) return "${diff.inMinutes}m ago";
      return "Just now";
    } catch (_) {
      return "";
    }
  }

  Widget _priorityTag(String priority) {
    final color = _getPriorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 5,
              height: 5,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(priority,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _dateTag(String date) {
    String display = date;
    if (date.length > 10) display = date.substring(0, 10);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_rounded, size: 12, color: Colors.grey),
          const SizedBox(width: 4),
          Text(display,
              style: const TextStyle(
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.bold,
                  fontSize: 10)),
        ],
      ),
    );
  }

  void _showFilterDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.white,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(24),
              child: Consumer3<UserProvider, CategoryProvider, TagProvider>(
                builder: (ctx, userProv, catProv, tagProv, _) {
                  final users = [
                    "Anyone",
                    ...userProv.users.map((e) => e.fullName)
                  ];
                  final priorities = ["All Priority", "High", "Medium", "Low"];
                  final categories = [
                    "All Categories",
                    ...catProv.categoryModels.map((e) => e.name)
                  ];
                  final tags = ["All Tags", ...tagProv.tags.map((e) => e.name)];

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("FILTERS",
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                  letterSpacing: 1.2)),
                          GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                _assignedToFilter = "Anyone";
                                _priorityFilter = "All Priority";
                                _categoryFilter = "All Categories";
                                _tagFilter = "All Tags";
                              });
                              setState(() {
                                _assignedToFilter = "Anyone";
                                _priorityFilter = "All Priority";
                                _categoryFilter = "All Categories";
                                _tagFilter = "All Tags";
                              });
                            },
                            child: const Text("Clear All",
                                style: TextStyle(
                                    color: Color(0xFF00D094),
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ASSIGNED TO
                      _buildFilterDropdownLabel("ASSIGNED TO"),
                      _buildFilterDropdown(
                        value: _assignedToFilter,
                        items: users,
                        onChanged: (val) {
                          setDialogState(() => _assignedToFilter = val!);
                          setState(() => _assignedToFilter = val!);
                        },
                      ),
                      const SizedBox(height: 16),

                      // PRIORITY
                      _buildFilterDropdownLabel("PRIORITY"),
                      _buildFilterDropdown(
                        value: _priorityFilter,
                        items: priorities,
                        onChanged: (val) {
                          setDialogState(() => _priorityFilter = val!);
                          setState(() => _priorityFilter = val!);
                        },
                      ),
                      const SizedBox(height: 16),

                      // CATEGORY
                      _buildFilterDropdownLabel("CATEGORY"),
                      _buildFilterDropdown(
                        value: _categoryFilter,
                        items: categories,
                        onChanged: (val) {
                          setDialogState(() => _categoryFilter = val!);
                          setState(() => _categoryFilter = val!);
                        },
                      ),
                      const SizedBox(height: 16),

                      // TAG
                      _buildFilterDropdownLabel("TAG"),
                      _buildFilterDropdown(
                        value: _tagFilter,
                        items: tags,
                        onChanged: (val) {
                          setDialogState(() => _tagFilter = val!);
                          setState(() => _tagFilter = val!);
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                },
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildFilterDropdownLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.grey,
              letterSpacing: 0.5)),
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final currentValue = items.contains(value) ? value : items.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B)),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _statusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 9)),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "Pending": return Colors.orange;
      case "Completed": return primaryColor;
      case "Overdue": return Colors.red;
      case "In Progress": return Colors.blue;
      default: return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case "High": return Colors.red;
      case "Medium": return Colors.blue;
      default: return Colors.green;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.outbox_rounded,
                      size: 56, color: Colors.grey),
                  Positioned(
                    right: 20,
                    bottom: 20,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "No Delegated Tasks",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            const Text(
              "You haven't assigned any tasks to others yet",
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AssignTaskSheet(),
    ).then((_) => Provider.of<DelegationProvider>(context, listen: false).fetchAll());
  }
}
