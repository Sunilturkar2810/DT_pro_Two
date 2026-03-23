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
      // ✅ New backend: getAllRoles returns List<dynamic> directly
      final response = await _service.getAllRoles();
      _roles = response.map((e) => Map<String, dynamic>.from(e)).toList();
      print('✅ All roles fetched: ${_roles.length} roles');
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Fetch all roles error: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== GET SINGLE ROLE (Not available via separate endpoint in new backend) ==========
  Future<void> fetchRoleWithPermissions(String roleId) async {
    // Fetch from cached list
    _selectedRole = getRoleById(roleId);
    notifyListeners();
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

  // ========== UPDATE ROLE (Not available in new backend) ==========
  Future<bool> updateRole({
    required String roleId,
    required String name,
    required String? description,
  }) async {
    // ⚠️ Not available in new backend
    _errorMessage = 'Update role not available in current backend';
    notifyListeners();
    return false;
  }

  // ========== DELETE ROLE (Not available in new backend) ==========
  Future<bool> deleteRole(String roleId) async {
    // ⚠️ Not available in new backend
    _errorMessage = 'Delete role not available in current backend';
    notifyListeners();
    return false;
  }

  // ========== UPDATE ROLE PERMISSIONS (Not available in new backend) ==========
  Future<bool> updateRolePermissions({
    required String roleId,
    required Map<String, bool> permissions,
  }) async {
    // ⚠️ Not available in new backend
    _errorMessage = 'Update permissions not available in current backend';
    notifyListeners();
    return false;
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
