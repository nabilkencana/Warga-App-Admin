// services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wargaapp_admin/models/auth_response.dart';

class AuthService {
  static const String baseUrl = 'https://wargakita.canadev.my.id';

  Future<AuthResponse> sendOtp(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode.toString().startsWith('2')) {
        final data = jsonDecode(response.body);
        return AuthResponse(
          message: data['message'] ?? 'OTP berhasil dikirim',
          user: null,
          accessToken: '',
        );
      } else if (response.statusCode == 401) {
        throw Exception('Email tidak ditemukan');
      } else {
        throw Exception('Gagal mengirim OTP: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<AuthResponse> verifyOtp(String email, String otp) async {
    try {
      print('🔐 Verifying OTP for: $email');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode.toString().startsWith('2')) {
        final userRole = data['user']['role'] as String;
        print('👤 User role from backend: $userRole');

        final allowedRoles = ['ADMIN', 'SUPER_ADMIN', 'SECURITY', 'SATPAM'];

        if (!allowedRoles.contains(userRole)) {
          print('❌ Role $userRole not allowed');
          throw Exception(
            'Hanya ADMIN, SUPER_ADMIN, SECURITY, dan SATPAM yang diizinkan login',
          );
        }

        print('✅ Login successful for role: $userRole');
        return AuthResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception(data['message'] ?? 'OTP salah atau sudah kadaluarsa');
      } else {
        throw Exception('Verifikasi gagal: ${data['message']}');
      }
    } catch (e) {
      print('❌ Error in verifyOtp: $e');
      throw Exception('Error: $e');
    }
  }

  Future<void> logout() async {
    // Clear local storage handled by provider
  }
}
