import 'package:flutter/material.dart';
import '../services/export_service.dart';
import '../services/dio_client.dart';

class ExportProvider extends ChangeNotifier {
  final ExportService _service = ExportService(DioClient().dio);

  List<Map<String, dynamic>> _exportLogs = [];
  List<Map<String, dynamic>> _allExportLogs = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get exportLogs => _exportLogs;
  List<Map<String, dynamic>> get allExportLogs => _allExportLogs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ========== GET EXPORT LOGS ==========
  Future<void> fetchExportLogs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _service.getExportLogs();
      _exportLogs = List<Map<String, dynamic>>.from(response['logs'] ?? []);
      print('✅ Export logs fetched: ${_exportLogs.length} records');
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Fetch export logs error: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== GET ALL EXPORT LOGS (ADMIN) ==========
  Future<void> fetchAllExportLogs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _service.getAllExportLogs();
      _allExportLogs = List<Map<String, dynamic>>.from(response['logs'] ?? []);
      print('✅ All export logs fetched: ${_allExportLogs.length} records');
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Fetch all export logs error: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== CREATE EXPORT ==========
  Future<bool> createExport({
    required String dateRange,
    List<String>? assignedTo,
    List<String>? assignedBy,
    List<String>? taskType,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.createExport(
        dateRange: dateRange,
        assignedTo: assignedTo,
        assignedBy: assignedBy,
        taskType: taskType,
      );

      print('✅ Export created successfully');
      // Refresh logs after creating new export
      await fetchExportLogs();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Create export error: $_errorMessage');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== DOWNLOAD EXPORT ==========
  Future<Map<String, dynamic>?> downloadExport(String exportId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _service.downloadExport(exportId);
      print('✅ Export download prepared');
      return response['data'] as Map<String, dynamic>?;
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Download export error: $_errorMessage');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== DELETE EXPORT ==========
  Future<bool> deleteExport(String exportId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.deleteExport(exportId);
      print('✅ Export deleted successfully');
      // Refresh logs after deletion
      await fetchExportLogs();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Delete export error: $_errorMessage');
      return false;
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
