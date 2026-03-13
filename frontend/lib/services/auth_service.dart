import 'dart:async';
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

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConstants.register, data: data);
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Signup failed';
    }
  }

  Future<List<dynamic>> getAllUsers() async {
    try {
      final response = await _dio.get(ApiConstants.getAllUser);
      return response.data['users'] ?? [];
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to load users';
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _dio.delete('${ApiConstants.getAllUser}/$userId', data: {});
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to delete user';
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(ApiConstants.updateProfile, data: data);
      return response.data['data'] ?? response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to update profile';
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String workEmail) async {
    try {
      final response = await _dio.post(ApiConstants.forgotPassword, data: {
        'workEmail': workEmail,
      });
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Forgot password failed';
    }
  }

  Future<Map<String, dynamic>> resetPassword(String resetToken, String newPassword) async {
    try {
      final response = await _dio.post(ApiConstants.resetPassword, data: {
        'resetToken': resetToken,
        'newPassword': newPassword,
      });
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Reset password failed';
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
}