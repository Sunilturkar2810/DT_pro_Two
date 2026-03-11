
import 'package:d_table_delegate_system/config/api_constants.dart';
import 'package:d_table_delegate_system/model/user_model.dart';
import 'package:d_table_delegate_system/services/dio_client.dart';
import 'package:dio/dio.dart';

class UserService {
  final Dio _dio = DioClient().dio;

  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _dio.get(ApiConstants.getAllUser);
      final dynamic responseData = response.data;
      List<dynamic> usersList = [];
      if (responseData is Map) {
        usersList = responseData['users'] ?? responseData['data'] ?? [];
      } else if (responseData is List) {
        usersList = responseData;
      }
      return usersList.map((u) => UserModel.fromJson(u)).toList();
    } catch (e) {
      print("❌ User Service Error: $e");
      rethrow;
    }
  }

  Future<List<UserModel>> getMyTeam() async {
    try {
      final response = await _dio.get(ApiConstants.getMyTeam);
      final dynamic responseData = response.data;
      List<dynamic> usersList = [];
      if (responseData is Map) {
        usersList = responseData['users'] ?? responseData['team'] ?? responseData['data'] ?? [];
      } else if (responseData is List) {
        usersList = responseData;
      }
      return usersList.map((u) => UserModel.fromJson(u)).toList();
    } catch (e) {
      print("❌ User Service Error (Team): $e");
      rethrow;
    }
  }

  /// Fetch member profile + task stats from /reports/member/:userId
  Future<Map<String, dynamic>> getMemberProfile(String userId) async {
    try {
      final response = await _dio.get('${ApiConstants.reportMemberProfile}/$userId');
      final data = response.data;
      if (data is Map && data['success'] == true) {
        return Map<String, dynamic>.from(data['data']);
      }
      return {};
    } catch (e) {
      print("❌ Member Profile Error: $e");
      rethrow;
    }
  }
}