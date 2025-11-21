// services/user_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class UserService {
  static const String baseUrl =
      'http://apiwarga.digicodes.my.id'; // Ganti dengan URL API Anda

  Future<User> getUserById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data);
      } else {
        throw Exception('Failed to load user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load user: $e');
    }
  }

  Future<User> getUserByEmail(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/email/$email'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data);
      } else {
        throw Exception('Failed to load user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load user: $e');
    }
  }

  Future<Map<String, int>> getUserStats(int userId) async {
    try {
      // Mengambil data dari endpoint stats umum, atau bisa disesuaikan
      final response = await http.get(
        Uri.parse('$baseUrl/users/stats'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Asumsikan response stats memiliki struktur seperti:
        // { totalUsers: X, verifiedUsers: Y, etc... }
        // Atau Anda bisa membuat endpoint khusus untuk user stats
        return {
          'laporan': data['reportCount'] ?? 0,
          'darurat': data['emergencyCount'] ?? 0,
          'aktivitas': data['activityCount'] ?? 0,
        };
      } else {
        // Fallback ke data dari user detail jika endpoint stats tidak tersedia
        return await _getUserStatsFromUserDetail(userId);
      }
    } catch (e) {
      // Fallback ke data lokal
      return _getLocalUserStats(userId);
    }
  }

  Future<Map<String, int>> _getUserStatsFromUserDetail(int userId) async {
    try {
      final user = await getUserById(userId);
      // Jika user model memiliki field untuk stats, gunakan itu
      // Jika tidak, return default
      return {
        'laporan': user.reportCount ?? 0,
        'darurat': user.emergencyCount ?? 0,
        'aktivitas': user.activityCount ?? 0,
      };
    } catch (e) {
      return _getLocalUserStats(userId);
    }
  }

  Map<String, int> _getLocalUserStats(int userId) {
    // Implementasi fallback ke database lokal atau cache
    return {'laporan': 0, 'darurat': 0, 'aktivitas': 0};
  }

  Future<User> updateUserProfile(
    int id,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data);
      } else {
        throw Exception('Failed to update user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  Future<User> updateUserRole(int id, String role) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$id/role'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'role': role}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data);
      } else {
        throw Exception('Failed to update role: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update role: $e');
    }
  }

  Future<User> updateVerificationStatus(int id, bool isVerified) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$id/verify'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'isVerified': isVerified}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data);
      } else {
        throw Exception(
          'Failed to update verification: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to update verification: $e');
    }
  }

  Future<void> deleteUser(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  Future<List<User>> getAllUsers({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    try {
      final params = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final uri = Uri.parse('$baseUrl/users').replace(queryParameters: params);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data.map((userData) => User.fromJson(userData)).toList();
        } else if (data['data'] is List) {
          return (data['data'] as List)
              .map((userData) => User.fromJson(userData))
              .toList();
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load users: $e');
    }
  }
}
