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
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:d_table_delegate_system/widget/custom_date_range_picker.dart';

class InLoopTasksScreen extends StatefulWidget {
  final String title;
  final Color themeColor;

  const InLoopTasksScreen({
    super.key,
    this.title = "In Loop Tasks",
    this.themeColor = const Color(0xFF20E19F),
  });

  @override
  State<InLoopTasksScreen> createState() => _InLoopTasksScreenState();
}

class _InLoopTasksScreenState extends State<InLoopTasksScreen>
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
    // IN LOOP TASKS = sirf wo tasks jisme main inLoopIds me hoon
    return all.where((task) {
      if (!task.inLoopIds.contains(myId)) return false;

      bool matchesSearch = searchQuery.isEmpty ||
          task.delegationName.toLowerCase().contains(searchQuery) ||
          task.description.toLowerCase().contains(searchQuery);

      String statusKey = task.status;
      if (statusKey == "Overdue") statusKey = "OverDue"; // Handle model inconsistency

      bool matchesStatus =
          _activeStatusTab == "All" || statusKey == _activeStatusTab;

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

    // Status counts — sirf in-loop tasks
    final inLoopTasks = delegationProv.delegations.where((t) => t.inLoopIds.contains(myId)).toList();

    int overdueCount = inLoopTasks.where((t) => t.status == "Overdue" || t.status == "OverDue").length;
    int pendingCount = inLoopTasks.where((t) => t.status == "Pending").length;
    int inProgressCount = inLoopTasks.where((t) => t.status == "In Progress").length;
    int completedCount = inLoopTasks.where((t) => t.status == "Completed").length;
    int allCount = inLoopTasks.length;

    final counts = {
      "All": allCount,
      "OverDue": overdueCount,
      "Pending": pendingCount,
      "In Progress": inProgressCount,
      "Completed": completedCount,
    };

    return Scaffold(
      backgroundColor: const Color(0xFFE6F9F1),
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
        body: RefreshIndicator(
          color: primary,
          onRefresh: () async => await delegationProv.fetchAll(),
          child: ListView(
            padding: const EdgeInsets.only(top: 0),
            children: [
              _buildHeader(primary),
              _buildQuickStats(counts),
              _buildToolbar(appColors, primary, userProv.users),
              _buildStatusTabs(appColors, primary, counts),

              // ── Task List / Empty ────────────────────────────────────
              delegationProv.isLoading
                  ? Center(child: CircularProgressIndicator(color: primary))
                  : filtered.isEmpty
                  ? _buildEmptyState(appColors)
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
                        myId,
                        appColors,
                        primary,
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
            child: const Icon(Icons.loop_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "In Loop Tasks",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                "Tasks you are copied on",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // QUICK STATS
  // ─────────────────────────────────────────────────────────────────
  Widget _buildQuickStats(Map<String, int> counts) {
    final stats = [
      {'label': 'TOTAL', 'value': counts['All'], 'color': Colors.grey[500]!, 'bg': Colors.white},
      {'label': 'OVERDUE', 'value': counts['OverDue'], 'color': Colors.redAccent, 'bg': const Color(0xFFFFF0F0)},
      {'label': 'PENDING', 'value': counts['Pending'], 'color': Colors.grey[400]!, 'bg': Colors.white},
      {'label': 'IN PROGRESS', 'value': counts['In Progress'], 'color': Colors.orangeAccent, 'bg': const Color(0xFFFFF7ED)},
      {'label': 'COMPLETED', 'value': counts['Completed'], 'color': const Color(0xFF10B981), 'bg': const Color(0xFFECFDF5)},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: stats.map((s) {
          final isPending = s['label'] == 'PENDING';
          return Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: s['bg'] as Color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPending ? Colors.transparent : s['color'] as Color,
                      border: isPending ? Border.all(color: Colors.grey[400]!, width: 2) : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['label'] as String,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.grey,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${s['value']}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: (s['label'] == 'TOTAL' || s['label'] == 'PENDING')
                                ? const Color(0xFF1E293B)
                                : s['color'] as Color,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // TOOLBAR ROW 1
  // ─────────────────────────────────────────────────────────────────
  Widget _buildToolbar(AppColors appColors, Color primary, List<UserModel> users) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Date Range Dropdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "DATE RANGE",
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 40,
                child: AppDropdown<String>(
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
            ],
          ),
          const SizedBox(width: 10),

          // Filter Button
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton.icon(
              onPressed: () => _showFilterDialog(appColors, primary, users),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              icon: const Icon(Icons.filter_alt_outlined, size: 18, color: Colors.white),
              label: const Text(
                "Filter",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Search Field
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: Colors.grey, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        hintText: "Search tasks...",
                        hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Refresh/Clear Button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
              onPressed: () {
                setState(() {
                  searchController.clear();
                  searchQuery = "";
                  selectedDateRange = "All Time";
                  _activeStatusTab = "All";
                });
              },
            ),
          ),
          const SizedBox(width: 10),

          // View Toggle
          Container(
            height: 40,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
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

  // ─────────────────────────────────────────────────────────────────
  // STATUS TABS
  // ─────────────────────────────────────────────────────────────────
  Widget _buildStatusTabs(AppColors appColors, Color primary, Map<String, int> counts) {
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
              // Our internal logic handles "OverDue" for counts/active
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
                builder: (_) => TaskDetailScreen(task: task, allowEdit: false))),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Checkbox and Avatar
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
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 18,
                backgroundColor: primary.withOpacity(0.1),
                child: Text(
                  initial,
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title and "From: "
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
                    const SizedBox(height: 4),
                    Text(
                      "From: $delegatorName",
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
              const SizedBox(width: 12),

              // Status, Date, Priority, Time, Menu
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                children: [
                  _statusBadge(task.status, statusColor),
                  _dateTag(task.dueDate, appColors),
                  _priorityTag(task.priority),
                  Text(
                    timeAgo,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const Icon(Icons.more_vert_rounded, size: 18, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status, Color color) {
    if (status == "OverDue") status = "Overdue";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _dateTag(String dateStr, AppColors appColors) {
    final formatted = _formatDate(dateStr);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_rounded, size: 10, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            formatted,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _priorityTag(String p) {
    Color pc = Colors.grey;
    if (p == 'Urgent') pc = Colors.redAccent;
    if (p == 'High') pc = Colors.orangeAccent;
    if (p == 'Medium') pc = Colors.blueAccent;
    if (p == 'Low') pc = Colors.grey;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.flag_rounded, size: 12, color: pc),
        const SizedBox(width: 4),
        Text(
          p,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: pc,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return const Color(0xFF10B981);
      case 'In Progress':
        return Colors.orangeAccent;
      case 'OverDue':
      case 'Overdue':
        return Colors.redAccent;
      case 'Pending':
      default:
        return Colors.grey.shade500;
    }
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

  Widget _buildEmptyState(AppColors appColors) {
    return Column(
      children: [
        const SizedBox(height: 80),
        Icon(Icons.all_inbox_rounded, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        const Text(
          "No tasks found",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "You are not copied on any matching tasks.",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // FILTER DIALOG
  // ─────────────────────────────────────────────────────────────────
  void _showFilterDialog(AppColors appColors, Color primary, List<UserModel> users) {
    final categoryModels = context.read<CategoryProvider>().categoryModels;
    final tags = context.read<TagProvider>().tags;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Filter Tasks", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  TextButton(
                    onPressed: () {
                      setDialogState(() {
                        _assignedByFilter = "Anyone";
                        _priorityFilter = "All Priority";
                        _categoryFilter = "All Categories";
                        _tagFilter = "All Tags";
                      });
                    },
                    child: const Text("Reset", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFilterDropdownLabel("ASSIGNED BY"),
                    AppDropdown<String>(
                      value: _assignedByFilter,
                      items: ["Anyone", ...users.map((u) => u.fullName)],
                      labelBuilder: (v) => v,
                      onChanged: (v) => setDialogState(() => _assignedByFilter = v!),
                    ),
                    const SizedBox(height: 15),
                    _buildFilterDropdownLabel("PRIORITY"),
                    AppDropdown<String>(
                      value: _priorityFilter,
                      items: const ["All Priority", "Urgent", "High", "Medium", "Low"],
                      labelBuilder: (v) => v,
                      onChanged: (v) => setDialogState(() => _priorityFilter = v!),
                    ),
                    const SizedBox(height: 15),
                    _buildFilterDropdownLabel("CATEGORY"),
                    AppDropdown<String>(
                      value: _categoryFilter,
                      items: ["All Categories", ...categoryModels.map((c) => c.name)],
                      labelBuilder: (v) => v,
                      onChanged: (v) => setDialogState(() => _categoryFilter = v!),
                    ),
                    const SizedBox(height: 15),
                    _buildFilterDropdownLabel("TAG"),
                    AppDropdown<String>(
                      value: _tagFilter,
                      items: ["All Tags", ...tags.map((t) => t.name)],
                      labelBuilder: (v) => v,
                      onChanged: (v) => setDialogState(() => _tagFilter = v!),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CANCEL", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text("APPLY FILTERS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFilterDropdownLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 2),
        child: Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5),
        ),
      ),
    );
  }
}
