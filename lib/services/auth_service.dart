import 'dart:async';
import 'dart:io';
import 'package:d_table_delegate_system/config/api_constants.dart';
import 'package:d_table_delegate_system/services/dio_client.dart';
import 'package:dio/dio.dart';



class AuthService {
  final Dio _dio = DioClient().dio;

  Future<Map<String, dynamic>> login(String workEmail, String password) async {
    try {
      final response = await _dio.post(ApiConstants.login, data: {
        'workEmail': workEmail,
        'password': password,
      });
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Login failed';
    }
  }

  /// ⚠️ Only ADMIN/MANAGER can call this — token required
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConstants.register, data: data);
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Signup failed';
    }
  }

  /// Returns direct List (new backend sends array directly, not {users:[]})
  Future<List<dynamic>> getAllUsers() async {
    try {
      final response = await _dio.get(ApiConstants.getAllUser);
      final data = response.data;
      if (data is List) return data;
      if (data is Map) return data['users'] ?? data['data'] ?? [];
      return [];
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to load users';
    }
  }

  /// Get current user profile details — GET /auth/me
  Future<Map<String, dynamic>> fetchMe() async {
    try {
      final response = await _dio.get(ApiConstants.me);
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to fetch user profile';
    }
  }

  /// Update any user's profile — PUT /auth/users/:userId
  Future<Map<String, dynamic>> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(ApiConstants.userById(userId), data: data);
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to update user';
    }
  }

  /// Update own profile — same route PUT /auth/users/:userId
  Future<Map<String, dynamic>> updateProfile(String userId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(ApiConstants.userById(userId), data: data);
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to update profile';
    }
  }

  /// Upload profile image
  Future<Map<String, dynamic>> uploadProfileImage(File file) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
      });
      final response = await _dio.post(
        ApiConstants.uploadProfileImage,
        data: formData,
        options: Options(headers: {"Content-Type": "multipart/form-data"}),
      );
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to upload profile image';
    }
  }

  /// Change password/email — PUT /auth/users/:userId/credentials
  /// Body: { oldPassword, newPassword, newEmail (optional) }
  Future<Map<String, dynamic>> updateCredentials(String userId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(ApiConstants.userCredentials(userId), data: data);
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to update credentials';
    }
  }

  /// Delete all tasks of a user — DELETE /auth/users/:userId/tasks
  Future<Map<String, dynamic>> deleteUserTasks(String userId, String confirmEmail) async {
    try {
      final response = await _dio.delete(
        ApiConstants.userDeleteTasks(userId),
        data: {'confirmEmail': confirmEmail},
      );
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to delete user tasks';
    }
  }

  /// Delete a user permanently — DELETE /auth/users/:userId
  Future<void> deleteUser(String userId) async {
    try {
      await _dio.delete(ApiConstants.userById(userId));
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to delete user';
    }
  }

  Future<List<dynamic>> getRoles() async {
    try {
      final response = await _dio.get(ApiConstants.getRoles);
      final data = response.data;
      if (data is List) return data;
      if (data is Map) return data['roles'] ?? data['data'] ?? [];
      return [];
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to load roles';
    }
  }

  Future<Map<String, dynamic>> createRole(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConstants.getRoles, data: data);
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to create role';
    }
  }

  Future<Map<String, dynamic>> updateTeamMember(String memberId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('${ApiConstants.baseUrl}/team/members/$memberId', data: data);
      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to update team member';
    }
  }

  // Bulk Register Users
  Future<Map<String, dynamic>> bulkRegister(List<Map<String, dynamic>> users) async {
    try {
      final response = await _dio.post(ApiConstants.bulkRegister, data: {'users': users});
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to bulk register users');
    }
  }
}