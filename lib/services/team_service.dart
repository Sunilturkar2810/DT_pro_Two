import 'package:dio/dio.dart';
import '../config/api_constants.dart';
import 'dio_client.dart';

class TeamService {
  final Dio _dio = DioClient().dio;

  Future<Map<String, dynamic>> createTeam(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiConstants.teams, data: data);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getMyTeamMembers() async {
    try {
      final response = await _dio.get(ApiConstants.myTeamMembers);
      return response.data is List ? response.data : (response.data['data'] ?? []);
    } catch (e) {
      rethrow;
    }
  }
}
