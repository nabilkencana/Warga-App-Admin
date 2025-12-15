// lib/providers/security_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SecurityProvider with ChangeNotifier {
  bool _isOnDuty = false;
  bool _isPatrolling = false;
  bool _isLocationEnabled = false;
  Position? _currentPosition;
  List<Map<String, dynamic>> _emergencies = [];
  List<Map<String, dynamic>> _patrolLogs = [];
  List<Map<String, dynamic>> _incidents = [];
  int _pendingEmergencyCount = 0;
  Map<String, dynamic>? _latestEmergency;
  bool _hasNewEmergencyAlert = false;
  bool _isLoading = false;
  String? _error;
  int? _securityId;
  String? _token;

  bool get isOnDuty => _isOnDuty;
  bool get isPatrolling => _isPatrolling;
  bool get isLocationEnabled => _isLocationEnabled;
  Position? get currentPosition => _currentPosition;
  List<Map<String, dynamic>> get emergencies => _emergencies;
  List<Map<String, dynamic>> get patrolLogs => _patrolLogs;
  List<Map<String, dynamic>> get incidents => _incidents;
  int get pendingEmergencyCount => _pendingEmergencyCount;
  Map<String, dynamic>? get latestEmergency => _latestEmergency;
  bool get hasNewEmergencyAlert => _hasNewEmergencyAlert;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final String baseUrl = 'https://wargakita.canadev.my.id/api';

  Future<void> initializeSecurity(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');

      // Load security data
      await _loadSecurityData(userId);
      await _loadEmergencies();
      await _loadIncidents();

      // Request location permission
      await _requestLocationPermission();

      // Load duty status from storage
      _isOnDuty = prefs.getBool('isOnDuty') ?? false;
      _isPatrolling = prefs.getBool('isPatrolling') ?? false;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadSecurityData(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/security/user/$userId'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _securityId = data['id'];

        // Update duty status from server
        _isOnDuty = data['isOnDuty'] ?? false;
        _isPatrolling = data['isPatrolling'] ?? false;

        // Save to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isOnDuty', _isOnDuty);
        await prefs.setBool('isPatrolling', _isPatrolling);
      }
    } catch (e) {
      print('Error loading security data: $e');
    }
  }

  Future<void> _requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _isLocationEnabled = false;
        return;
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        _isLocationEnabled = true;
        await _getCurrentLocation();
      }
    } catch (e) {
      print('Error requesting location permission: $e');
      _isLocationEnabled = false;
    }
    notifyListeners();
  }

  Future<void> _getCurrentLocation() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> updateLocation() async {
    if (!_isLocationEnabled) return;

    try {
      await _getCurrentLocation();

      // Send location update to server if on duty
      if (_isOnDuty && _currentPosition != null && _securityId != null) {
        await http.post(
          Uri.parse('$baseUrl/security/$_securityId/location'),
          headers: {
            'Authorization': 'Bearer $_token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'latitude': _currentPosition!.latitude,
            'longitude': _currentPosition!.longitude,
            'timestamp': DateTime.now().toIso8601String(),
          }),
        );
      }
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  Future<void> checkIn() async {
    try {
      if (_securityId == null) return;

      final response = await http.post(
        Uri.parse('$baseUrl/security/$_securityId/checkin'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _isOnDuty = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isOnDuty', true);

        // Log activity
        await _logSecurityAction('CHECK_IN', 'Started duty shift');

        notifyListeners();
      }
    } catch (e) {
      print('Error checking in: $e');
    }
  }

  Future<void> checkOut() async {
    try {
      if (_securityId == null) return;

      final response = await http.post(
        Uri.parse('$baseUrl/security/$_securityId/checkout'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _isOnDuty = false;
        _isPatrolling = false;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isOnDuty', false);
        await prefs.setBool('isPatrolling', false);

        // Log activity
        await _logSecurityAction('CHECK_OUT', 'Ended duty shift');

        notifyListeners();
      }
    } catch (e) {
      print('Error checking out: $e');
    }
  }

  Future<void> startPatrol() async {
    try {
      if (_securityId == null || !_isOnDuty) return;

      final response = await http.post(
        Uri.parse('$baseUrl/security/$_securityId/patrol/start'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _isPatrolling = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isPatrolling', true);

        // Log patrol start
        await _logSecurityAction('PATROL_START', 'Started patrol');

        notifyListeners();
      }
    } catch (e) {
      print('Error starting patrol: $e');
    }
  }

  Future<void> endPatrol() async {
    try {
      if (_securityId == null) return;

      final response = await http.post(
        Uri.parse('$baseUrl/security/$_securityId/patrol/end'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'endLocation': _currentPosition != null
              ? '${_currentPosition!.latitude},${_currentPosition!.longitude}'
              : 'Unknown',
        }),
      );

      if (response.statusCode == 200) {
        _isPatrolling = false;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isPatrolling', false);

        // Log patrol end
        await _logSecurityAction('PATROL_END', 'Ended patrol');

        notifyListeners();
      }
    } catch (e) {
      print('Error ending patrol: $e');
    }
  }

  Future<void> _loadEmergencies() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/security/emergencies'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _emergencies = List<Map<String, dynamic>>.from(
          data['emergencies'] ?? [],
        );
        _pendingEmergencyCount = data['pendingCount'] ?? 0;
      }
    } catch (e) {
      print('Error loading emergencies: $e');
    }
  }

  Future<void> checkNewEmergencies() async {
    if (!_isOnDuty) return;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/security/emergencies/new'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newEmergencies = List<Map<String, dynamic>>.from(
          data['emergencies'] ?? [],
        );

        if (newEmergencies.isNotEmpty) {
          _latestEmergency = newEmergencies.first;
          _hasNewEmergencyAlert = true;
          _pendingEmergencyCount += newEmergencies.length;

          // Add to emergencies list
          _emergencies.insertAll(0, newEmergencies);

          // Show notification
          _showEmergencyNotification(newEmergencies.first);

          notifyListeners();
        }
      }
    } catch (e) {
      print('Error checking new emergencies: $e');
    }
  }

  Future<void> refreshEmergencies() async {
    await _loadEmergencies();
    notifyListeners();
  }

  Future<void> respondToEmergency(int emergencyId, String emergencyType) async {
    try {
      if (_securityId == null) return;

      final response = await http.post(
        Uri.parse('$baseUrl/emergency/$emergencyId/respond'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'securityId': _securityId,
          'action': 'RESPONDING',
          'notes': 'Security personnel responding to $emergencyType',
        }),
      );

      if (response.statusCode == 200) {
        // Update local emergencies list
        _emergencies = _emergencies.map((emergency) {
          if (emergency['id'] == emergencyId) {
            return {
              ...emergency,
              'status': 'RESPONDING',
              'respondedBy': _securityId,
              'respondedAt': DateTime.now().toIso8601String(),
            };
          }
          return emergency;
        }).toList();

        _pendingEmergencyCount = _pendingEmergencyCount > 0
            ? _pendingEmergencyCount - 1
            : 0;

        // Log response
        await _logSecurityAction(
          'EMERGENCY_RESPONSE',
          'Responded to emergency #$emergencyId',
        );

        notifyListeners();
      }
    } catch (e) {
      print('Error responding to emergency: $e');
    }
  }

  Future<void> _loadIncidents() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/security/incidents'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _incidents = List<Map<String, dynamic>>.from(data['incidents'] ?? []);
      }
    } catch (e) {
      print('Error loading incidents: $e');
    }
  }

  Future<void> reportIncident(
    String title,
    String description,
    String location,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/security/incidents'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': title,
          'description': description,
          'location': location,
          'latitude': _currentPosition?.latitude,
          'longitude': _currentPosition?.longitude,
          'reportedBy': _securityId,
        }),
      );

      if (response.statusCode == 201) {
        // Add to local incidents list
        final newIncident = {
          'id': DateTime.now().millisecondsSinceEpoch,
          'title': title,
          'description': description,
          'location': location,
          'reportedAt': DateTime.now().toIso8601String(),
          'status': 'REPORTED',
        };

        _incidents.insert(0, newIncident);

        // Log incident report
        await _logSecurityAction(
          'INCIDENT_REPORT',
          'Reported incident: $title',
        );

        notifyListeners();
      }
    } catch (e) {
      print('Error reporting incident: $e');
    }
  }

  Future<void> _logSecurityAction(String action, String details) async {
    try {
      if (_securityId == null) return;

      await http.post(
        Uri.parse('$baseUrl/security/logs'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'securityId': _securityId,
          'action': action,
          'details': details,
          'location': _currentPosition != null
              ? '${_currentPosition!.latitude},${_currentPosition!.longitude}'
              : 'Unknown',
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      print('Error logging security action: $e');
    }
  }

  void clearEmergencyAlert() {
    _hasNewEmergencyAlert = false;
    _latestEmergency = null;
    notifyListeners();
  }

  void _showEmergencyNotification(Map<String, dynamic> emergency) {
    // This would typically use a notification plugin
    // For now, we just log it
    print('🚨 NEW EMERGENCY: ${emergency['type']} at ${emergency['location']}');
  }

  Future<void> updateDutyStatus(bool status) async {
    _isOnDuty = status;
    if (!status) _isPatrolling = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isOnDuty', status);
    await prefs.setBool('isPatrolling', _isPatrolling);

    notifyListeners();
  }

  Future<void> updatePatrolStatus(bool status) async {
    _isPatrolling = status;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPatrolling', status);

    notifyListeners();
  }
}
