import 'package:flutter/material.dart';
import '../model/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();
  
  bool _isLoading = false;
  String? _errorMessage;
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;

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

  Future<void> markAllAsRead() async {
    try {
      await _service.markAllRead();
      _unreadCount = 0;
      for (var n in _notifications) {
        // Technically Dart models don't have setters here but we assume UI redraw helps,
        // so we'll re-fetch just in case.
      }
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
