import 'dart:io';
import 'package:flutter/material.dart';
import '../model/group_model.dart';
import '../services/group_service.dart';
import '../services/delegation_service.dart';

class GroupProvider extends ChangeNotifier {
  final GroupService _service = GroupService();
  final DelegationService _delegationService = DelegationService();
  
  bool _isLoading = false;
  String? _errorMessage;
  List<GroupModel> _myGroups = [];
  GroupModel? _selectedGroup;
  List<dynamic> _groupTasks = [];
  List<dynamic> _groupMembers = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<GroupModel> get myGroups => _myGroups;
  GroupModel? get selectedGroup => _selectedGroup;
  List<dynamic> get groupTasks => _groupTasks;
  List<dynamic> get groupMembers => _groupMembers;

  int get myGroupsCount => _myGroups.length;

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

  Future<bool> createGroup(String name, String description, List<String> memberIds, {File? image}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String? photoUrl;
      if (image != null) {
        photoUrl = await _delegationService.uploadFile(image, folder: 'groups');
      }

      await _service.createGroup({
        "name": name,
        "description": description,
        "memberIds": memberIds,
        "photo": photoUrl, // Backend usually expects "photo" or "image"
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
    _errorMessage = null;
    notifyListeners();
    try {
      // 1. Get Group Info
      final data = await _service.getGroupById(id);
      _selectedGroup = GroupModel.fromJson(data);

      // 2. Get Group Tasks (Delegations with groupId=id)
      _groupTasks = await _service.getGroupTasks(id);

      // 3. Get Group Members
      _groupMembers = await _service.getGroupMembers(id);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateGroup(String groupId, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.updateGroup(groupId, data);
      await fetchMyGroups();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> assignTaskToGroup(String groupId, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Web behavior: Call delegations endpoint with groupId in the payload
      final payload = {
        ...data,
        'groupId': groupId,
      };
      
      // Use the generic delegation service or just dio here
      // For now, let's stick to a clean implementation in provider
      await _service.createGroupTask(payload);
      
      await fetchGroupDetails(groupId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
