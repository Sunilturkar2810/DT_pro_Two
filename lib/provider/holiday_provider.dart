import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../config/api_constants.dart';

class HolidayProvider with ChangeNotifier {
  final Dio _dio = Dio();
  List<dynamic> _holidays = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get holidays => _holidays;
  bool get isLoading => _isLoading;
  String? get error => _error;

  HolidayProvider() {
    _dio.options.baseUrl = ApiConstants.baseUrl; // Using standardized base URL
    _dio.options.headers['Content-Type'] = 'application/json';
  }

  void updateToken(String? token) {
    if (token != null && token.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  Future<void> fetchHolidays() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('🚀 SENDING REQUEST: [GET] /holidays');
      final response = await _dio.get('/holidays');

      if (response.statusCode == 200 && response.data['success'] == true) {
        _holidays = response.data['holidays'] ?? [];
        print('✅ Fetched ${_holidays.length} holidays');
      } else {
        _error = "Failed to fetch holidays";
      }
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? e.message;
      print('❌ Fetch holidays error: $_error');
    } catch (e) {
      _error = e.toString();
      print('❌ Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addHoliday(String name, String date) async {
    try {
      print('🚀 SENDING REQUEST: [POST] /holidays');
      final response = await _dio.post('/holidays', data: {
        'name': name,
        'date': date,
      });
      if (response.statusCode == 200 && response.data['success'] == true) {
        await fetchHolidays();
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Add holiday error: $e');
      return false;
    }
  }

  Future<bool> deleteHoliday(String id) async {
    try {
      print('🚀 SENDING REQUEST: [DELETE] /holidays/$id');
      final response = await _dio.delete('/holidays/$id');
      if (response.statusCode == 200 && response.data['success'] == true) {
        _holidays.removeWhere((h) => h['id'] == id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Delete holiday error: $e');
      return false;
    }
  }
}
