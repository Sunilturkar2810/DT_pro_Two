import 'package:flutter/material.dart';
import '../model/group_model.dart';
import '../services/group_service.dart';

class GroupProvider extends ChangeNotifier {
  final GroupService _service = GroupService();
  
  bool _isLoading = false;
  String? _errorMessage;
  List<GroupModel> _myGroups = [];
  GroupModel? _selectedGroup;
  List<dynamic> _groupTasks = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<GroupModel> get myGroups => _myGroups;
  GroupModel? get selectedGroup => _selectedGroup;
  List<dynamic> get groupTasks => _groupTasks;

  Future<void> fetchMyGroups() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rawData = await _service.getMyGroups();
      _myGroups = rawData.map((json) => GroupModel.fromJson(json)).toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createGroup(String name, String description, List<String> memberIds) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.createGroup({
        "name": name,
        "description": description,
        "memberIds": memberIds
      });
      await fetchMyGroups();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchGroupDetails(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _service.getGroupById(id);
      _selectedGroup = GroupModel.fromJson(data);
      _groupTasks = await _service.getGroupTasks(id);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> assignTaskToGroup(String groupId, Map<String, dynamic> taskData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.assignTaskToGroup(groupId, taskData);
      await fetchGroupDetails(groupId); // Refresh details and tasks
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
