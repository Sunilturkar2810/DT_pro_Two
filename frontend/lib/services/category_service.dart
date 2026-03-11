import 'package:dio/dio.dart';
import '../config/api_constants.dart';
import 'dio_client.dart';

class CategoryService {
  final Dio _dio = DioClient().dio;

  Future<List<dynamic>> getCategories() async {
    try {
      final response = await _dio.get(ApiConstants.categories);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
