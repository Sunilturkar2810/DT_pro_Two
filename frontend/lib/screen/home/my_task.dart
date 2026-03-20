import 'package:d_table_delegate_system/model/delegate_model.dart';
import 'package:d_table_delegate_system/model/user_model.dart';
import 'package:d_table_delegate_system/provider/auth_provider.dart';
import 'package:d_table_delegate_system/provider/delegation_provider.dart';
import 'package:d_table_delegate_system/provider/theme_provider.dart';
import 'package:d_table_delegate_system/provider/user_provider.dart';
import 'package:d_table_delegate_system/provider/category_provider.dart';
import 'package:d_table_delegate_system/provider/tag_provider.dart';
import 'package:d_table_delegate_system/screen/home/task_detail.dart';
import 'package:d_table_delegate_system/widget/app_dropdown.dart';
import 'package:d_table_delegate_system/widget/assign_task_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MyTaskScreen extends StatefulWidget {
  final String title;
  final Color themeColor;

  const MyTaskScreen({
    super.key,
    required this.title,
    this.themeColor = const Color(0xFF20E19F),
  });

  @override
  State<MyTaskScreen> createState() => _MyTaskScreenState();
}

class _MyTaskScreenState extends State<MyTaskScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController searchController = TextEditingController();

  String searchQuery = "";
  String selectedDateRange = "All Time";
  String selectedSortBy = "Target Date";
  bool parentTasksOnly = false;
  int _viewMode = 0; // 0=list, 1=grid, 2=calendar
  String _activeStatusTab = "All";

  // Filter states
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  String _assignedByFilter = "Anyone";
  String _priorityFilter = "All Priority";
  String _categoryFilter = "All Categories";
  String _tagFilter = "All Tags";

  // Status tabs with config
  final List<Map<String, dynamic>> _statusTabs = [
    {"label": "All", "color": Colors.blueGrey, "icon": null, "filled": true},
    {"label": "OverDue", "color": Colors.red, "icon": null, "filled": true},
    {"label": "Pending", "color": Colors.orange, "icon": null, "filled": false},
    {"label": "In Progress", "color": Colors.orange, "icon": null, "filled": true},
    {"label": "Completed", "color": const Color(0xFF20E19F), "icon": Icons.check_circle_rounded, "filled": true},
  ];

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text.toLowerCase();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Provider.of<DelegationProvider>(context, listen: false).fetchAll();
      Provider.of<UserProvider>(context, listen: false).fetchUsers();
      Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
      Provider.of<TagProvider>(context, listen: false).fetchTags();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<DelegationModel> _applyFilters(
      List<DelegationModel> all, String? myId, List<UserModel> users) {
    // MY TASKS = sirf wo tasks jo MUJHE assign kiye gaye hain
    return all.where((task) {
      if (task.assingDoerId != myId) return false;

      bool matchesSearch = searchQuery.isEmpty ||
          task.delegationName.toLowerCase().contains(searchQuery) ||
          task.description.toLowerCase().contains(searchQuery);

      bool matchesStatus =
          _activeStatusTab == "All" || task.status == _activeStatusTab;

      // Filter: Assigned By
      bool matchesAssignedBy = true;
      if (_assignedByFilter != "Anyone") {
        final assigner = users.firstWhere((u) => u.id == task.delegatorId, orElse: () => UserModel.empty());
        matchesAssignedBy = assigner.fullName == _assignedByFilter;
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

      return matchesSearch && matchesStatus && matchesDate && matchesAssignedBy && matchesPriority && matchesCategory && matchesTags;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final delegationProv = Provider.of<DelegationProvider>(context);
    final userProv = Provider.of<UserProvider>(context);
    final appColors = Theme.of(context).extension<AppColors>()!;
    final primary = ThemeProvider.primaryGreen;

    final myId = auth.currentUser?.id;
    final filtered = _applyFilters(delegationProv.delegations, myId, userProv.users);

    // Status counts — sirf mujhe assign kiye gaye tasks
    final myTasks = delegationProv.delegations.where((t) => t.assingDoerId == myId).toList();

    int overdueCount = myTasks.where((t) => t.status == "Overdue").length;
    int pendingCount = myTasks.where((t) => t.status == "Pending").length;
    int inProgressCount = myTasks.where((t) => t.status == "In Progress").length;
    int completedCount = myTasks.where((t) => t.status == "Completed").length;
    int allCount = myTasks.length;

    final counts = {
      "All": allCount,
      "OverDue": overdueCount,
      "Pending": pendingCount,
      "In Progress": inProgressCount,
      "Completed": completedCount,
    };

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            backgroundColor: primary,
            expandedHeight: 120,
            pinned: true,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(widget.title.toUpperCase(), 
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)
              ),
              background: Container(color: primary),
            ),
          ),
        ],
        body: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                color: primary,
                onRefresh: () async => await delegationProv.fetchAll(),
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: primary.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                                child: Icon(Icons.task_alt_rounded, color: primary, size: 28),
                              ),
                              const SizedBox(width: 15),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("My Tasks", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: appColors.textPrimary)),
                                  Text("Tasks assigned to you", style: TextStyle(fontSize: 13, color: appColors.textMuted)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),
                          _buildSummaryRow(counts, appColors),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    _buildTopToolbar(appColors, primary),
                    _buildSecondaryToolbar(appColors, primary),
                    _buildStatusTabs(appColors, primary, counts),
                    const SizedBox(height: 10),
                    if (delegationProv.isLoading)
                      const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
                    else if (filtered.isEmpty)
                      _buildEmptyState(appColors)
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) => _buildTaskCard(filtered[i], userProv.users, myId, appColors, primary),
                      ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(Map<String, int> counts, AppColors appColors) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _statCard("TOTAL", counts["All"] ?? 0, Colors.blueGrey, Icons.list_rounded, appColors),
          _statCard("OVERDUE", counts["OverDue"] ?? 0, Colors.red, Icons.timer_outlined, appColors),
          _statCard("PENDING", counts["Pending"] ?? 0, Colors.orange, Icons.pending_actions_rounded, appColors),
          _statCard("IN PROGRESS", counts["In Progress"] ?? 0, Colors.blue, Icons.sync_rounded, appColors),
          _statCard("COMPLETED", counts["Completed"] ?? 0, ThemeProvider.primaryGreen, Icons.check_circle_outline_rounded, appColors),
        ],
      ),
    );
  }

  Widget _statCard(String label, int count, Color color, IconData icon, AppColors appColors) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: appColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: appColors.shadowColor, blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Icon(icon, color: color, size: 18),
               Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            ],
          ),
          const SizedBox(height: 12),
          Text("$count", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: appColors.textPrimary)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: appColors.textMuted, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // TOOLBAR ROW 1
  // ─────────────────────────────────────────────────────────────────
  Widget _buildTopToolbar(AppColors appColors, Color primary) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: appColors.toolbarBackground,
        boxShadow: [BoxShadow(color: appColors.shadowColor, blurRadius: 3)],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            // Assign Task
            _greenBtn(
              icon: Icons.add_task_rounded,
              label: "Assign Task",
              color: primary,
              onTap: () => _showAssignBottomSheet(context),
            ),
            const SizedBox(width: 8),

            AppDropdown<String>(
              isCompact: true,
              value: selectedDateRange,
              items: const [
                "All Time", 
                "Today", 
                "Yesterday", 
                "This Week", 
                "Last Week", 
                "This Month", 
                "Last Month", 
                "This Year", 
                "Custom"
              ],
              labelBuilder: (v) => v,
              prefixIcon: Icons.date_range_rounded,
              accentColor: ThemeProvider.primaryGreen,
              onChanged: (v) async {
                if (v == "Custom") {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: ThemeProvider.primaryGreen,
                            onPrimary: Colors.white,
                            onSurface: const Color(0xFF1A1D23),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
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
            const SizedBox(width: 8),

            // Filter button
            _greenBtn(
              icon: Icons.filter_list_rounded,
              label: "Filter",
              color: const Color(0xFF1A1D23),
              onTap: () => _showFilterDialog(appColors, primary),
            ),
            const SizedBox(width: 8),

            // Saved Filters button
            _greenBtn(
              icon: Icons.bookmark_rounded,
              label: "Saved Filters",
              color: primary,
              onTap: () {},
            ),
            const SizedBox(width: 8),

            // Search
            _searchBar(appColors),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // TOOLBAR ROW 2
  // ─────────────────────────────────────────────────────────────────
  Widget _buildSecondaryToolbar(AppColors appColors, Color primary) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      color: appColors.toolbarBackground,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            // View toggle: list / grid / calendar
            _viewToggle(appColors, primary),
            const SizedBox(width: 12),

            // Sort By label + dropdown
            Text("Sort By",
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: appColors.textMuted)),
            const SizedBox(width: 6),
            AppDropdown<String>(
              isCompact: true,
              value: selectedSortBy,
              items: const ["Target Date", "Priority", "Status", "Created Date"],
              labelBuilder: (v) => v,
              accentColor: ThemeProvider.primaryGreen,
              onChanged: (v) => setState(() => selectedSortBy = v!),
            ),
            const SizedBox(width: 6),

            // Sort direction toggle
            _iconBtn(
              icon: Icons.swap_vert_rounded,
              appColors: appColors,
              onTap: () {},
            ),
            const SizedBox(width: 16),

            // Parent Tasks toggle
            Text("Parent Tasks",
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: appColors.textMuted)),
            const SizedBox(width: 6),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: parentTasksOnly,
                activeColor: ThemeProvider.primaryGreen,
                onChanged: (v) => setState(() => parentTasksOnly = v),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // STATUS TABS (like screenshot)
  // ─────────────────────────────────────────────────────────────────
  Widget _buildStatusTabs(
      AppColors appColors, Color primary, Map<String, int> counts) {
    final tabs = [
      {"key": "All", "color": Colors.blueGrey as Color, "filled": true, "useCheck": false},
      {"key": "OverDue", "color": Colors.red as Color, "filled": true, "useCheck": false},
      {"key": "Pending", "color": Colors.orange as Color, "filled": false, "useCheck": false},
      {"key": "In Progress", "color": Colors.orange as Color, "filled": true, "useCheck": false},
      {"key": "Completed", "color": primary, "filled": true, "useCheck": true},
    ];

    return Container(
      color: appColors.toolbarBackground,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: tabs.map((tab) {
            final key = tab["key"] as String;
            final color = tab["color"] as Color;
            final filled = tab["filled"] as bool;
            final useCheck = tab["useCheck"] as bool;
            final isActive = _activeStatusTab == key;
            final count = counts[key] ?? 0;

            return GestureDetector(
              onTap: () => setState(() => _activeStatusTab = key),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? primary : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dot / check icon
                    if (useCheck)
                      Icon(Icons.check_circle_rounded,
                          size: 14, color: color)
                    else
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled ? color : Colors.transparent,
                          border: Border.all(color: color, width: 2),
                        ),
                      ),
                    const SizedBox(width: 6),
                    Text(
                      "$key - $count",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isActive
                            ? appColors.textPrimary
                            : appColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // TASK CARD
  // ─────────────────────────────────────────────────────────────────
  Widget _buildTaskCard(DelegationModel task, List<UserModel> users,
      String? myId, AppColors appColors, Color primary) {
    final String delegatorName = task.getAssignedByName(users);
    final String initial = delegatorName.isNotEmpty ? delegatorName[0].toUpperCase() : "U";
    final Color statusColor = _getStatusColor(task.status);
    final String timeAgo = _getTimeAgo(task.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: appColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: appColors.shadowColor, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task, allowEdit: true))),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  // Checkbox
                  SizedBox(
                    width: 24, height: 24,
                    child: Checkbox(value: false, onChanged: (v){}, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
                  ),
                  const SizedBox(width: 12),
                  
                  // Avatar
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: primary.withOpacity(0.1),
                    child: Text(initial, style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(width: 12),

                  // Title & Delegator
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 13, color: appColors.textPrimary),
                            children: [
                              TextSpan(text: "From: ${delegatorName.toLowerCase()} ", style: TextStyle(color: appColors.textMuted, fontSize: 11)),
                              TextSpan(text: task.delegationName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Status Badge
                  _statusBadge(task.status, statusColor),
                ],
              ),
              const SizedBox(height: 12),
              
              // Footer row
              Row(
                children: [
                  const SizedBox(width: 88), // Align with title
                  Icon(Icons.calendar_month_outlined, size: 14, color: Colors.blueAccent),
                  const SizedBox(width: 4),
                  Text(_formatDate(task.dueDate), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: appColors.textSecondary)),
                  const SizedBox(width: 12),
                  Container(width: 4, height: 4, decoration: BoxDecoration(color: appColors.textMuted.withOpacity(0.3), shape: BoxShape.circle)),
                  const SizedBox(width: 12),
                  Text(task.priority, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getPriorityColor(task.priority))),
                  const SizedBox(width: 12),
                  Container(width: 4, height: 4, decoration: BoxDecoration(color: appColors.textMuted.withOpacity(0.3), shape: BoxShape.circle)),
                  const SizedBox(width: 12),
                  Text(timeAgo, style: TextStyle(fontSize: 10, color: appColors.textMuted)),
                  const Spacer(),
                  Icon(Icons.more_vert_rounded, size: 18, color: appColors.textMuted),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String date) {
    if (date.isEmpty) return "N/A";
    try {
      final dt = DateTime.parse(date);
      final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      return "${dt.day} ${months[dt.month - 1]}";
    } catch (_) {
      return date.split('T')[0];
    }
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

  // ─────────────────────────────────────────────────────────────────
  // EMPTY STATE (matches screenshot style)
  // ─────────────────────────────────────────────────────────────────
  Widget _buildEmptyState(AppColors appColors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration placeholder
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: appColors.inputBackground,
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.assignment_outlined,
                      size: 56, color: appColors.cardBorder),
                  Positioned(
                    right: 20,
                    bottom: 20,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "No Tasks Here",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: appColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              "It seems that you don't have any tasks in this list",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: appColors.textMuted,
                  height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // HELPER WIDGETS
  // ─────────────────────────────────────────────────────────────────

  Widget _greenBtn(
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // ─── _outlineDropdown removed - using AppDropdown directly ───

  Widget _searchBar(AppColors appColors) {
    return Container(
      height: 36,
      width: 180,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: appColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: appColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 16, color: appColors.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: searchController,
              style:
                  TextStyle(fontSize: 12, color: appColors.textPrimary),
              decoration: InputDecoration(
                hintText: "Search",
                hintStyle:
                    TextStyle(color: appColors.textMuted, fontSize: 12),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _viewToggle(AppColors appColors, Color primary) {
    final icons = [
      Icons.view_list_rounded,
      Icons.view_module_rounded,
      Icons.calendar_month_rounded,
    ];
    return Container(
      decoration: BoxDecoration(
        color: appColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: appColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(icons.length, (i) {
          final isActive = _viewMode == i;
          return GestureDetector(
            onTap: () => setState(() => _viewMode = i),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isActive ? primary : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icons[i],
                  size: 16,
                  color: isActive ? Colors.white : appColors.textMuted),
            ),
          );
        }),
      ),
    );
  }

  void _showAssignBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AssignTaskSheet(),
    ).then((_) {
      // Refresh after closing
      Provider.of<DelegationProvider>(context, listen: false).fetchAll();
    });
  }

  Widget _iconBtn(
      {required IconData icon,
      required AppColors appColors,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: appColors.inputBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: appColors.cardBorder),
        ),
        child: Icon(icon, size: 18, color: appColors.textMuted),
      ),
    );
  }

  Widget _statusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(status.toUpperCase(),
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 9,
              letterSpacing: 0.5)),
    );
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

  Widget _dateTag(String date, AppColors appColors) {
    String display = date;
    if (date.length > 10) display = date.substring(0, 10);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: appColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: appColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_rounded, size: 12, color: appColors.textMuted),
          const SizedBox(width: 4),
          Text(display,
              style: TextStyle(
                  color: appColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 10)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "Pending":
        return Colors.orange;
      case "Completed":
        return ThemeProvider.primaryGreen;
      case "Overdue":
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case "High":
        return Colors.red;
      case "Medium":
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  void _showFilterDialog(AppColors appColors, Color primary) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: appColors.cardBackground,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(24),
                child: Consumer3<UserProvider, CategoryProvider, TagProvider>(
                  builder: (ctx, userProv, catProv, tagProv, _) {
                    final users = ["Anyone", ...userProv.users.map((e) => e.fullName)];
                    final priorities = ["All Priority", "High", "Medium", "Low"];
                    final categories = ["All Categories", ...catProv.categoryModels.map((e) => e.name)];
                    final tags = ["All Tags", ...tagProv.tags.map((e) => e.name)];

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("FILTERS",
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: appColors.textPrimary,
                                    letterSpacing: 1.2)),
                            GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  _assignedByFilter = "Anyone";
                                  _priorityFilter = "All Priority";
                                  _categoryFilter = "All Categories";
                                  _tagFilter = "All Tags";
                                });
                                setState(() {
                                  _assignedByFilter = "Anyone";
                                  _priorityFilter = "All Priority";
                                  _categoryFilter = "All Categories";
                                  _tagFilter = "All Tags";
                                });
                              },
                              child: Text("Clear All",
                                  style: TextStyle(
                                      color: primary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ASSIGNED BY
                        _buildFilterDropdownLabel("ASSIGNED BY", appColors),
                        _buildFilterDropdown(
                          value: _assignedByFilter,
                          items: users,
                          appColors: appColors,
                          onChanged: (val) {
                            setDialogState(() => _assignedByFilter = val!);
                            setState(() => _assignedByFilter = val!);
                          },
                        ),
                        const SizedBox(height: 16),

                        // PRIORITY
                        _buildFilterDropdownLabel("PRIORITY", appColors),
                        _buildFilterDropdown(
                          value: _priorityFilter,
                          items: priorities,
                          appColors: appColors,
                          onChanged: (val) {
                            setDialogState(() => _priorityFilter = val!);
                            setState(() => _priorityFilter = val!);
                          },
                        ),
                        const SizedBox(height: 16),

                        // CATEGORY
                        _buildFilterDropdownLabel("CATEGORY", appColors),
                        _buildFilterDropdown(
                          value: _categoryFilter,
                          items: categories,
                          appColors: appColors,
                          onChanged: (val) {
                            setDialogState(() => _categoryFilter = val!);
                            setState(() => _categoryFilter = val!);
                          },
                        ),
                        const SizedBox(height: 16),

                        // TAG
                        _buildFilterDropdownLabel("TAG", appColors),
                        _buildFilterDropdown(
                          value: _tagFilter,
                          items: tags,
                          appColors: appColors,
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
          },
        );
      },
    );
  }

  Widget _buildFilterDropdownLabel(String label, AppColors appColors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: appColors.textMuted, letterSpacing: 0.5)),
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required AppColors appColors,
    required ValueChanged<String?> onChanged,
  }) {
    // Make sure 'value' is actually inside 'items' to prevent assertion errors
    final currentValue = items.contains(value) ? value : items.first;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: appColors.inputBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: appColors.cardBorder.withOpacity(0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: appColors.textPrimary),
          dropdownColor: appColors.cardBackground,
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
}

