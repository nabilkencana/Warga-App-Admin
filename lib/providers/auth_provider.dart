// lib/providers/auth_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _userRole;
  String? _userEmail;
  String? _userName;
  int? _userId;
  bool _isLoading = false;
  String? _error;
  bool _isOtpSent = false;

  String? get token => _token;
  String? get userRole => _userRole;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  int? get userId => _userId;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOtpSent => _isOtpSent;

  final String baseUrl = 'https://wargakita.canadev.my.id/auth';

  // Constructor untuk load token dari SharedPreferences
  AuthProvider() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      _userRole = prefs.getString('userRole');
      _userEmail = prefs.getString('userEmail');
      _userName = prefs.getString('userName');
      _userId = prefs.getInt('userId');

      if (_token != null) {
        print('Token loaded: ${_token!.substring(0, 20)}...');
        print('User role: $_userRole');
      }
      notifyListeners();
    } catch (e) {
      print('Error loading token: $e');
    }
  }

  Future<void> _saveToken(
    String token,
    String role,
    String email,
    String name,
    int id,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('userRole', role);
    await prefs.setString('userEmail', email);
    await prefs.setString('userName', name);
    await prefs.setInt('userId', id);

    _token = token;
    _userRole = role;
    _userEmail = email;
    _userName = name;
    _userId = id;
  }

  Future<void> requestOtp(String email) async {
    _isLoading = true;
    _error = null;
    _isOtpSent = false;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode.toString().startsWith('2')) {
        _isOtpSent = true;
        _error = null;
        // Simpan email untuk verifikasi nanti
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pendingEmail', email);
      } else {
        throw Exception(data['message'] ?? 'Gagal mengirim OTP');
      }
    } catch (e) {
      _error = e.toString();
      _isOtpSent = false;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode.toString().startsWith('2')) {
        // Validasi bahwa user adalah admin/super admin/satpam
        final userRole = data['user']['role'];

        // Hanya izinkan role tertentu untuk login ke dashboard
        final allowedRoles = ['ADMIN', 'SUPER_ADMIN', 'SATPAM'];
        if (!allowedRoles.contains(userRole)) {
          throw Exception(
            'Anda tidak memiliki akses ke dashboard admin/security',
          );
        }

        // Simpan token dan user data
        await _saveToken(
          data['access_token'],
          userRole,
          data['user']['email'],
          data['user']['name'],
          data['user']['id'],
        );

        _isOtpSent = false; // Reset OTP status
        return {'success': true, 'role': userRole, 'user': data['user']};
      } else {
        throw Exception(data['message'] ?? 'OTP verification failed');
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Google Login untuk mobile
  Future<Map<String, dynamic>> googleMobileLogin(
    Map<String, dynamic> googleData,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/google/mobile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(googleData),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode.toString().startsWith('2')) {
        // Validasi role untuk dashboard access
        final userRole = data['user']['role'];
        final allowedRoles = ['ADMIN', 'SUPER_ADMIN', 'SATPAM'];

        if (!allowedRoles.contains(userRole)) {
          throw Exception(
            'Anda tidak memiliki akses ke dashboard admin/security',
          );
        }

        // Simpan token
        await _saveToken(
          data['access_token'],
          userRole,
          data['user']['email'],
          data['user']['name'],
          data['user']['id'],
        );

        return {'success': true, 'role': userRole, 'user': data['user']};
      } else {
        // Handle khusus untuk user belum terdaftar
        if (response.statusCode == 401 &&
            data['message']?.contains('USER_NOT_REGISTERED')) {
          throw Exception(
            'Akun Google belum terdaftar sebagai admin/satpam. Silakan daftar terlebih dahulu.',
          );
        }
        throw Exception(data['message'] ?? 'Google login failed');
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userRole');
    await prefs.remove('userEmail');
    await prefs.remove('userName');
    await prefs.remove('userId');
    await prefs.remove('pendingEmail');

    _token = null;
    _userRole = null;
    _userEmail = null;
    _userName = null;
    _userId = null;
    _isOtpSent = false;

    notifyListeners();
  }

  // Helper untuk mendapatkan email yang sedang dalam proses OTP
  Future<String?> getPendingEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('pendingEmail');
  }

  void resetOtpState() {
    _isOtpSent = false;
    _error = null;
    notifyListeners();
  }

  bool get isAdmin => _userRole == 'ADMIN' || _userRole == 'SUPER_ADMIN';
  bool get isSatpam => _userRole == 'SATPAM';
  bool get isAuthenticated => _token != null;
}
