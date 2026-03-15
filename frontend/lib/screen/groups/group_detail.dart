import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../provider/group_provider.dart';

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

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  late TextEditingController _taskTitleController;
  late TextEditingController _taskDescriptionController;
  String _selectedPriority = 'Medium';
  String _selectedCategory = 'General';

  @override
  void initState() {
    super.initState();
    _taskTitleController = TextEditingController();
    _taskDescriptionController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupProvider>().fetchGroupDetails(widget.groupId);
    });
  }

  @override
  void dispose() {
    _taskTitleController.dispose();
    _taskDescriptionController.dispose();
    super.dispose();
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Task to Group'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _taskTitleController,
                decoration: InputDecoration(
                  labelText: 'Task Title',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _taskDescriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedPriority,
                decoration: InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: const ['Low', 'Medium', 'High'].map((priority) {
                  return DropdownMenuItem(value: priority, child: Text(priority));
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedPriority = value ?? 'Medium');
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                        'doerId': 'group', // Will be handled by backend
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
              child: provider.isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator()) : const Text('Add Task'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _showAddTaskDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Task'),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<GroupProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final group = provider.selectedGroup;

          if (group == null) {
            return const Center(child: Text("Failed to load group details."));
          }

          final members = group.members ?? [];
          final tasks = provider.groupTasks;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display Details
                const Text(
                  "Description",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  group.description?.isNotEmpty == true
                      ? group.description!
                      : "No description provided.",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),

                // Members List
                Text(
                  "Members (${group.memberCount})",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                if (members.isEmpty)
                  const Text("No members found.")
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final name = member['firstName'] != null
                          ? "${member['firstName']} ${member['lastName'] ?? ''}"
                          : member['workEmail'] ?? "Unknown Member";

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(name[0].toUpperCase()),
                          ),
                          title: Text(name),
                          subtitle: Text(member['role'] ?? 'Member'),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 24),

                // Tasks List
                Text(
                  "Group Tasks (${tasks.length})",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                if (tasks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text("No tasks assigned yet."),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(task['taskTitle'] ?? 'Untitled'),
                          subtitle: Text(task['description'] ?? 'No description'),
                          trailing: Chip(
                            label: Text(task['status'] ?? 'Pending'),
                            backgroundColor: task['status'] == 'Completed'
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
