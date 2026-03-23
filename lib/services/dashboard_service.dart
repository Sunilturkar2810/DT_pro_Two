import 'package:dio/dio.dart';
import '../config/api_constants.dart';
import 'dio_client.dart';

// ⚠️ New backend does NOT have /dashboard/stats endpoint.
// Stats are now derived client-side from /delegations data.
class DashboardService {
  final Dio _dio = DioClient().dio;

  /// Fetches all delegations and computes dashboard stats locally
  Future<Map<String, dynamic>?> fetchDashboardStats({
    String filter = 'All Time',
    String tab = 'My Report',
    String category = 'Category',
    String status = 'Status',
    String? frequency,
    String? tag,
    String? userId,
    String search = '',
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _dio.get(ApiConstants.delegations);
      final data = response.data;
      List<dynamic> delegations = [];
      if (data is Map) {
        delegations = data['data'] ?? [];
      } else if (data is List) {
        delegations = data;
      }

      // 1. Initial Parsing
      List<Map<String, dynamic>> dList = [for (var map in delegations) (map as Map<String, dynamic>)];
      
      // 2. APPLY FILTERS 🔄
      // Date Filter
      if (filter != 'All Time') {
        final now = DateTime.now();
        DateTime? start;
        DateTime? end;

        if (filter == 'Today') {
          start = DateTime(now.year, now.month, now.day);
          end = start.add(const Duration(days: 1));
        } else if (filter == 'Yesterday') {
          start = DateTime(now.year, now.month, now.day - 1);
          end = DateTime(now.year, now.month, now.day);
        } else if (filter == 'This Week') {
          start = now.subtract(Duration(days: now.weekday - 1));
          start = DateTime(start.year, start.month, start.day);
          end = start.add(const Duration(days: 7));
        } else if (filter == 'Custom' && startDate != null && endDate != null) {
          start = DateTime.tryParse(startDate);
          end = DateTime.tryParse(endDate)?.add(const Duration(days: 1));
        }

        if (start != null && end != null) {
          dList = dList.where((d) {
            final cr = DateTime.tryParse(d['createdAt'] ?? d['date'] ?? '');
            return cr != null && cr.isAfter(start!) && cr.isBefore(end!);
          }).toList();
        }
      }

      // User Filter
      if (userId != null && userId.isNotEmpty && userId != 'All') {
        dList = dList.where((d) => d['doerId'] == userId || d['assignerId'] == userId).toList();
      }

      // Category Filter
      if (category != 'Category' && category != 'All' && category != 'General') {
        dList = dList.where((d) => d['category'] == category).toList();
      }

      // Tag Filter
      if (tag != null && tag != 'Tag' && tag != 'All') {
        // Tag search in delegationName or description for now as fallback, or if backend has tags list find it
        dList = dList.where((d) {
           final title = (d['taskTitle'] ?? '').toString().toLowerCase();
           final desc = (d['description'] ?? '').toString().toLowerCase();
           final check = tag.toLowerCase();
           return title.contains(check) || desc.contains(check);
        }).toList();
      }

      // Frequency Filter
      if (frequency != null && frequency != 'Frequency' && frequency != 'All') {
        // Logic for frequency filtering (Assuming it's stored in description or we have a field)
        dList = dList.where((d) => (d['description'] ?? '').toString().contains(frequency)).toList();
      }

      // Search Filter
      if (search.isNotEmpty) {
        final q = search.toLowerCase();
        dList = dList.where((d) {
          final t = (d['taskTitle'] ?? d['delegationName'] ?? '').toString().toLowerCase();
          final de = (d['description'] ?? '').toString().toLowerCase();
          return t.contains(q) || de.contains(q);
        }).toList();
      }

      // 3. Calculate basic stats 📊
      final total = dList.length;
      final completed = dList.where((d) => d['status'] == 'Completed').length;
      final inProgress = dList.where((d) => d['status'] == 'In Progress').length;
      final pending = dList.where((d) => d['status'] == 'Pending').length;
      
      final overdueCount = dList.where((d) {
        final due = d['dueDate'];
        if (due == null) return false;
        return DateTime.tryParse(due)?.isBefore(DateTime.now()) == true && d['status'] != 'Completed';
      }).length;

      final onTimeCount = dList.where((d) {
        if (d['status'] != 'Completed') return false;
        final due = d['dueDate'];
        final updated = d['updatedAt'];
        if (due == null || updated == null) return true;
        return DateTime.tryParse(due)?.isAfter(DateTime.tryParse(updated) ?? DateTime.now()) == true;
      }).length;

      // 4. Build Table / Bar Chart Data based on filtered list!
      List<Map<String, dynamic>> tableData = [];
      Map<String, Map<String, dynamic>> grouped = {};
      
      for (var task in dList) {
        String key = "General";
        if (tab == 'Employees') {
          key = "${task['doerFirstName'] ?? ''} ${task['doerLastName'] ?? ''}".trim();
          if (key.isEmpty) key = "Unknown Employee";
        } else if (tab == 'Delegated') {
          key = "${task['doerFirstName'] ?? ''} ${task['doerLastName'] ?? ''}".trim();
          if (key.isEmpty) key = "Unknown Assignee";
        } else if (tab == 'Categories' || tab == 'My Report') {
          key = task['category'] ?? 'Uncategorized';
        } else if (tab == 'Groups') {
          key = task['groupName'] ?? 'No Group';
        } else if (tab == 'Daily') {
          final cr = task['createdAt'] ?? task['date'] ?? '';
          if (cr.isNotEmpty) {
            final dObj = DateTime.tryParse(cr);
            if (dObj != null) key = "${dObj.year}-${dObj.month.toString().padLeft(2, '0')}-${dObj.day.toString().padLeft(2, '0')}";
          } else { key = "Unknown Date"; }
        } else if (tab == 'Monthly') {
          final cr = task['createdAt'] ?? task['date'] ?? '';
          if (cr.isNotEmpty) {
            final dObj = DateTime.tryParse(cr);
            if (dObj != null) key = "${_getMonthName(dObj.month)} ${dObj.year}";
          } else { key = "Unknown Month"; }
        } else if (tab == 'Tags') {
          key = "Un-tagged"; // Simple fallback, complex parsing can be added later
          if (task['tags'] != null) {
            if (task['tags'] is List && (task['tags'] as List).isNotEmpty) {
              key = (task['tags'] as List).first['text'] ?? (task['tags'] as List).first.toString();
            } else if (task['tags'] is String && (task['tags'] as String).isNotEmpty) {
              key = task['tags'];
            }
          }
        }
        
        if (!grouped.containsKey(key)) {
          grouped[key] = { "name": key, "total": 0, "score": 0, "overdue": 0, "pending": 0, "in_progress": 0, "in_time": 0, "delayed": 0 };
        }
        final r = grouped[key]!;
        r['total']++;
        final s = task['status'];
        if (s == 'Overdue') r['overdue']++;
        else if (s == 'Pending') r['pending']++;
        else if (s == 'In Progress') r['in_progress']++;
        else if (s == 'Completed') r['in_time']++;
        
        if (s != 'Completed' && task['dueDate'] != null && DateTime.tryParse(task['dueDate'])?.isBefore(DateTime.now()) == true) {
          r['delayed']++;
        }
      }

      for (var r in grouped.values) {
        int t = r['total'] == 0 ? 1 : r['total'];
        r['score'] = '${((r['in_time'] / t) * 100).toStringAsFixed(1)}%';
        tableData.add(r);
      }
      tableData.sort((a, b) => b['total'].compareTo(a['total']));

      // Handle Overdue literally for the React-like list
      List<dynamic> overdueTasksList = [];
      if (tab == 'Overdue') {
        overdueTasksList = dList.where((d) => d['status'] == 'Overdue' || (d['status'] != 'Completed' && d['dueDate'] != null && DateTime.tryParse(d['dueDate'])?.isBefore(DateTime.now()) == true)).toList();
      }

      // Build Bar Chart Data
      Map<String, Map<String, int>> empGrouped = {};
      Map<String, Map<String, int>> catGrouped = {};
      Map<String, Map<String, int>> dailyGrouped = {};
      Map<String, Map<String, int>> monthlyGrouped = {};
      Map<String, Map<String, int>> delGrouped = {};

      void addToGroup(Map<String, Map<String, int>> group, String key, String status) {
        if (!group.containsKey(key)) {
          group[key] = {"Pending": 0, "Overdue": 0, "In Progress": 0, "Completed": 0};
        }
        final statusKey = status == "Done" ? "Completed" : status;
        if (group[key]!.containsKey(statusKey)) {
          group[key]![statusKey] = group[key]![statusKey]! + 1;
        } else {
          group[key]!["Pending"] = group[key]!["Pending"]! + 1;
        }
      }

      for (var task in dList) {
        final status = task['status'] ?? 'Pending';
        
        // Assignee (Doer) Name
        final doerF = task['doerFirstName'] ?? task['assigneeFirstName'] ?? task['assignee_first_name'] ?? '';
        final doerL = task['doerLastName'] ?? task['assigneeLastName'] ?? task['assignee_last_name'] ?? '';
        final empName = "$doerF $doerL".trim();
        if (empName.isNotEmpty) addToGroup(empGrouped, empName, status);

        // Category Wise
        final catName = task['category'] ?? 'General';
        addToGroup(catGrouped, catName, status);

        // Daily/Monthly
        final createdAt = task['createdAt'] ?? task['date'] ?? '';
        if (createdAt.isNotEmpty) {
          final dateObj = DateTime.tryParse(createdAt);
          if (dateObj != null) {
            final dayStr = "${dateObj.year}-${dateObj.month.toString().padLeft(2, '0')}-${dateObj.day.toString().padLeft(2, '0')}";
            final monthStr = "${_getMonthName(dateObj.month)} ${dateObj.year}";
            addToGroup(dailyGrouped, dayStr, status);
            addToGroup(monthlyGrouped, monthStr, status);
          }
        }

        // Assigner (Delegator) Name
        final delF = task['delegatorFirstName'] ?? task['delegator_first_name'] ?? task['assignerFirstName'] ?? task['assigner_first_name'] ?? '';
        final delL = task['delegatorLastName'] ?? task['delegator_last_name'] ?? task['assignerLastName'] ?? task['assigner_last_name'] ?? '';
        final delName = "$delF $delL".trim();
        if (delName.isNotEmpty) addToGroup(delGrouped, delName, status);
      }

      return {
        'total': total,
        'completed': completed,
        'inProgress': inProgress,
        'pending': pending,
        'overdue': overdueCount,
        'onTime': onTimeCount,
        'delayed': overdueCount, // Using overdue as delayed for simplicity
        'tableData': tableData,
        'overdueTasks': overdueTasksList,
        'charts': {
          'employeeWise': empGrouped,
          'categoryWise': catGrouped,
          'dailyReport': dailyGrouped,
          'monthlyReport': monthlyGrouped,
          'delegatedReport': delGrouped,
        }
      };
    } catch (e) {
      rethrow;
    }
  }

  String _getMonthName(int month) {
    const names = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return names[month];
  }
}

