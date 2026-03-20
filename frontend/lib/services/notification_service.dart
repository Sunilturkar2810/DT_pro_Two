import 'package:dio/dio.dart';
import '../config/api_constants.dart';
import 'dio_client.dart';

class NotificationService {
  final Dio _dio = DioClient().dio;

  Future<Map<String, dynamic>> getMyNotifications() async {
    final response = await _dio.get(ApiConstants.notifications);
    return response.data;
  }

  Future<void> markAllRead() async {
    await _dio.patch('${ApiConstants.notifications}/read-all');
  }

  Future<void> markOneRead(String id) async {
    await _dio.patch('${ApiConstants.notifications}/$id/read');
  }

  // ========== NOTIFICATION SETTINGS ==========
  Future<Map<String, dynamic>?> getNotificationSettings() async {
    try {
      final response = await _dio.get(ApiConstants.notificationSettings);
      if (response.data != null && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveNotificationSettings(Map<String, dynamic> data) async {
    await _dio.post(ApiConstants.notificationSettings, data: data);
  }

  // ========== TEMPLATES API (SYNCED WITH BACKEND REF) ==========
  Future<Map<String, dynamic>?> getTemplate(String event, String channel) async {
    try {
      // Backend expects: GET /notification-templates/:eventName/:channel
      final response = await _dio.get('${ApiConstants.notificationTemplates}/$event/$channel');
      return response.data;
    } catch (e) {
      print("❌ Error in NotificationService.getTemplate: $e");
      rethrow;
    }
  }

  Future<bool> saveTemplate(Map<String, dynamic> data) async {
    try {
      // Backend expects: POST /notification-templates
      final response = await _dio.post(ApiConstants.notificationTemplates, data: data);
      return response.data['success'] == true;
    } catch (e) {
      print("❌ Error in NotificationService.saveTemplate: $e");
      rethrow;
    }
  }
}
