import 'package:dio/dio.dart';
import '../config/api_constants.dart';
import 'dio_client.dart';

// ⚠️ NOTE: Tickets feature is NOT available in the new backend (erprld.com/api).
// This service is stubbed out to prevent compile errors.
// Future implementation can replace these stubs when the feature is available.
class TicketService {
  final Dio _dio = DioClient().dio;

  Future<List<dynamic>> getMyTickets() async {
    // Not available in new backend
    return [];
  }

  Future<Map<String, dynamic>> raiseTicket(Map<String, dynamic> data) async {
    // Not available in new backend
    return {'message': 'Tickets not available in current backend'};
  }

  // Admin / Manager Only
  Future<List<dynamic>> getAllTickets() async {
    // Not available in new backend
    return [];
  }

  Future<void> updateTicket(String id, Map<String, dynamic> data) async {
    // Not available in new backend
  }
}
