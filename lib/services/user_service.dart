// services/user_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class UserService {
  static const String baseUrl =
      'http://wargakita.canadev.my.id'; // Ganti dengan URL API Anda

  Future<User> getUserById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Debug: Print struktur response
        print('=== DEBUG USER RESPONSE ===');
        print('Full response: $data');
        print('Report count: ${data['reportCount']}');
        print('Emergency count: ${data['emergencyCount']}');
        print('Activity count: ${data['activityCount']}');
        print('==========================');

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
          headers: {'Content-Type': 'application/json'},
        );

        if (reportsResponse.statusCode == 200) {
          final reportsData = json.decode(reportsResponse.body);
          final reports = _extractListFromResponse(reportsData);
          totalReports = reports.length;

          // Hitung laporan darurat (asumsi ada field 'type' atau 'category')
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
          headers: {'Content-Type': 'application/json'},
        );

        if (activitiesResponse.statusCode == 200) {
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

  // Helper method untuk extract list dari berbagai format response
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

  // Temporary mock data untuk testing - HAPUS SETELAH API READY
  Future<Map<String, int>> _getMockStats(int userId) {
    // Generate random stats berdasarkan user ID untuk testing
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
