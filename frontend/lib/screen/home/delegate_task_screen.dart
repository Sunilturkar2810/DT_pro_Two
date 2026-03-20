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

      return matchesSearch && matchesStatus && matchesAssignedTo && matchesPriority && matchesCategory && matchesTags;
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
      backgroundColor: isDark ? const Color(0xFF12161B) : slate50,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF12161B) : Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          "DELEGATED TASKS",
          style: TextStyle(
            color: isDark ? Colors.white : slate800,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.2
          ),
        ),
        iconTheme: IconThemeData(color: isDark ? Colors.white : slate800),
      ),
      body: Column(
        children: [
          _buildWebsiteStyleToolbar(isDark),
          _buildStatusTabs(isDark, counts),
          Expanded(
            child: RefreshIndicator(
              color: primaryColor,
              onRefresh: () async {
                await Provider.of<DelegationProvider>(context, listen: false).fetchAll();
              },
              child: delegationProv.isLoading
                  ? Center(child: CircularProgressIndicator(color: primaryColor))
                  : filtered.isEmpty
                      ? _buildEmptyState(isDark)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) => _buildTaskCard(filtered[i], userProv.users, isDark),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebsiteStyleToolbar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF12161B) : Colors.white,
        border: Border(bottom: BorderSide(color: isDark ? slate800 : slate100)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _actionButton(LucideIcons.checkSquare, "Assign Task", primaryColor, onTap: () => _showAssignBottomSheet(context)),
            const SizedBox(width: 12),
            
            _dropdownWrapper(
              child: DropdownButton<String>(
                value: selectedDateRange,
                items: ["Today", "This Week", "This Month", "Last Month", "All Time"]
                    .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)))).toList(),
                onChanged: (v) => setState(() => selectedDateRange = v!),
                underline: const SizedBox(),
                icon: const Icon(LucideIcons.chevronDown, size: 14),
              ),
              label: "DATE RANGE",
              isDark: isDark,
            ),
            const SizedBox(width: 12),

            _actionButton(LucideIcons.filter, "Filter", const Color(0xFF1E293B), onTap: () => _showFilterDialog(isDark)),
            const SizedBox(width: 12),

            Container(
              width: 250,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? slate800 : slate200),
              ),
              child: TextField(
                controller: searchController,
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white : slate800),
                decoration: InputDecoration(
                  hintText: "Search tasks...",
                  hintStyle: TextStyle(color: slate400, fontSize: 12),
                  prefixIcon: Icon(LucideIcons.search, size: 16, color: slate400),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 12),

            _iconActionBtn(LucideIcons.refreshCw, primaryColor, onTap: () => Provider.of<DelegationProvider>(context, listen: false).fetchAll()),
            const SizedBox(width: 12),

            _actionButton(LucideIcons.fileOutput, "Export", primaryColor),
            const SizedBox(width: 12),

            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : slate50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? slate800 : slate200),
              ),
              child: Row(
                children: [
                  _viewIcon(LucideIcons.list, 0),
                  _viewIcon(LucideIcons.layoutGrid, 1),
                  _viewIcon(LucideIcons.calendar, 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return ElevatedButton.icon(
      onPressed: onTap ?? () {},
      icon: Icon(icon, size: 16, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _iconActionBtn(IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }

  Widget _dropdownWrapper({required Widget child, required String label, required bool isDark}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: slate400, letterSpacing: 1)),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isDark ? slate800 : primaryColor.withOpacity(0.5)),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _viewIcon(IconData icon, int index) {
    bool active = _viewMode == index;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = index),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: active ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: active ? Colors.white : slate400),
      ),
    );
  }

  Widget _buildStatusTabs(bool isDark, Map<String, int> counts) {
    final tabs = [
      {"key": "All", "color": const Color(0xFF94A3B8)},
      {"key": "OverDue", "color": const Color(0xFFEF4444)},
      {"key": "Pending", "color": const Color(0xFF64748B)},
      {"key": "In Progress", "color": const Color(0xFFF59E0B)},
      {"key": "Completed", "color": const Color(0xFF10B981)},
    ];

    return Container(
      color: isDark ? const Color(0xFF12161B) : Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((tab) {
            final key = tab["key"] as String;
            final color = tab["color"] as Color;
            final isActive = _activeStatusTab == key;
            final count = counts[key] ?? 0;

            return GestureDetector(
              onTap: () => setState(() => _activeStatusTab = key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: isActive ? primaryColor : Colors.transparent, width: 3)),
                ),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
                    const SizedBox(width: 8),
                    Text(
                      "${key.toUpperCase()} — $count",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isActive ? FontWeight.w900 : FontWeight.bold,
                        color: isActive ? (isDark ? Colors.white : slate800) : slate400,
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

  Widget _buildTaskCard(DelegationModel task, List<UserModel> users, bool isDark) {
    final Color statusColor = _getStatusColor(task.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? slate800 : slate100),
        boxShadow: [if(!isDark) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task))),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(width: 4, height: 40, decoration: BoxDecoration(color: _getPriorityColor(task.priority), borderRadius: BorderRadius.circular(4))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(task.delegationName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : slate800)),
                        Text(task.category, style: TextStyle(fontSize: 11, color: slate400)),
                      ],
                    ),
                  ),
                  _statusBadge(task.status, statusColor),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: isDark ? Colors.black26 : slate50, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16))),
              child: Row(
                children: [
                  const Icon(LucideIcons.user, size: 12, color: Color(0xFF00D094)),
                  const SizedBox(width: 4),
                  Text("To: ${task.getAssignedToName(users)}", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : slate600)),
                  const Spacer(),
                  const Icon(LucideIcons.calendar, size: 12, color: Color(0xFF00D094)),
                  const SizedBox(width: 4),
                  Text(task.dueDate.length >= 10 ? task.dueDate.substring(0, 10) : task.dueDate, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : slate600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Consumer3<UserProvider, CategoryProvider, TagProvider>(
              builder: (ctx, userProv, catProv, tagProv, _) {
                final users = ["Anyone", ...userProv.users.map((e) => e.fullName)];
                final priorities = ["All Priority", "High", "Medium", "Low"];
                final categories = ["All Categories", ...catProv.categoryModels.map((e) => e.name)];
                final tags = ["All Tags", ...tagProv.tags.map((e) => e.name)];

                return Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Container(
                    width: 320,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("FILTERS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            TextButton(onPressed: () {
                              setDialogState(() { _assignedToFilter = "Anyone"; _priorityFilter = "All Priority"; _categoryFilter = "All Categories"; _tagFilter = "All Tags"; });
                              setState(() { _assignedToFilter = "Anyone"; _priorityFilter = "All Priority"; _categoryFilter = "All Categories"; _tagFilter = "All Tags"; });
                            }, child: Text("Clear All", style: TextStyle(color: primaryColor)))
                          ],
                        ),
                        const SizedBox(height: 16),
                        _filterDropdown("ASSIGNED TO", _assignedToFilter, users, (v) => setDialogState(() => setState(() => _assignedToFilter = v!))),
                        _filterDropdown("PRIORITY", _priorityFilter, priorities, (v) => setDialogState(() => setState(() => _priorityFilter = v!))),
                        _filterDropdown("CATEGORY", _categoryFilter, categories, (v) => setDialogState(() => setState(() => _categoryFilter = v!))),
                        _filterDropdown("TAG", _tagFilter, tags, (v) => setDialogState(() => setState(() => _tagFilter = v!))),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        );
      }
    );
  }

  Widget _filterDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: slate400)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: slate200)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: items.contains(value) ? value : items.first,
              items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 12)))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
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

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.clipboardList, size: 64, color: slate200),
          const SizedBox(height: 16),
          Text("No Delegated Tasks", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: slate400)),
        ],
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
