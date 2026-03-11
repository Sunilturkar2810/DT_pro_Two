import 'package:flutter/material.dart';
import '../model/category_model.dart';
import '../services/category_service.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryService _service = CategoryService();

  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final List<dynamic> rawData = await _service.getCategories();
      _categories = rawData.map((item) => CategoryModel.fromJson(item)).toList();
      print("✅ Fetched ${_categories.length} categories");
    } catch (e) {
      _errorMessage = e.toString();
      print("❌ Fetch Error (Categories): $_errorMessage");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
