import 'package:dio/dio.dart';
import '../config/api_constants.dart';
import 'dio_client.dart';

class DashboardService {
  final Dio _dio = DioClient().dio;

  Future<Map<String, dynamic>?> fetchDashboardStats({
    String filter = 'All Time', 
    String tab = 'My Report',
    String category = 'Category',
    String status = 'Status',
    String search = '',
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryObj = {
        'filter': filter,
        'tab': tab,
        if (category != 'Category' && category != 'All') 'category': category,
        if (status != 'Status' && status != 'All') 'status': status,
        if (search.isNotEmpty) 'search': search,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      };
      
      final queryParams = queryObj.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      
      final response = await _dio.get('${ApiConstants.dashboardStats}?$queryParams');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
