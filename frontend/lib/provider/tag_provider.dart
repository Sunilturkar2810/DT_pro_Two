import 'package:flutter/material.dart';
import '../services/tag_service.dart';
import '../model/tag_model.dart';
import 'auth_provider.dart';

class TagProvider extends ChangeNotifier {
  final TagService _service = TagService();
  
  List<TagModel> _tags = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<TagModel> get tags => _tags;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchTags() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tags = await _service.getTagsList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createTag({required String name, required String color, required AuthProvider auth}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = auth.currentUser;
      final userId = user?.id; // Needed for 'createdBy'
      
      final newTagData = {
        'name': name.trim(),
        'color': color,
        'createdBy': userId,
      };

      await _service.createTag(newTagData);
      
      // Refresh list after success
      await fetchTags();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTag(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.deleteTag(id);
      
      // Remove from list locally for instant UI update
      _tags.removeWhere((tag) => tag.id == id);
      
      return true;
    } catch (e) {
      _errorMessage = e.toString();
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
