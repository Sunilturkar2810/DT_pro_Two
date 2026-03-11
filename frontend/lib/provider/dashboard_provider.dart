import 'package:flutter/material.dart';
import '../services/dashboard_service.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardService _service = DashboardService();

  String _selectedFilter = "All Time";
  String _selectedTab = "My Report";
  String _selectedCategory = "Category";
  String _selectedStatus = "Status";
  String _searchQuery = "";
  
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  
  bool _isTableView = true;
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic> _taskStats = {
    "total": 0, "pending": 0, "inProgress": 0, "done": 0, "overdue": 0, "onTime": 0, "delayed": 0
  };
  List<dynamic> _categoryStats = [];
  List<String> _categories = [];

  String get selectedFilter => _selectedFilter;
  String get selectedTab => _selectedTab;
  String get selectedCategory => _selectedCategory;
  String get selectedStatus => _selectedStatus;
  String get searchQuery => _searchQuery;

  DateTime? get customStartDate => _customStartDate;
  DateTime? get customEndDate => _customEndDate;

  bool get isTableView => _isTableView;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic> get taskStats => _taskStats;
  List<dynamic> get categoryStats => _categoryStats;
  List<String> get categories => _categories;

  void setFilter(String filter, {DateTime? startDate, DateTime? endDate}) {
    _selectedFilter = filter;
    if (filter == 'Custom' && startDate != null && endDate != null) {
      _customStartDate = startDate;
      _customEndDate = endDate;
    } else if (filter != 'Custom') {
      _customStartDate = null;
      _customEndDate = null;
    }
    fetchDashboardStats();
    notifyListeners();
  }

  void setTab(String tab) {
    _selectedTab = tab;
    fetchDashboardStats();
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    fetchDashboardStats();
    notifyListeners();
  }

  void setStatus(String status) {
    _selectedStatus = status;
    fetchDashboardStats();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    fetchDashboardStats();
    notifyListeners();
  }

  void resetFilters() {
    _selectedFilter = "All Time";
    _selectedCategory = "Category";
    _selectedStatus = "Status";
    _searchQuery = "";
    fetchDashboardStats();
    notifyListeners();
  }

  void toggleView(bool isTable) {
    _isTableView = isTable;
    notifyListeners();
  }

  Future<void> fetchDashboardStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _service.fetchDashboardStats(
        filter: _selectedFilter,
        tab: _selectedTab,
        category: _selectedCategory,
        status: _selectedStatus,
        search: _searchQuery,
        startDate: _customStartDate?.toIso8601String().split('T')[0],
        endDate: _customEndDate?.toIso8601String().split('T')[0],
      );
      print("📊 Dashboard API Data: $data");
      if (data != null && data['success'] == true) {
        _taskStats = Map<String, dynamic>.from(data['stats'] ?? _taskStats);
        _categoryStats = List<dynamic>.from(data['tableData']?['employees'] ?? []);
        
        // Populate categories from the stats if needed or keep as is
        if (_selectedCategory == "Category" || _selectedCategory == "All") {
          // You could extract unique categories from categoryStats here if backend doesn't provide them
          _categories = _categoryStats.map((e) => e['category']?.toString() ?? "General").toSet().toList().cast<String>();
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
      print("❌ DashboardStats Error: $_errorMessage");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}