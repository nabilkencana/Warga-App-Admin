// services/admin_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:user_management_app/models/dashboard_stats.dart';
import 'package:user_management_app/models/user.dart';

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
      print('GET: $url');

      final response = await http.get(url, headers: headers);

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

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
      print('GET: $url');

      final response = await http.get(url, headers: headers);

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

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
