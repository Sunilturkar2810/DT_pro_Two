import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:d_table_delegate_system/provider/theme_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Row(
            children: [
              Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const SizedBox(width: 8),
              const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
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
      backgroundColor: const Color(0xFFF8FAFC),
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
              title: const Text("GROUP TASK", 
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)
              ),
              background: Container(color: primary),
            ),
          ),
        ],
        body: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.users, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.groupName,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                        ),
                        const Text("Manage tasks and monitor performance", 
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 40, height: 40,
                    child: ElevatedButton(
                      onPressed: _showAddTaskDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Icon(Icons.add, size: 20),
                    ),
                  ),
                ],
              ),
            ),

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
            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            // Tabs Row
            Container(
              color: Colors.white,
              width: double.infinity,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: primary,
                unselectedLabelColor: const Color(0xFF64748B),
                indicatorColor: primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                tabs: const [
                  Tab(child: Row(children: [Icon(LucideIcons.layoutDashboard, size: 16), SizedBox(width: 6), Text("DASHBOARD")])),
                  Tab(child: Row(children: [Icon(LucideIcons.checkCircle2, size: 16), SizedBox(width: 6), Text("TASKS")])),
                  Tab(child: Row(children: [Icon(LucideIcons.lightbulb, size: 16), SizedBox(width: 6), Text("IDEABOARD")])),
                  Tab(child: Row(children: [Icon(LucideIcons.link, size: 16), SizedBox(width: 6), Text("LINKS")])),
                  Tab(child: Row(children: [Icon(LucideIcons.history, size: 16), SizedBox(width: 6), Text("TIMELINE")])),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: Consumer<GroupProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading && provider.selectedGroup == null) {
                    return Center(child: CircularProgressIndicator(color: primary));
                  }

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDashboardTab(provider),
                      _buildTasksTab(provider.groupTasks),
                      const Center(child: Text("Ideaboard Not Available")),
                      const Center(child: Text("Links Not Available")),
                      const Center(child: Text("Timeline Not Available")),
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
    
    int overdue = tasks.where((t) => t['status'] == 'Overdue').length;
    int pending = tasks.where((t) => t['status'] == 'Pending' || t['status'] == 'To Do').length;
    int inProgress = tasks.where((t) => t['status'] == 'In Progress' || t['status'] == 'Working').length;
    int completed = tasks.where((t) => t['status'] == 'Completed' || t['status'] == 'Done').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatCard("OVERDUE", overdue, const Color(0xFFEF4444)),
                const SizedBox(width: 12),
                _buildStatCard("PENDING", pending, const Color(0xFFF59E0B)),
                const SizedBox(width: 12),
                _buildStatCard("IN PROGRESS", inProgress, const Color(0xFF3B82F6)),
                const SizedBox(width: 12),
                _buildStatCard("COMPLETED", completed, const Color(0xFF10B981)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text("MEMBER PERFORMANCE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          
          if (members.isEmpty)
            const Center(child: Text("No members available."))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                final doerId = member['id'];
                final name = member['firstName'] != null ? "${member['firstName']} ${member['lastName'] ?? ''}" : "Member";
                final memberTasks = tasks.where((t) => t['doerId'] == doerId || t['assignedTo'] == doerId).toList();
                return _buildMemberPerformanceCard(name, memberTasks);
              },
            ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildMemberPerformanceCard(String name, List memberTasks) {
    int total = memberTasks.length;
    int overdue = memberTasks.where((t) => t['status'] == 'Overdue').length;
    int pending = memberTasks.where((t) => t['status'] == 'Pending').length;
    int completed = memberTasks.where((t) => t['status'] == 'Completed').length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(color: Color(0xFF1E293B), borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
            child: Row(
              children: [
                CircleAvatar(radius: 12, backgroundColor: Colors.white24, child: Text(name[0], style: const TextStyle(fontSize: 10, color: Colors.white))),
                const SizedBox(width: 10),
                Expanded(child: Text(name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12))),
                Text("TOTAL: $total", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: _perfRow("Overdue", overdue, const Color(0xFFEF4444))),
                Expanded(child: _perfRow("Pending", pending, const Color(0xFFF59E0B))),
                Expanded(child: _perfRow("Done", completed, const Color(0xFF10B981))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _perfRow(String label, int val, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        Text("$val", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
      ],
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Container(
      width: 140, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border(bottom: BorderSide(color: color, width: 4))),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8))),
          const SizedBox(height: 8),
          Text("$value", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildTasksTab(List tasks) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) => _buildTaskCard(tasks[index]),
    );
  }

  Widget _buildTaskCard(dynamic task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Row(
        children: [
          const Icon(LucideIcons.clipboardList, size: 20, color: Color(0xFF10B981)),
          const SizedBox(width: 12),
          Expanded(child: Text(task['taskTitle'] ?? "Untitled", style: const TextStyle(fontWeight: FontWeight.bold))),
          _statusBadge(task['status'] ?? "Pending"),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status.toUpperCase(), style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w900, fontSize: 9)),
    );
  }
}
