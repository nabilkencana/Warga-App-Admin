// services/admin_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dashboard_stats.dart';
import '../models/user.dart';

class AdminService {
  static const String baseUrl = 'http://localhost:3000/admin';
  final String token;

  AdminService(this.token);

  Future<Map<String, String>> _getHeaders() async {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<DashboardStats> getDashboardStats() async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/dashboard/stats');

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DashboardStats.fromJson(data);
      } else {
        throw Exception(
          'Failed to load dashboard stats: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error in getDashboardStats: $e');
      rethrow;
    }
  }

  Future<List<User>> getRecentUsers() async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/recent/users');

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load recent users: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getRecentUsers: $e');
      rethrow;
    }
  }
}
