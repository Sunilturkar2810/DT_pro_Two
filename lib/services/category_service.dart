import 'package:dio/dio.dart';
import '../config/api_constants.dart';
import 'dio_client.dart';

class CategoryService {
  final Dio _dio = DioClient().dio;

  // Get all categories with task count
  Future<List<Map<String, dynamic>>> getAllCategories() async {
    try {
      final response = await _dio.get('${ApiConstants.categories}/list');
      final categories = List<Map<String, dynamic>>.from(response.data ?? []);
      return categories;
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  // Get single category by ID
  Future<Map<String, dynamic>> getCategoryById(String categoryId) async {
    try {
      final response = await _dio.get('${ApiConstants.categories}/$categoryId');
      return Map<String, dynamic>.from(response.data ?? {});
    } catch (e) {
      throw Exception('Failed to fetch category: $e');
    }
  }

  // Create new category
  Future<Map<String, dynamic>> createCategory({
    required String name,
    required String color,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.categories}/create',
        data: {
          'name': name.trim(),
          'color': color.trim(),
        },
      );
      return Map<String, dynamic>.from(response.data ?? {});
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  // Update category
  Future<Map<String, dynamic>> updateCategory({
    required String categoryId,
    required String name,
    required String color,
  }) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.categories}/$categoryId',
        data: {
          'name': name.trim(),
          'color': color.trim(),
        },
      );
      return Map<String, dynamic>.from(response.data ?? {});
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  // Delete category
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _dio.delete('${ApiConstants.categories}/$categoryId');
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  // Delete all tasks in category
  Future<Map<String, dynamic>> deleteCategoryTasks(String categoryId) async {
    try {
      final response = await _dio.delete(
        '${ApiConstants.categories}/$categoryId/tasks'
      );
      return Map<String, dynamic>.from(response.data ?? {});
    } catch (e) {
      throw Exception('Failed to delete tasks: $e');
    }
  }

  // Remove category link from tasks (keep tasks, remove category)
  Future<Map<String, dynamic>> removeCategoryLink(String categoryId) async {
    try {
      final response = await _dio.delete(
        '${ApiConstants.categories}/$categoryId/unlink'
      );
      return Map<String, dynamic>.from(response.data ?? {});
    } catch (e) {
      throw Exception('Failed to remove category link: $e');
    }
  }

  // Search categories
  Future<List<Map<String, dynamic>>> searchCategories(String query) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.categories}/search',
        queryParameters: {'search': query},
      );
      final categories = List<Map<String, dynamic>>.from(response.data ?? []);
      return categories;
    } catch (e) {
      throw Exception('Failed to search categories: $e');
    }
  }

  // Legacy method for backward compatibility
  Future<List<dynamic>> getCategories() async {
    try {
      final response = await _dio.get('${ApiConstants.categories}/list');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}

