import 'package:dio/dio.dart';
import '../config/api_constants.dart';
import 'dio_client.dart';

class GroupService {
  final Dio _dio = DioClient().dio;

  /// GET /groups/list — all groups (admin sees all, user sees their own)
  Future<List<dynamic>> getMyGroups() async {
    try {
      final response = await _dio.get(ApiConstants.groupsList);
      final data = response.data;
      if (data is Map) return data['data'] ?? [];
      if (data is List) return data;
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// POST /groups/create
  Future<Map<String, dynamic>> createGroup(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConstants.groupsCreate, data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// GET /groups/:id
  Future<Map<String, dynamic>> getGroupById(String id) async {
    try {
      final response = await _dio.get(ApiConstants.groupById(id));
      final data = response.data;
      if (data is Map && data['data'] != null) return Map<String, dynamic>.from(data['data']);
      return Map<String, dynamic>.from(data ?? {});
    } catch (e) {
      rethrow;
    }
  }

  /// GET /groups/:id/members — members with full user details
  Future<List<dynamic>> getGroupMembers(String id) async {
    try {
      final response = await _dio.get(ApiConstants.groupMembers(id));
      final data = response.data;
      if (data is Map) return data['data'] ?? [];
      if (data is List) return data;
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// PATCH /groups/:id/update
  Future<Map<String, dynamic>> updateGroup(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch(ApiConstants.groupUpdate(id), data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// GET /delegations?groupId=:id — group tasks
  Future<List<dynamic>> getGroupTasks(String id) async {
    try {
      final response = await _dio.get(ApiConstants.delegations, queryParameters: {'groupId': id});
      final data = response.data;
      if (data is Map) return data['data'] ?? [];
      if (data is List) return data;
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// POST /delegations — creating a group task
  Future<Map<String, dynamic>> createGroupTask(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConstants.delegations, data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}

