import 'package:flutter/material.dart';
import '../model/category_model.dart';
import '../services/category_service.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryService _service = CategoryService();

  List<Map<String, dynamic>> _categories = [];
  List<CategoryModel> _categoryModels = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get categories => _categories;
  List<CategoryModel> get categoryModels => _categoryModels;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ========== FETCH ALL CATEGORIES ==========
  Future<void> fetchCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _categories = await _service.getAllCategories();
      _categoryModels = _categories
          .map((item) => CategoryModel.fromJson(item))
          .toList();
      print("✅ Fetched ${_categories.length} categories");
    } catch (e) {
      _errorMessage = e.toString();
      print("❌ Fetch Error (Categories): $_errorMessage");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== CREATE CATEGORY ==========
  Future<bool> createCategory({
    required String name,
    required String color,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newCategory = await _service.createCategory(
        name: name,
        color: color,
      );

      _categories.insert(0, newCategory);
      _categoryModels.insert(0, CategoryModel.fromJson(newCategory));
      print('✅ Category created: $name');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Create category error: $_errorMessage');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== UPDATE CATEGORY ==========
  Future<bool> updateCategory({
    required String categoryId,
    required String name,
    required String color,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _service.updateCategory(
        categoryId: categoryId,
        name: name,
        color: color,
      );

      final index = _categories.indexWhere((cat) => cat['id'] == categoryId);
      if (index != -1) {
        _categories[index] = updated;
        _categoryModels[index] = CategoryModel.fromJson(updated);
      }

      print('✅ Category updated: $name');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Update category error: $_errorMessage');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== DELETE CATEGORY ==========
  Future<bool> deleteCategory(String categoryId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.deleteCategory(categoryId);
      _categories.removeWhere((cat) => cat['id'] == categoryId);
      _categoryModels.removeWhere((cat) => cat.id == categoryId);
      print('✅ Category deleted');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Delete category error: $_errorMessage');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== DELETE ALL TASKS IN CATEGORY ==========
  Future<bool> deleteCategoryTasks(String categoryId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.deleteCategoryTasks(categoryId);
      print('✅ All tasks deleted from category');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Delete tasks error: $_errorMessage');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== REMOVE CATEGORY LINK ==========
  Future<bool> removeCategoryLink(String categoryId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.removeCategoryLink(categoryId);
      print('✅ Category link removed from tasks');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Remove link error: $_errorMessage');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== SEARCH CATEGORIES ==========
  Future<List<Map<String, dynamic>>> searchCategories(String query) async {
    try {
      return await _service.searchCategories(query);
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Search error: $_errorMessage');
      return [];
    }
  }

  // ========== GET CATEGORY BY ID ==========
  Future<Map<String, dynamic>?> getCategoryById(String categoryId) async {
    try {
      return await _service.getCategoryById(categoryId);
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

