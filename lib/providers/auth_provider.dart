// providers/auth_provider.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../models/auth_response.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;
  String? _originalRole; // Simpan role asli dari backend

  User? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get originalRole => _originalRole; // Getter untuk role asli

  final AuthService _authService = AuthService();

  AuthProvider() {
    _loadStoredData();
  }

  // Update _loadStoredData untuk load original role
  Future<void> _loadStoredData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userJson = prefs.getString('user');
      final originalRole = prefs.getString('original_role');

      if (token != null && userJson != null) {
        _token = token;
        final userMap = Map<String, dynamic>.from(jsonDecode(userJson));
        _user = User.fromJson(userMap);
        _originalRole = originalRole;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading stored data: $e');
    }
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_token != null) {
        await prefs.setString('token', _token!);
      }
      if (_user != null) {
        await prefs.setString('user', jsonEncode(_user!.toJson()));
      }
      if (_originalRole != null) {
        await prefs.setString('original_role', _originalRole!);
      }
    } catch (e) {
      print('Error saving data: $e');
    }
  }

  Future<void> sendOtp(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.sendOtp(email);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyOtp(String email, String otp) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _authService.verifyOtp(email, otp);

      _user = response.user;
      _token = response.accessToken;
      _originalRole = _extractOriginalRole(response); // Simpan role asli

      // Save to local storage
      await _saveData();

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper method untuk extract original role
  String? _extractOriginalRole(AuthResponse response) {
    try {
      // Coba ambil dari data mentah response
      // Anda mungkin perlu menyesuaikan ini tergantung struktur response
      return response.user?.originalRole;
    } catch (e) {
      return response.user?.role;
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user');
      await prefs.remove('original_role'); // Hapus juga original role

      _user = null;
      _token = null;
      _error = null;
      _originalRole = null;

      notifyListeners();
    } catch (e) {
      print('Error during logout: $e');
    }
  }
}

Map<String, dynamic> jsonDecode(String source) {
  return json.decode(source);
}
