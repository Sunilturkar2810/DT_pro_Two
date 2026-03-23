import 'package:dio/dio.dart';
import '../config/api_constants.dart';

class RolesService {
  final Dio _dio;

  RolesService(this._dio);

  // Get all roles with permissions
  Future<List<dynamic>> getAllRoles() async {
    try {
      final response = await _dio.get('/roles');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Get single role with permissions
  Future<Map<String, dynamic>> getRoleWithPermissions(String roleId) async {
    try {
      final response = await _dio.get('/roles/$roleId');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Create custom role
  Future<Map<String, dynamic>> createRole({
    required String name,
    required String? description,
  }) async {
    try {
      final response = await _dio.post(
        '/roles',
        data: {
          'name': name,
          'description': description,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Update role
  Future<Map<String, dynamic>> updateRole({
    required String roleId,
    required String name,
    required String? description,
  }) async {
    try {
      final response = await _dio.put(
        '/roles/$roleId',
        data: {
          'name': name,
          'description': description,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Delete role
  Future<Map<String, dynamic>> deleteRole(String roleId) async {
    try {
      final response = await _dio.delete(
        '/roles/$roleId',
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Update role permissions
  Future<Map<String, dynamic>> updateRolePermissions({
    required String roleId,
    required Map<String, dynamic> permissions,
  }) async {
    try {
      final response = await _dio.put(
        '/roles/$roleId',
        data: {
          'permissions': permissions,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
