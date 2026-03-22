import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:d_table_delegate_system/provider/theme_provider.dart';
import '../../provider/group_provider.dart';
import '../../model/group_model.dart';
class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupDetailScreen({
    Key? key,
    required this.groupId,
    required this.groupName,
  }) : super(key: key);

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _taskTitleController;
  late TextEditingController _taskDescriptionController;
  String _selectedPriority = 'Medium';
  String _selectedCategory = 'General';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _taskTitleController = TextEditingController();
    _taskDescriptionController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupProvider>().fetchGroupDetails(widget.groupId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _taskTitleController.dispose();
    _taskDescriptionController.dispose();
    super.dispose();
  }

  void _showAddTaskDialog() {
    final primary = ThemeProvider.primaryGreen;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Task to Group'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _taskTitleController,
                decoration: InputDecoration(
                  labelText: 'Task Title',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.assignment),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _taskDescriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPriority,
                decoration: InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.flag),
                ),
                items: const ['Low', 'Medium', 'High'].map((priority) {
                  return DropdownMenuItem(value: priority, child: Text(priority));
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedPriority = value ?? 'Medium');
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.category),
                ),
                items: const ['General', 'Urgent', 'Maintenance', 'Sales', 'Support']
                    .map((category) {
                  return DropdownMenuItem(value: category, child: Text(category));
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value ?? 'General');
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Consumer<GroupProvider>(
            builder: (context, provider, _) => ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: provider.isLoading
                  ? null
                  : () async {
                      if (_taskTitleController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a task title')),
                        );
                        return;
                      }

                      final taskData = {
                        'taskTitle': _taskTitleController.text,
                        'description': _taskDescriptionController.text,
                        'priority': _selectedPriority,
                        'category': _selectedCategory,
                        'doerId': 'group',
                        'status': 'Pending',
                      };

                      final success = await provider.assignTaskToGroup(
                        widget.groupId,
                        taskData,
                      );

                      if (mounted) {
                        if (success) {
                          _taskTitleController.clear();
                          _taskDescriptionController.clear();
                          _selectedPriority = 'Medium';
                          _selectedCategory = 'General';
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Task added successfully!')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${provider.errorMessage}')),
                          );
                        }
                      }
                    },
              child: provider.isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : const Text('Add Task', style: TextStyle(color: Colors.black)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(width: 8),
              const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = ThemeProvider.primaryGreen;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Head mimicking Web Layout top bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(backgroundColor: Colors.grey.shade100, radius: 18, child: const Icon(Icons.group_outlined, color: Colors.grey, size: 20)),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.groupName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                      Text(widget.groupName.toLowerCase(), style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    height: 36, width: 110,
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(children: [Icon(Icons.search, size: 14, color: Colors.grey.shade400), const SizedBox(width: 6), Expanded(child: Text("Search", style: TextStyle(color: Colors.grey.shade400, fontSize: 12)))]),
                  ),
                  const SizedBox(width: 12),
                  const Text("TEAM", style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(width: 6),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(radius: 12, backgroundColor: primary, child: const Text("AG", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold))),
                      Positioned(right: -12, child: CircleAvatar(radius: 12, backgroundColor: Colors.cyan, child: const Text("ME", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)))),
                    ],
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            
            // Filter Dropdowns Row
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _showAddTaskDialog,
                        icon: const Icon(Icons.add, color: Colors.white, size: 16),
                        label: const Text("Assign Task", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    _buildFilterDropdown("DATE RANGE", "This Month"),
                    const SizedBox(width: 12),
                    _buildFilterDropdown("ASSIGNED TO", "Assigned To"),
                    const SizedBox(width: 12),
                    _buildFilterDropdown("FREQUENCY", "Frequency"),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Container(
                        height: 38, width: 38,
                        decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(8)),
                        child: IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                          onPressed: () => context.read<GroupProvider>().fetchGroupDetails(widget.groupId),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),

            // Tabs Row
            Container(
              color: Colors.white,
              width: double.infinity,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: primary,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: primary,
                indicatorWeight: 3,
                labelPadding: const EdgeInsets.symmetric(horizontal: 20),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                tabs: const [
                  Tab(child: Row(children: [Icon(Icons.dashboard_outlined, size: 16), SizedBox(width: 4), Text("Dashboard")])),
                  Tab(child: Row(children: [Icon(Icons.check_circle_outline, size: 16), SizedBox(width: 4), Text("Tasks")])),
                  Tab(child: Row(children: [Icon(Icons.lightbulb_outline, size: 16), SizedBox(width: 4), Text("Ideaboard")])),
                  Tab(child: Row(children: [Icon(Icons.link, size: 16), SizedBox(width: 4), Text("Links")])),
                  Tab(child: Row(children: [Icon(Icons.history, size: 16), SizedBox(width: 4), Text("Timeline")])),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: Consumer<GroupProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading && provider.selectedGroup == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final group = provider.selectedGroup;
                  if (group == null) {
                    return const Center(child: Text("Failed to load group details."));
                  }

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDashboardTab(provider),
                      _buildTasksTab(provider.groupTasks),
                      const Center(child: Text("Ideaboard Not Available", style: TextStyle(color: Colors.grey))),
                      const Center(child: Text("Links Not Available", style: TextStyle(color: Colors.grey))),
                      const Center(child: Text("Timeline Not Available", style: TextStyle(color: Colors.grey))),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTab(GroupProvider provider) {
    final tasks = provider.groupTasks;
    final members = provider.groupMembers;
    
    // Total group stats
    int overdue = tasks.where((t) => t['status'] == 'Overdue').length;
    int pending = tasks.where((t) => t['status'] == 'Pending' || t['status'] == 'To Do').length;
    int inProgress = tasks.where((t) => t['status'] == 'In Progress' || t['status'] == 'Working').length;
    int completed = tasks.where((t) => t['status'] == 'Completed' || t['status'] == 'Done').length;
    int inTime = tasks.where((t) => t['status'] == 'In Time').length;
    int delayed = tasks.where((t) => t['status'] == 'Delayed').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat Cards Scrollable Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatCard("OVERDUE", overdue, Colors.red),
                const SizedBox(width: 12),
                _buildStatCard("PENDING", pending, Colors.orange),
                const SizedBox(width: 12),
                _buildStatCard("IN PROGRESS", inProgress, Colors.blue),
                const SizedBox(width: 12),
                _buildStatCard("COMPLETED", completed, Colors.green),
                const SizedBox(width: 12),
                _buildStatCard("IN TIME", inTime, Colors.teal),
                const SizedBox(width: 12),
                _buildStatCard("DELAYED", delayed, Colors.redAccent),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text("MEMBER PERFORMANCE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
          const SizedBox(height: 12),
          
          if (members.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text("No members available to show performance.", style: TextStyle(color: Colors.grey)),
            ))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                final doerId = member['id'];
                final name = member['firstName'] != null 
                    ? "${member['firstName']} ${member['lastName'] ?? ''}" 
                    : member['workEmail'] ?? "Unknown Member";

                final memberTasks = tasks.where((t) => t['doerId'] == doerId || t['assignedTo'] == doerId).toList();
                
                int mTotal = memberTasks.length;
                int mOverdue = memberTasks.where((t) => t['status'] == 'Overdue').length;
                int mPending = memberTasks.where((t) => t['status'] == 'Pending' || t['status'] == 'To Do').length;
                int mInProgress = memberTasks.where((t) => t['status'] == 'In Progress' || t['status'] == 'Working').length;
                int mCompleted = memberTasks.where((t) => t['status'] == 'Completed' || t['status'] == 'Done').length;
                int mInTime = memberTasks.where((t) => t['status'] == 'In Time').length;
                int mDelayed = memberTasks.where((t) => t['status'] == 'Delayed').length;

                return _buildMemberPerformanceCard(name, mTotal, mOverdue, mPending, mInProgress, mCompleted, mInTime, mDelayed);
              },
            ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildMemberPerformanceCard(String name, int total, int overdue, int pending, int inProgress, int completed, int inTime, int delayed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
        ]
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(color: Color(0xFF0D1B2A), borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
            child: Row(
              children: [
                CircleAvatar(radius: 12, backgroundColor: Colors.white24, child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold))),
                const SizedBox(width: 10),
                Expanded(child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                const Text("TOTAL: ", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                Text("$total", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Not Completed Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(child: Text("NOT COMPLETED", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.black87))),
                      const SizedBox(height: 12),
                      _performanceStatRow(Colors.red, "Overdue", overdue, total),
                      _performanceStatRow(Colors.orange, "Pending", pending, total),
                      _performanceStatRow(Colors.blue, "In-Progress", inProgress, total),
                    ],
                  ),
                ),
                Container(width: 1, height: 80, color: Colors.grey.shade200, margin: const EdgeInsets.symmetric(horizontal: 16)),
                // Completed Section
                Expanded(
                  child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       const Center(child: Text("COMPLETED", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.black87))),
                       const SizedBox(height: 12),
                       _performanceStatRow(Colors.green, "In Time", inTime, total),
                       _performanceStatRow(Colors.redAccent, "Delayed", delayed, total),
                     ]
                  )
                )
              ],
            ),
          ),
        ],
      )
    );
  }

  Widget _performanceStatRow(Color color, String label, int count, int total) {
     double percent = total > 0 ? (count / total) * 100 : 0.0;
     return Padding(
       padding: const EdgeInsets.only(bottom: 6),
       child: Row(
         children: [
           Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
           const SizedBox(width: 6),
           Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w600))),
           Text("$count ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black)),
           Text("(${percent.toStringAsFixed(0)}%)", style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
         ],
       )
     );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Container(
      width: 140, // Fixed width for horizontal scrolling
      padding: const EdgeInsets.all(12),
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
              Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value.toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E1E1E))),
        ],
      ),
    );
  }

  Widget _buildTasksTab(List<dynamic> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 60, color: Colors.grey.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text("No tasks in this group", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 100),
      itemCount: tasks.length,
      itemBuilder: (context, index) => _buildTaskCard(tasks[index]),
    );
  }

  Widget _buildTaskCard(dynamic task) {
    final status = task['status'] ?? 'Pending';
    Color statusColor = Colors.orange;
    if (status == 'Completed' || status == 'Done') statusColor = Colors.green;
    if (status == 'Overdue') statusColor = Colors.red;
    if (status == 'In Progress' || status == 'Working') statusColor = Colors.blue;

    final priority = task['priority'] ?? 'Medium';
    Color priorityColor = Colors.orange;
    if (priority == 'High') priorityColor = Colors.red;
    if (priority == 'Low') priorityColor = Colors.green;

    final title = task['taskTitle'] ?? task['delegationName'] ?? 'No Title';
    final fromName = task['assignedByName'] ?? 'Group Admin';
    final initial = fromName.toString().isNotEmpty ? fromName.toString()[0].toUpperCase() : 'G';
    final dateStr = task['dueDate'] ?? task['createdAt'] ?? '';
    String displayDate = dateStr.length > 10 ? dateStr.substring(0, 10) : dateStr;
    if (displayDate.isEmpty) displayDate = "N/A";

    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: Checkbox + Avatar + Title/From ──
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: status == 'Completed' || status == 'Done',
                    onChanged: (v) {},
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                    activeColor: Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.green.withOpacity(0.1),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.green,
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
                        title,
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
                        "From: $fromName",
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
            const SizedBox(height: 12),
            // ── Bottom row: Status + Date + Priority ──
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 9,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                // Date Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_rounded, size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        displayDate,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                // Priority Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: priorityColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        priority,
                        style: TextStyle(
                          color: priorityColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersTab(List<dynamic> members) {
    if (members.isEmpty) return const Center(child: Text("No members in this group."));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        final name = member['firstName'] != null
            ? "${member['firstName']} ${member['lastName'] ?? ''}"
            : member['workEmail'] ?? "Unknown Member";
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(member['designation'] ?? member['role'] ?? 'Member', style: const TextStyle(fontSize: 12)),
          ),
        );
      },
    );
  }

  Widget _buildInfoTab(GroupModel group) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              const Text("GROUP DESCRIPTION", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.withOpacity(0.1))),
            child: Text(group.description ?? 'No description provided for this group.', style: const TextStyle(fontSize: 14, height: 1.5)),
          ),
          const SizedBox(height: 32),
          _infoRow(Icons.person_outline, "Created By", group.createdBy),
          _infoRow(Icons.group_outlined, "Total Members", group.memberCount.toString()),
          _infoRow(Icons.tag_outlined, "Group ID", group.id),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
