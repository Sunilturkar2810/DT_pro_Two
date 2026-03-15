import 'package:dio/dio.dart';
import '../config/api_constants.dart';

class SettingsService {
  final Dio _dio;

  SettingsService(this._dio);

  // General Settings
  Future<Map<String, dynamic>> getGeneralSettings() async {
    try {
      final response = await _dio.get('/settings/general');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateGeneralSettings({
    required String? companyName,
    required String? businessIndustry,
    required String? companySize,
  }) async {
    try {
      final response = await _dio.post(
        '/settings/general',
        data: {
          'companyName': companyName,
          'businessIndustry': businessIndustry,
          'companySize': companySize,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Task Update Settings
  Future<Map<String, dynamic>> getTaskUpdateSettings() async {
    try {
      final response = await _dio.get('/settings/task-update');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateTaskUpdateSettings({
    required bool remarksRequired,
    required bool attachmentsRequired,
    required bool imagesRequired,
  }) async {
    try {
      final response = await _dio.post(
        '/settings/task-update',
        data: {
          'remarksRequired': remarksRequired,
          'attachmentsRequired': attachmentsRequired,
          'imagesRequired': imagesRequired,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Notification Settings
  Future<Map<String, dynamic>> getNotificationSettings() async {
    try {
      final response = await _dio.get('/settings/notifications');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateNotificationSettings({
    required bool informaticsNotifications,
    required bool emailNotifications,
    required bool dailyReminder,
    required bool emailReminders,
    required String taskReminderTime,
    required bool weeklyOnly,
    required List<String> reminderDays,
    required Map<String, dynamic> notificationChannels,
    required Map<String, dynamic> notificationFrequency,
  }) async {
    try {
      final response = await _dio.post(
        '/settings/notifications',
        data: {
          'informaticsNotifications': informaticsNotifications,
          'emailNotifications': emailNotifications,
          'dailyReminder': dailyReminder,
          'emailReminders': emailReminders,
          'taskReminderTime': taskReminderTime,
          'weeklyOnly': weeklyOnly,
          'reminderDays': reminderDays,
          'notificationChannels': notificationChannels,
          'notificationFrequency': notificationFrequency,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
