// services/emergency_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/emergency.dart';

class EmergencyService {
  static const String baseUrl = 'http://wargakita.canadev.my.id';

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<String?> _getToken() async {
    // Implement token retrieval from shared preferences or secure storage
    return null; // Replace with actual token retrieval
  }

  Future<List<Emergency>> getActiveEmergencies() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/emergency/active'),
        headers: await _getHeaders(),
      );

      if (response.statusCode.toString().startsWith('2')) {
        final data = json.decode(response.body);
        if (data is List) {
          return data.map((item) => Emergency.fromJson(item)).toList();
        } else {
          throw Exception('Format response tidak valid');
        }
      } else {
        throw Exception('Gagal memuat keadaan darurat: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal memuat keadaan darurat: $e');
    }
  }

  Future<List<Emergency>> getAllEmergencies() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/emergency'),
        headers: await _getHeaders(),
      );

      if (response.statusCode.toString().startsWith('2')) {
        final data = json.decode(response.body);
        if (data is List) {
          return data.map((item) => Emergency.fromJson(item)).toList();
        } else {
          throw Exception('Format response tidak valid');
        }
      } else {
        throw Exception('Gagal memuat keadaan darurat: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal memuat keadaan darurat: $e');
    }
  }

  Future<List<Emergency>> getEmergenciesNeedVolunteers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/emergency/need-volunteers'),
        headers: await _getHeaders(),
      );

      if (response.statusCode.toString().startsWith('2')) {
        final data = json.decode(response.body);
        if (data is List) {
          return data.map((item) => Emergency.fromJson(item)).toList();
        } else {
          throw Exception('Format response tidak valid');
        }
      } else {
        throw Exception('Gagal memuat keadaan darurat: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal memuat keadaan darurat: $e');
    }
  }

  Future<Emergency> createSOS({
    required String type,
    String? details,
    String? location,
    String? latitude,
    String? longitude,
    bool needVolunteer = false,
    int volunteerCount = 0,
    int? userId,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'type': type,
        'needVolunteer': needVolunteer,
        'volunteerCount': volunteerCount,
      };

      // Only add fields if they have values
      if (details != null && details.isNotEmpty) {
        requestData['details'] = details;
      }
      if (location != null && location.isNotEmpty) {
        requestData['location'] = location;
      }
      if (latitude != null && latitude.isNotEmpty) {
        requestData['latitude'] = latitude;
      }
      if (longitude != null && longitude.isNotEmpty) {
        requestData['longitude'] = longitude;
      }
      if (userId != null) requestData['userId'] = userId;

      final response = await http.post(
        Uri.parse('$baseUrl/emergency/sos'),
        headers: await _getHeaders(),
        body: json.encode(requestData),
      );

      if (response.statusCode == 201 ||
          response.statusCode.toString().startsWith('2')) {
        final data = json.decode(response.body);
        return Emergency.fromJson(data);
      } else {
        throw Exception('Gagal membuat SOS: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal membuat SOS: $e');
    }
  }

  Future<Emergency> updateStatus(int id, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/emergency/$id/status'),
        headers: await _getHeaders(),
        body: json.encode({'status': status}),
      );

      if (response.statusCode.toString().startsWith('2')) {
        final data = json.decode(response.body);
        return Emergency.fromJson(data);
      } else {
        throw Exception('Gagal mengupdate status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal mengupdate status: $e');
    }
  }

  Future<Emergency> toggleNeedVolunteer({
    required int id,
    required bool needVolunteer,
    int? volunteerCount,
  }) async {
    try {
      final Map<String, dynamic> requestData = {'needVolunteer': needVolunteer};

      if (volunteerCount != null) {
        requestData['volunteerCount'] = volunteerCount;
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/emergency/$id/volunteer'),
        headers: await _getHeaders(),
        body: json.encode(requestData),
      );

      if (response.statusCode.toString().startsWith('2')) {
        final data = json.decode(response.body);
        return Emergency.fromJson(data);
      } else {
        throw Exception(
          'Gagal mengupdate kebutuhan relawan: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Gagal mengupdate kebutuhan relawan: $e');
    }
  }

  Future<Volunteer> registerVolunteer({
    required int emergencyId,
    int? userId,
    String? userName,
    String? userPhone,
    String? skills,
  }) async {
    try {
      final Map<String, dynamic> requestData = {};

      if (userId != null) requestData['userId'] = userId;
      if (userName != null && userName.isNotEmpty) {
        requestData['userName'] = userName;
      }
      if (userPhone != null && userPhone.isNotEmpty) {
        requestData['userPhone'] = userPhone;
      }
      if (skills != null && skills.isNotEmpty) requestData['skills'] = skills;

      final response = await http.post(
        Uri.parse('$baseUrl/emergency/$emergencyId/volunteer'),
        headers: await _getHeaders(),
        body: json.encode(requestData),
      );

      if (response.statusCode == 201 ||
          response.statusCode.toString().startsWith('2')) {
        final data = json.decode(response.body);
        return Volunteer.fromJson(data);
      } else {
        throw Exception(
          'Gagal mendaftar sebagai relawan: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Gagal mendaftar sebagai relawan: $e');
    }
  }

  Future<Volunteer> updateVolunteerStatus(
    int volunteerId,
    String status,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/emergency/volunteers/$volunteerId/status'),
        headers: await _getHeaders(),
        body: json.encode({'status': status}),
      );

      if (response.statusCode.toString().startsWith('2')) {
        final data = json.decode(response.body);
        return Volunteer.fromJson(data);
      } else {
        throw Exception(
          'Gagal mengupdate status relawan: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Gagal mengupdate status relawan: $e');
    }
  }

  Future<List<Volunteer>> getEmergencyVolunteers(int emergencyId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/emergency/$emergencyId/volunteers'),
        headers: await _getHeaders(),
      );

      if (response.statusCode.toString().startsWith('2')) {
        final data = json.decode(response.body);
        if (data is List) {
          return data.map((item) => Volunteer.fromJson(item)).toList();
        } else {
          throw Exception('Format response tidak valid');
        }
      } else {
        throw Exception('Gagal memuat data relawan: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal memuat data relawan: $e');
    }
  }

  Future<Map<String, dynamic>> getEmergencyStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/emergency/stats'),
        headers: await _getHeaders(),
      );

      if (response.statusCode.toString().startsWith('2')) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Gagal memuat statistik: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal memuat statistik: $e');
    }
  }

  Future<List<Emergency>> getEmergenciesByType(String type) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/emergency/type/$type'),
        headers: await _getHeaders(),
      );

      if (response.statusCode.toString().startsWith('2')) {
        final data = json.decode(response.body);
        if (data is List) {
          return data.map((item) => Emergency.fromJson(item)).toList();
        } else {
          throw Exception('Format response tidak valid');
        }
      } else {
        throw Exception('Gagal memuat keadaan darurat: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal memuat keadaan darurat: $e');
    }
  }

  // Get available emergency types
  Future<List<String>> getEmergencyTypes() async {
    return [
      'Kebakaran',
      'Banjir',
      'Gempa',
      'Kecelakaan',
      'Medis',
      'Bencana Alam',
      'Lainnya',
    ];
  }
}
