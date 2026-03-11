import 'dart:convert';

import 'package:d_table_delegate_system/model/user_model.dart';
import 'package:d_table_delegate_system/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';



class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _errorMessage;
  UserModel? _currentUser;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;

  // ✅ Getter to check if the user is an Admin
  bool get isAdmin => 
      _currentUser?.role?.toLowerCase() == 'admin' || 
      _currentUser?.role?.toLowerCase() == 'superadmin';

  AuthProvider() { restoreSession(); }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _authService.login(email, password);
      final box = Hive.box('settingsBox');

      await box.put('auth_token', data['token']);
      await box.put('auth_user', jsonEncode(data['user']));

      // ✅ User ID nikalne ke liye backup check
      String fetchedId = data['user']['userId'] ?? data['user']['id'] ?? '';
      await box.put('auth_user_id', fetchedId);

      _currentUser = UserModel.fromJson(data['user']);
      _isAuthenticated = true;

      // 🕵️ Is print se check karein ki ID khali toh nahi?
      print("🚀 LOGIN SUCCESS! ID: ${_currentUser?.id}, Role: ${_currentUser?.role}");

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print("🛑 LOGIN FAILED! Error: $_errorMessage");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- FORGOT PASSWORD METHOD ---
  Future<String?> forgotPassword(String workEmail) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resp = await _authService.forgotPassword(workEmail);
      print("🔑 FORGOT PASSWORD SENT! Response: ${jsonEncode(resp)}");
      return resp['resetToken'] as String?;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print("🛑 FORGOT PASSWORD FAILED! Error: $_errorMessage");
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- RESET PASSWORD METHOD ---
  Future<bool> resetPassword(String resetToken, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resp = await _authService.resetPassword(resetToken, newPassword);
      print("🔑 RESET PASSWORD SUCCESS! Response: ${jsonEncode(resp)}");
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print("🛑 RESET PASSWORD FAILED! Error: $_errorMessage");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- REGISTER METHOD ---
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String workEmail,
    required String password,
    required String mobileNumber,
    required String role,
    required String designation,
    required String department,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Map<String, dynamic> registrationData = {
        "firstName": firstName,
        "lastName": lastName,
        "workEmail": workEmail,
        "password": password,
        "mobileNumber": mobileNumber,
        "role": role,
        "designation": designation,
        "department": department,
      };

      final resp = await _authService.register(registrationData);

      // ✅ SUCCESS PRINT IN CONSOLE
      print("-----------------------------------------");
      print("🆕 REGISTRATION SUCCESSFUL!");
      print("📄 Response Data: ${jsonEncode(resp)}");
      print("-----------------------------------------");

      if (resp.containsKey('user') || resp['message'] == "User registered successfully") {
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');

      // ❌ ERROR PRINT IN CONSOLE
      print("-----------------------------------------");
      print("🛑 REGISTRATION FAILED!");
      print("⚠️ Error: $_errorMessage");
      print("-----------------------------------------");

      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- UPDATE PROFILE (AND PICTURE) ---
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedData = await _authService.updateProfile(updates);
      
      // Update local state and save to Hive
      _currentUser = UserModel.fromJson(updatedData);
      
      final box = Hive.box('settingsBox');
      await box.put('auth_user', jsonEncode(_currentUser!.toJson()));

      print("✅ PROFILE UPDATED SUCCESSFULLY!");
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print("🛑 PROFILE UPDATE FAILED! Error: $_errorMessage");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- ADMIN: GET ALL USERS ---
  List<UserModel> _allUsers = [];
  List<UserModel> get allUsers => _allUsers;

  Future<void> fetchAllUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      final List<dynamic> usersData = await _authService.getAllUsers();
      _allUsers = usersData.map((data) => UserModel.fromJson(data)).toList();
    } catch (e) {
      _errorMessage = e.toString();
      print("🛑 FAILED TO FETCH USERS: $_errorMessage");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- ADMIN: DELETE USER ---
  Future<bool> deleteUser(String userId) async {
    try {
      await _authService.deleteUser(userId);
      _allUsers.removeWhere((user) => user.id == userId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print("🛑 FAILED TO DELETE USER: $_errorMessage");
      return false;
    }
  }


  Future<void> logout() async {
    final box = Hive.box('settingsBox');
    await box.clear(); // Token aur user delete
    _isAuthenticated = false;
    _currentUser = null;
    print("🚪 User Logged Out & Console Cleared");
    notifyListeners();
  }

  void restoreSession() {
    final box = Hive.box('settingsBox');
    final token = box.get('auth_token');
    final userStr = box.get('auth_user');
    if (token != null && userStr != null) {
      _isAuthenticated = true;
      _currentUser = UserModel.fromJson(jsonDecode(userStr));
      print("✅ Session Restored for: ${_currentUser?.workEmail} as ${_currentUser?.role}");
    }
  }

}

