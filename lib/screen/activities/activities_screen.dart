import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../provider/activity_provider.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({Key? key}) : super(key: key);

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityProvider>().initActivities();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'task_created':
      case 'subtask_created':
        return Icons.add_circle_outline;
      case 'status_change':
        return Icons.check_circle_outline;
      case 'remark':
        return Icons.chat_bubble_outline;
      default:
        return Icons.access_time;
    }
  }

  Color _getActivityIconColor(String type) {
    switch (type) {
      case 'task_created':
        return Colors.redAccent;
      case 'subtask_created':
        return Colors.green;
      case 'status_change':
        return Colors.redAccent;
      case 'remark':
        return Colors.blueAccent;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime? time) {
    if (time == null) return 'N/A';
    return DateFormat('MMM d, y, hh:mm a').format(time);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F9F1), // Specific background from reference
      appBar: AppBar(
        title: const Text('ACTIVITIES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF20E19F),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ActivityProvider>().fetchActivities(skipLoadingChange: false);
            },
          )
        ],
      ),
      body: Consumer<ActivityProvider>(
        builder: (context, provider, child) {
          final stats = provider.userStats.take(5).toList();
          final filteredList = provider.filteredActivities;

          return Column(
            children: [
              // Filters Section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Date Range
                      _buildFilterDropdown(
                        label: 'Date Range',
                        value: provider.dateRange,
                        items: ['This Month', 'Today', 'This Week', 'All Time'],
                        onChanged: (val) {
                          if (val != null) provider.setDateRange(val);
                        },
                      ),
                      const SizedBox(width: 8),

                      // Updated By
                      _buildFilterDropdown(
                        label: 'Updated By',
                        value: provider.updatedBy ?? 'Updated By',
                        items: ['Updated By', ...provider.usersList.map((u) => u.id)],
                        displayMap: {
                          'Updated By': 'All Users',
                          for (var u in provider.usersList) u.id: '${u.firstName} ${u.lastName}',
                        },
                        onChanged: (val) {
                          provider.setUpdatedBy(val == 'Updated By' ? null : val);
                        },
                      ),
                      const SizedBox(width: 8),

                      // Search
                      Container(
                        width: 140,
                        margin: const EdgeInsets.only(top: 14),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search',
                            hintStyle: const TextStyle(fontSize: 12),
                            prefixIcon: const Icon(Icons.search, size: 16),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white)),
                          ),
                          onChanged: (val) => provider.setSearchQuery(val),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Stats Row
              if (stats.isNotEmpty)
                Container(
                  height: 90,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: stats.length,
                    itemBuilder: (context, index) {
                      final item = stats[index];
                      final user = item['user'];
                      final count = item['count'];
                      final initials = '${user.firstName.isNotEmpty ? user.firstName[0] : ""}${user.lastName.isNotEmpty ? user.lastName[0] : ""}';
                      
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: index % 2 == 0 ? Colors.cyan : Colors.red,
                              child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('$count', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                Text(user.firstName, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),

              // Activities List
              Expanded(
                child: provider.isLoading && provider.activities.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : filteredList.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text("No Activities Found", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text("Try adjusting your filters", style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final act = filteredList[index];
                              final uInitials = act.user != null ? '${act.user!.firstName[0]}${act.user!.lastName[0]}' : '?';
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Icon
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(50)),
                                      child: Icon(_getActivityIcon(act.type), color: _getActivityIconColor(act.type), size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    
                                    // Title & Desc
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          RichText(
                                            text: TextSpan(
                                              style: const TextStyle(color: Colors.black, fontSize: 13),
                                              children: [
                                                const TextSpan(text: 'Title: ', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                                TextSpan(text: act.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                              ]
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            act.description,
                                            style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          )
                                        ],
                                      ),
                                    ),
                                    
                                    const SizedBox(width: 8),

                                    // User Avatar & Time
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(radius: 10, backgroundColor: Colors.redAccent, child: Text(uInitials, style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold))),
                                            const SizedBox(width: 4),
                                            Text(act.user?.firstName ?? '', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(_formatDate(act.createdAt), style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                                        
                                        if (act.relatedId != null)
                                          InkWell(
                                            onTap: () {
                                              // Future update: Link to TaskDetailScreen with relatedId
                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Open task: ${act.relatedId}')));
                                            },
                                            child: const Padding(
                                              padding: EdgeInsets.only(top: 4.0),
                                              child: Icon(Icons.open_in_new, size: 14, color: Colors.green),
                                            ),
                                          )
                                      ],
                                    ),
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

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    Map<String, String>? displayMap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 2),
          child: Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
        ),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
              onChanged: onChanged,
              items: items.map<DropdownMenuItem<String>>((String val) {
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(displayMap != null ? (displayMap[val] ?? val) : val),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
