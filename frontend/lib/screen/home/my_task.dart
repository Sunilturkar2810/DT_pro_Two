import 'package:d_table_delegate_system/model/delegate_model.dart';
import 'package:d_table_delegate_system/model/user_model.dart';
import 'package:d_table_delegate_system/provider/auth_provider.dart';
import 'package:d_table_delegate_system/provider/delegation_provider.dart';
import 'package:d_table_delegate_system/provider/theme_provider.dart';
import 'package:d_table_delegate_system/provider/user_provider.dart';
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
  String selectedDateRange = "This Month";
  String selectedSortBy = "Target Date";
  bool parentTasksOnly = false;
  int _viewMode = 0; // 0=list, 1=grid, 2=calendar
  String _activeStatusTab = "All";

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
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<DelegationModel> _applyFilters(
      List<DelegationModel> all, String? myId) {
    // MY TASKS = sirf wo tasks jo MUJHE assign kiye gaye hain
    return all.where((task) {
      if (task.assingDoerId != myId) return false; // ✅ only assigned TO me

      bool matchesSearch = searchQuery.isEmpty ||
          task.delegationName.toLowerCase().contains(searchQuery) ||
          task.description.toLowerCase().contains(searchQuery);

      bool matchesStatus =
          _activeStatusTab == "All" || task.status == _activeStatusTab;

      bool matchesDate = true;
      if (selectedDateRange == "Today") {
        matchesDate =
            task.dueDate.startsWith(DateTime.now().toString().split(' ')[0]);
      } else if (selectedDateRange == "This Month") {
        matchesDate = task.dueDate
            .startsWith(DateTime.now().toString().substring(0, 7));
      } else if (selectedDateRange == "This Week") {
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        try {
          final due = DateTime.parse(task.dueDate.split('T')[0]);
          matchesDate =
              due.isAfter(weekStart.subtract(const Duration(days: 1))) &&
                  due.isBefore(weekEnd.add(const Duration(days: 1)));
        } catch (_) {}
      }

      return matchesSearch && matchesStatus && matchesDate;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final delegationProv = Provider.of<DelegationProvider>(context);
    final userProv = Provider.of<UserProvider>(context);
    final appColors = Theme.of(context).extension<AppColors>()!;
    final primary = ThemeProvider.primaryGreen;

    final filtered =
        _applyFilters(delegationProv.delegations, auth.currentUser?.id);

    final myId = auth.currentUser?.id;
    // Status counts — sirf mujhe assign kiye gaye tasks
    final myTasks = delegationProv.delegations
        .where((t) => t.assingDoerId == myId)
        .toList();

    int overdueCount  = myTasks.where((t) => t.status == "Overdue").length;
    int pendingCount  = myTasks.where((t) => t.status == "Pending").length;
    int inProgressCount = myTasks.where((t) => t.status == "In Progress").length;
    int completedCount  = myTasks.where((t) => t.status == "Completed").length;
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
      body: Column(
        children: [
          // ── AppBar ──────────────────────────────────────────────
          AppBar(
            backgroundColor: primary,
            elevation: 0,
            centerTitle: true,
            title: Text(
              widget.title.toUpperCase(),
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 1.2),
            ),
          ),

          // ── Top Toolbar Row 1: Assign + Date + Filter + Saved + Search ──
          _buildTopToolbar(appColors, primary),

          // ── Top Toolbar Row 2: View icons + Sort + Parent Tasks ──
          _buildSecondaryToolbar(appColors, primary),

          // ── Status Tabs ──────────────────────────────────────────
          _buildStatusTabs(appColors, primary, counts),

          // ── Task List / Empty ────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: primary,
              onRefresh: () async {
                await Provider.of<DelegationProvider>(context, listen: false)
                    .fetchAll();
              },
              child: delegationProv.isLoading
                  ? Center(child: CircularProgressIndicator(color: primary))
                  : filtered.isEmpty
                      ? _buildEmptyState(appColors)
                      : ListView.builder(
                          padding: const EdgeInsets.only(
                              top: 12, bottom: 80, left: 16, right: 16),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) =>
                              _buildTaskCard(filtered[i], userProv.users,
                                  auth.currentUser?.id, appColors, primary),
                        ),
            ),
          ),
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

            // Date Range dropdown
            AppDropdown<String>(
              isCompact: true,
              value: selectedDateRange,
              items: const ["Today", "This Week", "This Month", "Last Month", "All Time"],
              labelBuilder: (v) => v,
              prefixIcon: Icons.date_range_rounded,
              accentColor: ThemeProvider.primaryGreen,
              onChanged: (v) => setState(() => selectedDateRange = v!),
            ),
            const SizedBox(width: 8),

            // Filter button
            _greenBtn(
              icon: Icons.filter_list_rounded,
              label: "Filter",
              color: primary,
              onTap: () {},
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
    final bool isDelegatedByMe = task.delegatorId == myId;
    final Color statusColor = _getStatusColor(task.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: appColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.shade100,width: .7),
        boxShadow: [
          BoxShadow(
              color: appColors.shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task, allowEdit: true))),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card Header ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Priority color bar
                  Container(
                    width: 4,
                    height: 50,
                    margin: const EdgeInsets.only(right: 12, top: 2),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(task.priority),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                task.delegationName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: appColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _statusBadge(task.status, statusColor),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Assigned by whom
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "📥 Assigned to you",
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.teal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Meta Info Row ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Assignee info
                  Icon(Icons.person_rounded, size: 14, color: primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      isDelegatedByMe
                          ? "To: ${task.getAssignedToName(users)}"
                          : "From: ${task.getAssignedByName(users)}",
                      style: TextStyle(
                          fontSize: 11,
                          color: appColors.textSecondary,
                          fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.business_center_rounded,
                      size: 14, color: primary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      task.department,
                      style: TextStyle(
                          fontSize: 11,
                          color: appColors.textSecondary,
                          fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // ── Remark indicator ──────────────────────────────────
            if (task.remarks.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: Colors.blue.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_rounded,
                          size: 13, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          task.remarks.last.remark,
                          style: TextStyle(
                              fontSize: 11,
                              color: appColors.textSecondary,
                              height: 1.3),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(8)),
                        child: Text("${task.remarks.length}",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // ── Footer ────────────────────────────────────────────
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: .1),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  _priorityTag(task.priority),
                  const SizedBox(width: 8),
                  _dateTag(task.dueDate, appColors),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 13, color: appColors.textMuted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
}
