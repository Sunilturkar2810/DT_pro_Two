import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/delegation_provider.dart';
import '../../provider/auth_provider.dart';
import 'package:intl/intl.dart';

class InLoopTasksScreen extends StatefulWidget {
  const InLoopTasksScreen({Key? key}) : super(key: key);

  @override
  State<InLoopTasksScreen> createState() => _InLoopTasksScreenState();
}

class _InLoopTasksScreenState extends State<InLoopTasksScreen> {
  String _statusFilter = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DelegationProvider>().fetchAll();
    });
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'No Date';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed': return Colors.green;
      case 'In Progress': return Colors.orange;
      case 'Overdue': return Colors.red;
      case 'Pending': default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Current user id to match with inLoopIds
    final currentUser = context.read<AuthProvider>().currentUser;
    final currentUserId = currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFE6F9F1), // specific background color from reference
      appBar: AppBar(
        title: const Text('IN LOOP TASKS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF20E19F),
        elevation: 0,
      ),
      body: Consumer<DelegationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.delegations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter out ONLY tasks where I am in loop
          final inLoopList = provider.delegations.where((task) {
            return task.inLoopIds.contains(currentUserId);
          }).toList();

          // Further filter based on search and status
          final displayList = inLoopList.where((task) {
            final q = _searchQuery.toLowerCase();
            final matchesSearch = task.delegationName.toLowerCase().contains(q) || 
                                  task.description.toLowerCase().contains(q);
            final matchesStatus = _statusFilter == 'All' || task.status == _statusFilter;
            return matchesSearch && matchesStatus;
          }).toList();

          // Quick counts
          int countOverdue = inLoopList.where((t) => t.status == 'Overdue').length;
          int countPending = inLoopList.where((t) => t.status == 'Pending').length;
          int countInProgress = inLoopList.where((t) => t.status == 'In Progress').length;
          int countCompleted = inLoopList.where((t) => t.status == 'Completed').length;

          return Column(
            children: [
              // Search & Filters Toolbar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search in loop tasks...',
                          hintStyle: const TextStyle(fontSize: 12),
                          prefixIcon: const Icon(Icons.search, size: 16),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Small filter button placeholder
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(color: const Color(0xFF00D094), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.refresh, color: Colors.white, size: 20),
                    )
                  ],
                ),
              ),

              // Status Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    _buildStatusTab('All', inLoopList.length, Colors.grey),
                    _buildStatusTab('Overdue', countOverdue, Colors.red),
                    _buildStatusTab('Pending', countPending, Colors.grey),
                    _buildStatusTab('In Progress', countInProgress, Colors.orange),
                    _buildStatusTab('Completed', countCompleted, Colors.green),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // List of Tasks
              Expanded(
                child: displayList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_box_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text("No Tasks In-Loop", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                          const Text("Tasks you are copied on will appear here.", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: displayList.length,
                      itemBuilder: (context, index) {
                        final task = displayList[index];
                        final uInitials = task.delegatorName.isNotEmpty ? task.delegatorName.substring(0, 2).toUpperCase() : 'U';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.purple.shade100,
                                    child: Text(uInitials, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.purple.shade700)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('From: ${task.delegatorName.isEmpty ? 'Unknown' : task.delegatorName}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                        Text(task.delegationName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(task.status).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: _getStatusColor(task.status).withOpacity(0.3)),
                                    ),
                                    child: Text(task.status.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _getStatusColor(task.status))),
                                  )
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (task.description.isNotEmpty)
                                Text(
                                  task.description,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 12),
                              const Divider(height: 1, color: Color(0xFFF3F4F6)),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.flag, size: 14, color: task.priority == 'Urgent' ? Colors.red : Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(task.priority, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 14, color: Colors.redAccent),
                                      const SizedBox(width: 4),
                                      Text('Due: ${_formatDate(task.dueDate)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                                    ],
                                  )
                                ],
                              )
                            ],
                          ),
                        );
                      },
                    ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusTab(String title, int count, Color stripColor) {
    bool isSelected = _statusFilter == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _statusFilter = title;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(color: Colors.grey.shade300) : null,
        ),
        child: Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: stripColor, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(
              '${title.toUpperCase()} - $count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.black87 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
