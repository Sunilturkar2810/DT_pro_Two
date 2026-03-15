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

  // ========== GENERAL SETTINGS ==========
  Future<void> fetchGeneralSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _service.getGeneralSettings();
      _generalSettings = {
        'companyName': data['companyName'] ?? '',
        'businessIndustry': data['businessIndustry'] ?? '',
        'companySize': data['companySize'] ?? ''
      };
      print('✅ General settings fetched');
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Fetch general settings error: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateGeneralSettings({
    required String? companyName,
    required String? businessIndustry,
    required String? companySize,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.updateGeneralSettings(
        companyName: companyName,
        businessIndustry: businessIndustry,
        companySize: companySize,
      );

      _generalSettings = {
        'companyName': companyName ?? '',
        'businessIndustry': businessIndustry ?? '',
        'companySize': companySize ?? ''
      };

      print('✅ General settings updated successfully');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Update general settings error: $_errorMessage');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== TASK UPDATE SETTINGS ==========
  Future<void> fetchTaskUpdateSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _service.getTaskUpdateSettings();
      _taskUpdateSettings = {
        'remarksRequired': data['remarksRequired'] ?? true,
        'attachmentsRequired': data['attachmentsRequired'] ?? false,
        'imagesRequired': data['imagesRequired'] ?? false
      };
      print('✅ Task update settings fetched');
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Fetch task update settings error: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateTaskUpdateSettings({
    required bool remarksRequired,
    required bool attachmentsRequired,
    required bool imagesRequired,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.updateTaskUpdateSettings(
        remarksRequired: remarksRequired,
        attachmentsRequired: attachmentsRequired,
        imagesRequired: imagesRequired,
      );

      _taskUpdateSettings = {
        'remarksRequired': remarksRequired,
        'attachmentsRequired': attachmentsRequired,
        'imagesRequired': imagesRequired
      };

      print('✅ Task update settings saved successfully');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Update task update settings error: $_errorMessage');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

      _notificationSettings = {
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
