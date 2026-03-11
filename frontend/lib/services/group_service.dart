import 'package:dio/dio.dart';
import '../config/api_constants.dart';
import 'dio_client.dart';

class GroupService {
  final Dio _dio = DioClient().dio;

  Future<List<dynamic>> getMyGroups() async {
    final response = await _dio.get(ApiConstants.groups);
    return response.data['data'] ?? [];
  }

  Future<Map<String, dynamic>> createGroup(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConstants.groups, data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> getGroupById(String id) async {
    final response = await _dio.get('${ApiConstants.groups}/$id');
    return response.data['data'];
  }

  Future<List<dynamic>> getGroupTasks(String id) async {
    final response = await _dio.get('${ApiConstants.groups}/$id/tasks');
    return response.data['data'] ?? [];
  }

  Future<Map<String, dynamic>> assignTaskToGroup(String id, Map<String, dynamic> data) async {
    final response = await _dio.post('${ApiConstants.groups}/$id/tasks', data: data);
    return response.data;
  }
}
