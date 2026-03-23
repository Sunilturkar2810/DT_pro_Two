import 'package:flutter/material.dart';
import '../model/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();
  
  bool _isLoading = false;
  String? _errorMessage;
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;

  // Settings & Templates States
  bool whatsappNotifications = false;
  bool emailNotifications = false;
  String timezone = 'Asia/Kolkata';
  String dailyReminderTime = '09:00';
  bool whatsappReminders = false;
  bool emailReminders = false;
  bool dailyTaskReport = false;
  List<String> weeklyOffs = ['Sunday'];
  Map<String, dynamic> notificationChannels = {};
  Map<String, dynamic> notificationFrequency = {};

  // Template States
  Map<String, dynamic>? activeTemplate;
  bool isTemplateLoading = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  // ========== NOTIFICATION LIST ==========
  Future<void> fetchNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final rawData = await _service.getMyNotifications();
      _unreadCount = rawData['unreadCount'] ?? 0;
      final List<dynamic> listData = rawData['data'] ?? [];
      _notifications = listData.map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== FETCH SETTINGS ==========
  Future<void> fetchNotificationSettings() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _service.getNotificationSettings();
      if (response != null) {
        whatsappNotifications = response['whatsappNotifications'] ?? false;
        emailNotifications = response['emailNotifications'] ?? false;
        timezone = response['timezone'] ?? 'Asia/Kolkata';
        dailyReminderTime = response['dailyReminderTime'] ?? '09:00';
        whatsappReminders = response['whatsappReminders'] ?? false;
        emailReminders = response['emailReminders'] ?? false;
        dailyTaskReport = response['dailyTaskReport'] ?? false;
        weeklyOffs = List<String>.from(response['weeklyOffs'] ?? ['Sunday']);
        notificationChannels = Map<String, dynamic>.from(response['notificationChannels'] ?? {});
        notificationFrequency = Map<String, dynamic>.from(response['notificationFrequency'] ?? {});
      }
    } catch (e) {
      print("❌ Error fetching notification settings: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== SAVE SETTINGS ==========
  Future<void> saveSettings() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = {
        'whatsappNotifications': whatsappNotifications,
        'emailNotifications': emailNotifications,
        'timezone': timezone,
        'dailyReminderTime': dailyReminderTime,
        'whatsappReminders': whatsappReminders,
        'emailReminders': emailReminders,
        'dailyTaskReport': dailyTaskReport,
        'weeklyOffs': weeklyOffs,
        'notificationChannels': notificationChannels,
        'notificationFrequency': notificationFrequency,
      };
      await _service.saveNotificationSettings(data);
    } catch (e) {
      print("❌ Error saving settings: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== TEMPLATES LOGIC (FROM WEB REF) ==========
  Future<void> fetchTemplate(String event, String channel) async {
    isTemplateLoading = true;
    activeTemplate = null;
    notifyListeners();
    try {
      final response = await _service.getTemplate(event, channel);
      if (response != null && response['success'] == true) {
        activeTemplate = response['data'];
      }
    } catch (e) {
      print("❌ Error fetching template: $e");
    } finally {
      isTemplateLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveTemplate(Map<String, dynamic> data) async {
    isTemplateLoading = true;
    notifyListeners();
    try {
      final success = await _service.saveTemplate(data);
      if (success) {
        // Optionally refresh local state
      }
      return success;
    } catch (e) {
      print("❌ Error saving template: $e");
      return false;
    } finally {
      isTemplateLoading = false;
      notifyListeners();
    }
  }

  // UI Helper Methods
  void updateGlobal(String key, dynamic value) {
    if (key == 'whatsappNotifications') whatsappNotifications = value;
    if (key == 'emailNotifications') emailNotifications = value;
    if (key == 'timezone') timezone = value;
    if (key == 'whatsappReminders') whatsappReminders = value;
    if (key == 'emailReminders') emailReminders = value;
    if (key == 'dailyTaskReport') dailyTaskReport = value;
    notifyListeners();
  }

  void updateReminderTime(String time) {
    dailyReminderTime = time;
    notifyListeners();
  }

  void toggleWeeklyOff(String day) {
    if (weeklyOffs.contains(day)) {
      weeklyOffs.remove(day);
    } else {
      weeklyOffs.add(day);
    }
    notifyListeners();
  }

  void toggleChannel(String event, String role) {
    if (notificationChannels[event] == null) {
      notificationChannels[event] = {'admin': true, 'manager': true, 'member': true};
    }
    notificationChannels[event][role] = !(notificationChannels[event][role] ?? true);
    notifyListeners();
  }

  void toggleFrequency(String event, String freq, String role) {
    if (notificationFrequency[role] == null) notificationFrequency[role] = {};
    if (notificationFrequency[role][event] == null) {
      notificationFrequency[role][event] = {'once': true, 'daily': false, 'weekly': false, 'monthly': false, 'yearly': false};
    }
    notificationFrequency[role][event][freq] = !(notificationFrequency[role][event][freq] ?? false);
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    try {
      await _service.markAllRead();
      _unreadCount = 0;
      await fetchNotifications();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> markOneAsRead(String id) async {
    try {
      await _service.markOneRead(id);
      await fetchNotifications();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
