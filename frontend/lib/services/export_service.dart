import 'package:dio/dio.dart';
import '../config/api_constants.dart';

class ExportService {
  final Dio _dio;

  ExportService(this._dio);

  // Create export
  Future<Map<String, dynamic>> createExport({
    required String dateRange,
    required List<String>? assignedTo,
    required List<String>? assignedBy,
    required List<String>? taskType,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/api/exports',
        data: {
          'dateRange': dateRange,
          'assignedTo': assignedTo,
          'assignedBy': assignedBy,
          'taskType': taskType,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Get export logs
  Future<Map<String, dynamic>> getExportLogs() async {
    try {
      final response = await _dio.get('${ApiConstants.baseUrl}/api/exports/logs');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Get all export logs (admin only)
  Future<Map<String, dynamic>> getAllExportLogs() async {
    try {
      final response = await _dio.get('${ApiConstants.baseUrl}/api/exports/admin/logs');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Download export
  Future<Map<String, dynamic>> downloadExport(String exportId) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/api/exports/$exportId/download',
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Delete export
  Future<Map<String, dynamic>> deleteExport(String exportId) async {
    try {
      final response = await _dio.delete(
        '${ApiConstants.baseUrl}/api/exports/$exportId',
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
