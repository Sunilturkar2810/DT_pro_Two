import 'package:dio/dio.dart';
import '../config/api_constants.dart';
import 'dio_client.dart';
import '../model/tag_model.dart';

class TagService {
  late final Dio _dio;

  TagService({Dio? dio}) {
    _dio = dio ?? DioClient().dio;
  }

  Future<List<TagModel>> getTagsList() async {
    try {
      final response = await _dio.get('${ApiConstants.tags}/list');
      List<dynamic> data = [];
      
      // Handle different wrapper potentials
      if (response.data is List) {
        data = response.data;
      } else if (response.data is Map && response.data['tags'] is List) {
        data = response.data['tags'];
      } else if (response.data is Map && response.data['data'] is List) {
         data = response.data['data'];
      }
      
      return data.map((json) => TagModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to fetch tags: ${e.message}');
    }
  }

  Future<TagModel> createTag(Map<String, dynamic> tagData) async {
    try {
      final response = await _dio.post('${ApiConstants.tags}/create', data: tagData);
      // Assuming it returns the created tag directly or inside 'tag'/'data'
      Map<String, dynamic> respData = {};
      if (response.data is Map) {
         if (response.data['tag'] != null) {
           respData = response.data['tag'];
         } else if (response.data['data'] != null) {
           respData = response.data['data'];
         } else {
           respData = response.data;
         }
      }
      return TagModel.fromJson(respData);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to create tag: ${e.message}');
    }
  }

  Future<void> deleteTag(String id) async {
    try {
      await _dio.delete('${ApiConstants.tags}/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to delete tag: ${e.message}');
    }
  }
}
