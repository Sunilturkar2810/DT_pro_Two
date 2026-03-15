import 'package:flutter/material.dart';
import '../services/roles_service.dart';
import '../services/dio_client.dart';

class RolesProvider extends ChangeNotifier {
  final RolesService _service = RolesService(DioClient().dio);

  List<Map<String, dynamic>> _roles = [];
  Map<String, dynamic>? _selectedRole;
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get roles => _roles;
  Map<String, dynamic>? get selectedRole => _selectedRole;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ========== GET ALL ROLES ==========
  Future<void> fetchAllRoles() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _service.getAllRoles();
      _roles = List<Map<String, dynamic>>.from(response['roles'] ?? []);
      print('✅ All roles fetched: ${_roles.length} roles');
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Fetch all roles error: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== GET SINGLE ROLE ==========
  Future<void> fetchRoleWithPermissions(String roleId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _service.getRoleWithPermissions(roleId);
      _selectedRole = response['role'] as Map<String, dynamic>;
      print('✅ Role with permissions fetched: ${_selectedRole?['name']}');
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Fetch role error: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== CREATE ROLE ==========
  Future<bool> createRole({
    required String name,
    required String? description,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.createRole(
        name: name,
        description: description,
      );

      print('✅ Role created successfully: $name');
      // Refresh all roles
      await fetchAllRoles();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Create role error: $_errorMessage');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== UPDATE ROLE ==========
  Future<bool> updateRole({
    required String roleId,
    required String name,
    required String? description,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.updateRole(
        roleId: roleId,
        name: name,
        description: description,
      );

      print('✅ Role updated successfully');
      // Refresh all roles
      await fetchAllRoles();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Update role error: $_errorMessage');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== DELETE ROLE ==========
  Future<bool> deleteRole(String roleId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.deleteRole(roleId);
      print('✅ Role deleted successfully');
      // Refresh all roles
      await fetchAllRoles();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Delete role error: $_errorMessage');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== UPDATE ROLE PERMISSIONS ==========
  Future<bool> updateRolePermissions({
    required String roleId,
    required Map<String, bool> permissions,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _service.updateRolePermissions(
        roleId: roleId,
        permissions: permissions,
      );

      // Update selectedRole if it's the one being updated
      if (_selectedRole?['id'] == roleId) {
        _selectedRole?['permissions'] = response['data']['permissions'];
      }

      // Update in roles list
      final roleIndex = _roles.indexWhere((role) => role['id'] == roleId);
      if (roleIndex != -1) {
        _roles[roleIndex]['permissions'] = response['data']['permissions'];
      }

      print('✅ Role permissions updated successfully');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Update permissions error: $_errorMessage');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== GET ROLE BY ID (from cached list) ==========
  Map<String, dynamic>? getRoleById(String roleId) {
    try {
      return _roles.firstWhere((role) => role['id'] == roleId);
    } catch (e) {
      return null;
    }
  }

  // ========== GET DEFAULT ROLES ONLY ==========
  List<Map<String, dynamic>> getDefaultRoles() {
    return _roles.where((role) => role['isDefault'] == true).toList();
  }

  // ========== GET CUSTOM ROLES ONLY ==========
  List<Map<String, dynamic>> getCustomRoles() {
    return _roles.where((role) => role['isDefault'] == false).toList();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSelectedRole() {
    _selectedRole = null;
    notifyListeners();
  }
}
