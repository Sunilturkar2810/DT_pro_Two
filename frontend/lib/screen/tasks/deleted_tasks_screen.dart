import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/delegation_provider.dart';
import '../../provider/auth_provider.dart';
import 'package:intl/intl.dart';

class DeletedTasksScreen extends StatefulWidget {
  const DeletedTasksScreen({Key? key}) : super(key: key);

  @override
  State<DeletedTasksScreen> createState() => _DeletedTasksScreenState();
}

class _DeletedTasksScreenState extends State<DeletedTasksScreen> {
  String _statusFilter = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isAdmin = context.read<AuthProvider>().isAdmin;
      // Only ADMIN can fetch
      if (isAdmin) {
        context.read<DelegationProvider>().fetchDeleted();
      }
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

  Future<void> _handleRestore(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Task'),
        content: const Text('Restore this item? It will become active again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restore', style: TextStyle(color: Colors.green))),
        ],
      )
    );

    if (confirm == true) {
      final success = await context.read<DelegationProvider>().restoreTask(id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task Restored!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to restore task.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.read<AuthProvider>().isAdmin;

    if (!isAdmin) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(title: const Text('DELETED TASKS'), backgroundColor: Colors.redAccent, elevation: 0),
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                  child: Icon(Icons.security, size: 40, color: Colors.red.shade300),
                ),
                const SizedBox(height: 16),
                const Text('ADMIN Only', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('You need administrator access to\nview the deleted tasks bin.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5)),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DELETED TASKS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('ADMIN View - Trash Bin', style: TextStyle(fontSize: 10, color: Colors.white70)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<DelegationProvider>().fetchDeleted(),
          )
        ],
      ),
      body: Consumer<DelegationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.deletedDelegations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final displayList = provider.deletedDelegations.where((task) {
            final q = _searchQuery.toLowerCase();
            final matchesSearch = task.delegationName.toLowerCase().contains(q) || 
                                  task.description.toLowerCase().contains(q);
            final matchesStatus = _statusFilter == 'All' || task.status == _statusFilter;
            return matchesSearch && matchesStatus;
          }).toList();

          int countOverdue = provider.deletedDelegations.where((t) => t.status == 'Overdue').length;
          int countPending = provider.deletedDelegations.where((t) => t.status == 'Pending').length;
          int countInProgress = provider.deletedDelegations.where((t) => t.status == 'In Progress').length;
          int countCompleted = provider.deletedDelegations.where((t) => t.status == 'Completed').length;

          return Column(
            children: [
              // Search Toolbar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search deleted tasks...',
                          hintStyle: const TextStyle(fontSize: 12),
                          prefixIcon: const Icon(Icons.search, size: 16),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.red.shade100)),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Status Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    _buildStatusTab('All', provider.deletedDelegations.length, Colors.grey),
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
                          Icon(Icons.delete_outline, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text("Trash Is Empty", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                          const Text("No deleted tasks found", style: TextStyle(color: Colors.grey)),
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
                            border: Border.all(color: Colors.grey.shade100),
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
                                    backgroundColor: Colors.red.shade100,
                                    child: Text(uInitials, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red.shade600)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('From: ${task.delegatorName}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                        Text(task.delegationName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                                      ],
                                    ),
                                  ),
                                  // Restore Button
                                  GestureDetector(
                                    onTap: () => _handleRestore(task.id!),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.green.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.restore, size: 14, color: Colors.green.shade600),
                                          const SizedBox(width: 4),
                                          Text('Restore', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                                        ],
                                      ),
                                    ),
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
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: _getStatusColor(task.status).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                        child: Text(task.status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _getStatusColor(task.status))),
                                      )
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 14, color: Colors.orange),
                                      const SizedBox(width: 4),
                                      Text('Due: ${_formatDate(task.dueDate)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange)),
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
          border: isSelected ? Border.all(color: Colors.red.shade200) : null,
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
