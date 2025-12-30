// services/user_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class UserService {
  static const String baseUrl = 'https://wargakita.canadev.my.id';

  // Helper untuk mendapatkan headers dengan auth
  Future<Map<String, String>> _getHeaders() async {
    // TODO: Implement token dari shared preferences
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token'); // HARUS ADA ISINYA
  }


  Future<User> getUserById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode.toString().startsWith('2')) {
        final data = json.decode(response.body);

        data.forEach((key, value) {
          print('$key => ${value.runtimeType}');
        });


        // Debug: Print struktur response
        print('=== DEBUG USER RESPONSE ===');
        print('Full response: $data');
        print('KK File: ${data['kkFile']}');
        print('KK Status: ${data['kkVerificationStatus']}');
        print('==========================');

        return User.fromJson(data);
      } else {
        throw Exception('Failed to load user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load user: $e');
    }
  }

  // 🎯 NEW: Get KK Verification Details
  Future<Map<String, dynamic>> getKKVerificationDetails(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/kk-details'),
        headers: await _getHeaders(),
      );

      if (response.statusCode.toString().startsWith('2')) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get KK details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching KK details: $e');
      throw Exception('Gagal mengambil detail verifikasi KK');
    }
  }

  // 🎯 NEW: Verify KK Document
  Future<void> verifyKKDocument({
    required int userId,
    required bool isApproved,
    String? rejectionReason,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/profile/admin/verify-kk/$userId'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'verified': isApproved,
          'rejectionReason': rejectionReason,
        }),

      );

      // ✅ YANG BENAR
      if (!response.statusCode.toString().startsWith('2')) {
        throw Exception('Failed to verify KK document: ${response.statusCode}');
      }

      // OPTIONAL DEBUG
      print('KK VERIFY SUCCESS: ${response.body}');
    } catch (e) {
      throw Exception('Error verifying KK: $e');
    }
  }

  // 🎯 NEW: Delete KK Document
  Future<void> deleteKKDocument(int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$userId/kk-document'),
        headers: await _getHeaders(),
      );

      if (!response.statusCode.toString().startsWith('2')) {
        throw Exception('Failed to delete KK document: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting KK: $e');
    }
  }

  // 🎯 NEW: Upload KK Document
  Future<void> uploadKKDocument({
    required int userId,
    required String filePath,
    String fileName = 'kk_document',
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/users/$userId/kk-document'),
      );

      // Add headers
      final headers = await _getHeaders();
      request.headers.addAll({'Authorization': headers['Authorization']!});

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath(
          'kkFile',
          filePath,
          filename: '$fileName-${DateTime.now().millisecondsSinceEpoch}',
        ),
      );

      var response = await request.send();

      if (response.statusCode != 200) {
        throw Exception('Failed to upload KK document: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error uploading KK: $e');
    }
  }

  // Existing methods (tidak berubah)
  Future<User> getUserByEmail(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/email/$email'),
        headers: await _getHeaders(),
      );

      if (response.statusCode.toString().startsWith('2')) {
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
      // Coba ambil dari user data terlebih dahulu
      final user = await getUserById(userId);

      // Jika data statistik ada di user object, gunakan itu
      if (user.reportCount != null ||
          user.emergencyCount != null ||
          user.activityCount != null) {
        print('Using stats from user object');
        return {
          'laporan': user.reportCount ?? 0,
          'darurat': user.emergencyCount ?? 0,
          'aktivitas': user.activityCount ?? 0,
        };
      }

      // Jika tidak ada, coba hitung dari endpoint lain
      print('Calculating stats from endpoints...');
      return await _calculateStatsFromEndpoints(userId);
    } catch (e) {
      print('Error getting stats: $e');

      // Fallback ke mock data untuk testing - HAPUS SETELAH API READY
      return await _getMockStats(userId);
    }
  }

  Future<Map<String, int>> _calculateStatsFromEndpoints(int userId) async {
    try {
      int totalReports = 0;
      int emergencyReports = 0;
      int totalActivities = 0;

      // Hitung dari endpoint laporan
      try {
        final reportsResponse = await http.get(
          Uri.parse('$baseUrl/reports?user_id=$userId'),
          headers: await _getHeaders(),
        );

        if (reportsResponse.statusCode.toString().startsWith('2')) {
          final reportsData = json.decode(reportsResponse.body);
          final reports = _extractListFromResponse(reportsData);
          totalReports = reports.length;

          // Hitung laporan darurat
          emergencyReports = reports.where((report) {
            final type = report['type']?.toString().toLowerCase() ?? '';
            final category = report['category']?.toString().toLowerCase() ?? '';
            return type.contains('emergency') ||
                category.contains('emergency') ||
                type.contains('darurat') ||
                category.contains('darurat');
          }).length;
        }
      } catch (e) {
        print('Error fetching reports: $e');
      }

      // Hitung dari endpoint aktivitas
      try {
        final activitiesResponse = await http.get(
          Uri.parse('$baseUrl/activities?user_id=$userId'),
          headers: await _getHeaders(),
        );

        if (activitiesResponse.statusCode.toString().startsWith('2')) {
          final activitiesData = json.decode(activitiesResponse.body);
          final activities = _extractListFromResponse(activitiesData);
          totalActivities = activities.length;
        }
      } catch (e) {
        print('Error fetching activities: $e');
      }

      print(
        'Calculated stats - Reports: $totalReports, Emergency: $emergencyReports, Activities: $totalActivities',
      );

      return {
        'laporan': totalReports,
        'darurat': emergencyReports,
        'aktivitas': totalActivities,
      };
    } catch (e) {
      print('Error calculating stats: $e');
      return {'laporan': 0, 'darurat': 0, 'aktivitas': 0};
    }
  }

  List<dynamic> _extractListFromResponse(dynamic responseData) {
    if (responseData is List) {
      return responseData;
    } else if (responseData is Map && responseData['data'] is List) {
      return responseData['data'];
    } else if (responseData is Map && responseData['items'] is List) {
      return responseData['items'];
    } else if (responseData is Map && responseData['results'] is List) {
      return responseData['results'];
    }
    return [];
  }

  Future<Map<String, int>> _getMockStats(int userId) {
    final mockStats = {
      'laporan': (userId * 3) % 15 + 5,
      'darurat': (userId * 2) % 8 + 1,
      'aktivitas': (userId * 5) % 30 + 10,
    };

    print('Using mock stats: $mockStats');
    return Future.value(mockStats);
  }

  Future<User> updateUserProfile(
    int id,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$id'),
        headers: await _getHeaders(),
        body: json.encode(updateData),
      );

      if (response.statusCode.toString().startsWith('2')) {
        final data = json.decode(response.body);
        return User.fromJson(data);
      } else {
        throw Exception('Failed to update user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // services/user_service.dart - Fungsi updateUserRole
  Future<User> updateUserRole(int id, String role) async {
    try {
      print('🔵 DEBUG: Updating role for user $id to $role');

      final url = '$baseUrl/users/$id/role';
      print('🔵 DEBUG: URL: $url');

      final headers = await _getHeaders();
      print('🔵 DEBUG: Headers: $headers');

      final body = json.encode({'role': role});
      print('🔵 DEBUG: Request body: $body');

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      print('🔵 DEBUG: Response status: ${response.statusCode}');
      print('🔵 DEBUG: Response body: ${response.body}');

      if (response.statusCode.toString().startsWith('2')) {
        final data = json.decode(response.body);
        print('🟢 DEBUG: Role update successful: $data');
        return User.fromJson(data);
      } else {
        final errorMsg =
            'Failed to update role: ${response.statusCode} - ${response.body}';
        print('🔴 DEBUG: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('🔴 DEBUG: Exception in updateUserRole: $e');
      throw Exception('Failed to update role: $e');
    }
  }

  Future<User> updateVerificationStatus(int id, bool isVerified) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$id/verify'),
        headers: await _getHeaders(),
        body: json.encode({'isVerified': isVerified}),
      );

      if (response.statusCode.toString().startsWith('2')) {
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
        headers: await _getHeaders(),
      );

      if (!response.statusCode.toString().startsWith('2')) {
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

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode.toString().startsWith('2')) {
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
