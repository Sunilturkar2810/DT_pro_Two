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

class DelegateTasksScreen extends StatefulWidget {
  const DelegateTasksScreen({super.key});

  @override
  State<DelegateTasksScreen> createState() => _DelegateTasksScreenState();
}

class _DelegateTasksScreenState extends State<DelegateTasksScreen> {
  final Color primaryColor = ThemeProvider.primaryGreen;
  final TextEditingController searchController = TextEditingController();

  String searchQuery = "";
  String selectedDateRange = "This Month";
  String selectedSortBy = "Target Date";
  bool parentTasksOnly = false;
  int _viewMode = 0; // 0=list,1=grid,2=calendar
  String _activeStatusTab = "All";

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      setState(() => searchQuery = searchController.text.toLowerCase());
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
    // DELEGATED TASKS = sirf wo tasks jo MAINE kisi aur ko assign kiye hain
    return all.where((task) {
      if (task.delegatorId != myId) return false; // ✅ only delegated BY me
      if (task.assingDoerId == myId) return false; // ✅ and assigned to SOMEONE ELSE

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
    final bool isAdmin = auth.isAdmin;

    final myId = auth.currentUser?.id;
    final filtered = _applyFilters(delegationProv.delegations, myId);

    // Status counts — sirf maine delegete kiye kisi aur ko
    final delegatedByMe = delegationProv.delegations
        .where((t) => t.delegatorId == myId && t.assingDoerId != myId)
        .toList();
    final counts = {
      "All": delegatedByMe.length,
      "OverDue": delegatedByMe.where((t) => t.status == "Overdue").length,
      "Pending": delegatedByMe.where((t) => t.status == "Pending").length,
      "In Progress": delegatedByMe.where((t) => t.status == "In Progress").length,
      "Completed": delegatedByMe.where((t) => t.status == "Completed").length,
    };

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── AppBar ──────────────────────────────────────────────
          AppBar(
            backgroundColor: primaryColor,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              "DELEGATED TASKS",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 1.2),
            ),
          ),

          // ── Toolbar Row 1 ───────────────────────────────────────
          _buildTopToolbar(appColors, isAdmin),

          // ── Toolbar Row 2 ───────────────────────────────────────
          _buildSecondaryToolbar(appColors),

          // ── Status Tabs ─────────────────────────────────────────
          _buildStatusTabs(appColors, counts),

          // ── Task List ───────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: primaryColor,
              onRefresh: () async {
                await Provider.of<DelegationProvider>(context, listen: false)
                    .fetchAll();
              },
              child: delegationProv.isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: primaryColor))
                  : filtered.isEmpty
                      ? _buildEmptyState(appColors)
                      : ListView.builder(
                          padding: const EdgeInsets.only(
                              top: 12, bottom: 80, left: 16, right: 16),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) => _buildTaskCard(
                              filtered[i], userProv.users, isAdmin, appColors),
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
  Widget _buildTopToolbar(AppColors appColors, bool isAdmin) {
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
            // Assign Task (always visible - any user can assign)
            _greenBtn(
              icon: Icons.add_task_rounded,
              label: "Assign Task",
              onTap: () => _showAssignBottomSheet(context),
            ),
            const SizedBox(width: 8),

            // Date Range
            AppDropdown<String>(
              isCompact: true,
              value: selectedDateRange,
              items: const [
                "Today",
                "This Week",
                "This Month",
                "Last Month",
                "All Time"
              ],
              labelBuilder: (v) => v,
              prefixIcon: Icons.date_range_rounded,
              accentColor: primaryColor,
              onChanged: (v) => setState(() => selectedDateRange = v!),
            ),
            const SizedBox(width: 8),

            // Filter
            _greenBtn(
                icon: Icons.filter_list_rounded,
                label: "Filter",
                onTap: () {}),
            const SizedBox(width: 8),

            // Saved Filters
            _greenBtn(
                icon: Icons.bookmark_rounded,
                label: "Saved Filters",
                onTap: () {}),
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
  Widget _buildSecondaryToolbar(AppColors appColors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      color: appColors.toolbarBackground,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            // View toggle
            _viewToggle(appColors),
            const SizedBox(width: 12),

            // Sort By
            Text("Sort By",
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: appColors.textMuted)),
            const SizedBox(width: 6),
            AppDropdown<String>(
              isCompact: true,
              value: selectedSortBy,
              items: const [
                "Target Date",
                "Priority",
                "Status",
                "Created Date"
              ],
              labelBuilder: (v) => v,
              accentColor: primaryColor,
              onChanged: (v) => setState(() => selectedSortBy = v!),
            ),
            const SizedBox(width: 6),

            // Sort direction
            _iconBtn(icon: Icons.swap_vert_rounded, appColors: appColors),
            const SizedBox(width: 16),

            // Parent Tasks
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
                activeColor: primaryColor,
                onChanged: (v) => setState(() => parentTasksOnly = v),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // STATUS TABS
  // ─────────────────────────────────────────────────────────────────
  Widget _buildStatusTabs(AppColors appColors, Map<String, int> counts) {
    final tabs = [
      {"key": "All", "color": Colors.blueGrey as Color, "filled": true, "useCheck": false},
      {"key": "OverDue", "color": Colors.red as Color, "filled": true, "useCheck": false},
      {"key": "Pending", "color": Colors.orange as Color, "filled": false, "useCheck": false},
      {"key": "In Progress", "color": Colors.orange as Color, "filled": true, "useCheck": false},
      {"key": "Completed", "color": primaryColor, "filled": true, "useCheck": true},
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
                      color: isActive ? primaryColor : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (useCheck)
                      Icon(Icons.check_circle_rounded, size: 14, color: color)
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
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.w500,
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
      bool isAdmin, AppColors appColors) {
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
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task))),
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            task.delegationName,
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: appColors.textPrimary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _statusBadge(task.status, statusColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── By / To row ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.person_rounded, size: 14, color: primaryColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: RichText(
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: TextStyle(
                            fontSize: 11,
                            color: appColors.textSecondary),
                        children: [
                          TextSpan(
                              text: "By: ",
                              style:
                                  TextStyle(color: appColors.textMuted)),
                          TextSpan(
                              text: task.getAssignedByName(users),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.assignment_ind_rounded,
                      size: 14, color: primaryColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: RichText(
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: TextStyle(
                            fontSize: 11,
                            color: appColors.textSecondary),
                        children: [
                          TextSpan(
                              text: "To: ",
                              style:
                                  TextStyle(color: appColors.textMuted)),
                          TextSpan(
                              text: task.getAssignedToName(users),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // ── Dept + Evidence row ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.business_center_rounded,
                      size: 13, color: appColors.textMuted),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(task.department,
                        style: TextStyle(
                            fontSize: 11, color: appColors.textSecondary),
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.verified_user_rounded,
                      size: 13, color: appColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                      task.evidenceRequired
                          ? "Evidence Req."
                          : "No Evidence",
                      style: TextStyle(
                          fontSize: 11, color: appColors.textSecondary)),
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
                    color: Colors.orange.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: Colors.orange.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.comment_bank_rounded,
                          size: 13, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          task.remarks.last.remark,
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange[900],
                              fontStyle: FontStyle.italic,
                              height: 1.3),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.orange,
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  _priorityTag(task.priority),
                  const SizedBox(width: 8),
                  _dateTag(task.dueDate, appColors),
                  const Spacer(),
                  _actionBtn(Icons.edit_note_rounded, Colors.blue,
                      () => _showUpdateBottomSheet(context, task)),
                  const SizedBox(width: 8),
                  _actionBtn(Icons.delete_outline_rounded, Colors.red,
                      () => _confirmDelete(context, task.id!)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // EMPTY STATE
  // ─────────────────────────────────────────────────────────────────
  Widget _buildEmptyState(AppColors appColors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
                          color: Colors.redAccent, shape: BoxShape.circle),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text("No Tasks Here",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: appColors.textPrimary)),
            const SizedBox(height: 8),
            Text(
              "It seems that you don't have any tasks in this list",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: appColors.textMuted, height: 1.5),
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
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
            color: primaryColor, borderRadius: BorderRadius.circular(8)),
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
              style: TextStyle(fontSize: 12, color: appColors.textPrimary),
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

  Widget _viewToggle(AppColors appColors) {
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
                color: isActive ? primaryColor : Colors.transparent,
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

  Widget _iconBtn({required IconData icon, required AppColors appColors}) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: appColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: appColors.cardBorder),
      ),
      child: Icon(icon, size: 18, color: appColors.textMuted),
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
    String display = date.length > 10 ? date.substring(0, 10) : date;
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

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // DIALOGS & BOTTOM SHEETS (preserved from original)
  // ─────────────────────────────────────────────────────────────────

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

  Widget _inputField(TextEditingController ctrl, String label, IconData icon,
      {int maxLines = 1}) {
    return TextField(
        controller: ctrl, maxLines: maxLines, decoration: _inputDecoration(label, icon));
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      prefixIcon: Icon(icon, color: primaryColor, size: 18),
      filled: true,
      fillColor: Colors.grey[50],
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[200]!)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: primaryColor)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    );
  }

  void _showUpdateBottomSheet(BuildContext context, DelegationModel task) {
    String selectedStatus = task.status;
    final reasonCtrl =
        TextEditingController(text: "Updated from Admin Panel");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
                child: Container(
                    width: 50,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10)))),
            const Text("Update Task Status",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 25),
            AppDropdown<String>(
              isCompact: false,
              value: ["Pending", "In Progress", "Completed", "Overdue"]
                      .contains(selectedStatus)
                  ? selectedStatus
                  : "Pending",
              items: const [
                "Pending",
                "In Progress",
                "Completed",
                "Overdue"
              ],
              labelBuilder: (s) => s,
              label: "SELECT STATUS",
              prefixIcon: Icons.sync_rounded,
              onChanged: (val) {
                if (val != null) selectedStatus = val;
              },
            ),
            const SizedBox(height: 16),
            _inputField(
                reasonCtrl, "Reason for change", Icons.notes_rounded),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
                onPressed: () async {
                  final prov = Provider.of<DelegationProvider>(context,
                      listen: false);
                  final auth =
                      Provider.of<AuthProvider>(context, listen: false);
                  bool success = await prov.updateStatus(
                      task.id!,
                      selectedStatus,
                      reasonCtrl.text,
                      auth.currentUser!.id);
                  if (!mounted) return;
                  if (success) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Status Updated!"),
                        backgroundColor: Colors.green));
                  }
                },
                child: const Text("SAVE CHANGES",
                    style: TextStyle(
                        fontWeight: FontWeight.w800, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Task?"),
        content: const Text(
            "Are you sure you want to remove this task permanently?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("CANCEL",
                  style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await Provider.of<DelegationProvider>(context, listen: false)
                  .delete(id);
              Navigator.pop(ctx);
            },
            child: const Text("DELETE",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // COLOR HELPERS
  // ─────────────────────────────────────────────────────────────────

  Color _getStatusColor(String status) {
    switch (status) {
      case "Pending":
        return Colors.orange;
      case "Completed":
        return primaryColor;
      case "Overdue":
        return Colors.red;
      case "In Progress":
        return Colors.blue;
      default:
        return Colors.grey;
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
