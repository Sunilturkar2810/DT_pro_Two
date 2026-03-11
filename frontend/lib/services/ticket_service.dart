import 'package:dio/dio.dart';
import '../config/api_constants.dart';
import 'dio_client.dart';

class TicketService {
  final Dio _dio = DioClient().dio;

  Future<List<dynamic>> getMyTickets() async {
    final response = await _dio.get(ApiConstants.tickets);
    return response.data['data'] ?? [];
  }

  Future<Map<String, dynamic>> raiseTicket(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConstants.tickets, data: data);
    return response.data;
  }

  // Admin / Manager Only
  Future<List<dynamic>> getAllTickets() async {
    final response = await _dio.get('${ApiConstants.tickets}/admin/all');
    return response.data['data'] ?? [];
  }

  Future<void> updateTicket(String id, Map<String, dynamic> data) async {
    await _dio.patch('${ApiConstants.tickets}/$id', data: data);
  }
}
