import 'package:dio/dio.dart';
import '../config/api_constants.dart';
import 'dio_client.dart';

class NotificationService {
  final Dio _dio = DioClient().dio;

  Future<Map<String, dynamic>> getMyNotifications() async {
    final response = await _dio.get(ApiConstants.notifications);
    return response.data; // Contains 'count', 'unreadCount', 'data'
  }

  Future<void> markAllRead() async {
    await _dio.patch('${ApiConstants.notifications}/read-all');
  }

  Future<void> markOneRead(String id) async {
    await _dio.patch('${ApiConstants.notifications}/$id/read');
  }
}
