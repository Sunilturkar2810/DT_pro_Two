import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../config/api_constants.dart';
import '../services/dio_client.dart';

class HolidayProvider with ChangeNotifier {
  final Dio _dio = DioClient().dio;
  List<dynamic> _holidays = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get holidays => _holidays;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchHolidays() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('🚀 SENDING REQUEST: [GET] ${ApiConstants.holidays}');
      final response = await _dio.get(ApiConstants.holidays);

      // The backend returns an array directly based on the controller code
      if (response.data is List) {
        _holidays = response.data;
        print('✅ Fetched ${_holidays.length} holidays');
      } else if (response.data is Map && response.data['success'] == true) {
        _holidays = response.data['holidays'] ?? [];
      } else {
        _holidays = [];
      }
    } on DioException catch (e) {
      if (e.response != null && e.response!.data is Map) {
        _error = e.response!.data['message'] ?? e.message;
      } else {
        _error = e.message;
      }
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
      print('🚀 SENDING REQUEST: [POST] ${ApiConstants.holidays}');
      final response = await _dio.post(ApiConstants.holidays, data: {
        'name': name,
        'date': date,
      });
      
      // Controller sends 201 for success
      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchHolidays();
        return true;
      }
      return false;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data is Map) {
        _error = e.response!.data['message'] ?? 'Failed to add holiday';
      } else {
        _error = 'Failed to add holiday: ${e.message}';
      }
      print('❌ Add holiday error: $_error');
      return false;
    } catch (e) {
      print('❌ Error adding holiday: $e');
      return false;
    }
  }

  Future<bool> deleteHoliday(String id) async {
    try {
      print('🚀 SENDING REQUEST: [DELETE] ${ApiConstants.holidays}/$id');
      final response = await _dio.delete(
        '${ApiConstants.holidays}/$id',
        data: {}, // Fix: Fastify requires body to not be empty when content-type is application/json
      );
      
      if (response.statusCode == 200) {
        _holidays.removeWhere((h) => h['id'].toString() == id.toString());
        notifyListeners();
        return true;
      }
      return false;
    } on DioException catch (e) {
      if (e.response != null && e.response!.data is Map) {
        _error = e.response!.data['message'] ?? 'Failed to delete holiday';
      } else {
        _error = 'Failed to delete holiday: ${e.message}';
      }
      print('❌ Delete holiday error: $_error');
      return false;
    } catch (e) {
      print('❌ Error deleting holiday: $e');
      return false;
    }
  }
}
