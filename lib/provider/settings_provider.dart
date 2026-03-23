import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/dio_client.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsService _service = SettingsService(DioClient().dio);

  // General Settings
  Map<String, dynamic> _generalSettings = {
    'companyName': '',
    'businessIndustry': '',
    'companySize': ''
  };

  // Task Update Settings
  Map<String, dynamic> _taskUpdateSettings = {
    'remarksRequired': true,
    'attachmentsRequired': false,
    'imagesRequired': false
  };

  // Notification Settings
  Map<String, dynamic> _notificationSettings = {
    'informaticsNotifications': true,
    'emailNotifications': true,
    'dailyReminder': true,
    'emailReminders': true,
    'taskReminderTime': '09:00',
    'weeklyOnly': false,
    'reminderDays': [],
    'notificationChannels': {},
    'notificationFrequency': {}
  };

  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  Map<String, dynamic> get generalSettings => _generalSettings;
  Map<String, dynamic> get taskUpdateSettings => _taskUpdateSettings;
  Map<String, dynamic> get notificationSettings => _notificationSettings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ========== GENERAL SETTINGS (Not available in new backend) ==========
  Future<void> fetchGeneralSettings() async {
    // ⚠️ Not available in new backend — silently skip
    return;
  }

  Future<bool> updateGeneralSettings({
    required String? companyName,
    required String? businessIndustry,
    required String? companySize,
  }) async {
    // ⚠️ Not available in new backend
    _generalSettings = {
      'companyName': companyName ?? '',
      'businessIndustry': businessIndustry ?? '',
      'companySize': companySize ?? ''
    };
    notifyListeners();
    return true; // simulate success
  }

  // ========== TASK UPDATE SETTINGS (Not available in new backend) ==========
  Future<void> fetchTaskUpdateSettings() async {
    // ⚠️ Not available in new backend — silently skip
    return;
  }

  Future<bool> updateTaskUpdateSettings({
    required bool remarksRequired,
    required bool attachmentsRequired,
    required bool imagesRequired,
  }) async {
    // ⚠️ Not available in new backend — save locally only
    _taskUpdateSettings = {
      'remarksRequired': remarksRequired,
      'attachmentsRequired': attachmentsRequired,
      'imagesRequired': imagesRequired
    };
    notifyListeners();
    return true; // simulate success
  }

  // ========== NOTIFICATION SETTINGS ==========
  Future<void> fetchNotificationSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _service.getNotificationSettings();
      _notificationSettings = {
        'informaticsNotifications': data['informaticsNotifications'] ?? true,
        'emailNotifications': data['emailNotifications'] ?? true,
        'dailyReminder': data['dailyReminder'] ?? true,
        'emailReminders': data['emailReminders'] ?? true,
        'taskReminderTime': data['taskReminderTime'] ?? '09:00',
        'weeklyOnly': data['weeklyOnly'] ?? false,
        'reminderDays': data['reminderDays'] ?? [],
        'notificationChannels': data['notificationChannels'] ?? {},
        'notificationFrequency': data['notificationFrequency'] ?? {}
      };
      print('✅ Notification settings fetched');
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Fetch notification settings error: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateNotificationSettings({
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final settingsMap = {
        'informaticsNotifications': informaticsNotifications,
        'emailNotifications': emailNotifications,
        'dailyReminder': dailyReminder,
        'emailReminders': emailReminders,
        'taskReminderTime': taskReminderTime,
        'weeklyOnly': weeklyOnly,
        'reminderDays': reminderDays,
        'notificationChannels': notificationChannels,
        'notificationFrequency': notificationFrequency
      };
      await _service.updateNotificationSettings(
        informaticsNotifications: informaticsNotifications,
        emailNotifications: emailNotifications,
        dailyReminder: dailyReminder,
        emailReminders: emailReminders,
        taskReminderTime: taskReminderTime,
        weeklyOnly: weeklyOnly,
        reminderDays: reminderDays,
        notificationChannels: notificationChannels,
        notificationFrequency: notificationFrequency,
      );
      _notificationSettings = settingsMap;
      print('✅ Notification settings updated successfully');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Update notification settings error: $_errorMessage');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== CHANGE PASSWORD (NEW) ==========
  /// PUT /auth/users/:userId/credentials
  Future<bool> changeCredentials({
    required String userId,
    required String oldPassword,
    required String newPassword,
    String? newEmail,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.changeCredentials(
        userId: userId,
        oldPassword: oldPassword,
        newPassword: newPassword,
        newEmail: newEmail,
      );
      print('✅ Credentials changed successfully');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Change credentials error: $_errorMessage');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== BULK FETCH ALL SETTINGS ==========
  Future<void> fetchAllSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([
        fetchGeneralSettings(),
        fetchTaskUpdateSettings(),
        fetchNotificationSettings()
      ]);
      print('✅ All settings fetched successfully');
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Fetch all settings error: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
