// providers/emergency_provider.dart
import 'package:flutter/foundation.dart';
import '../models/emergency.dart';
import '../services/emergency_service.dart';

class EmergencyProvider with ChangeNotifier {
  final EmergencyService _emergencyService = EmergencyService();

  List<Emergency> _emergencies = [];
  List<Emergency> _filteredEmergencies = [];
  bool _isLoading = false;
  String? _error;
  String _selectedFilter = 'Aktif';
  String _selectedType = 'Semua';
  int? _currentUserId;

  List<Emergency> get emergencies => _filteredEmergencies;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedFilter => _selectedFilter;
  String get selectedType => _selectedType;

  final List<String> _statusFilters = [
    'Semua',
    'Aktif',
    'Butuh Relawan',
    'Selesai',
  ];
  final List<String> _typeFilters = [
    'Semua',
    'Kebakaran',
    'Banjir',
    'Gempa',
    'Kecelakaan',
    'Medis',
    'Bencana Alam',
  ];

  List<String> get statusFilters => _statusFilters;
  List<String> get typeFilters => _typeFilters;

  // Set current user ID
  void setCurrentUserId(int? userId) {
    _currentUserId = userId;
    notifyListeners();
  }

  Future<void> loadActiveEmergencies() async {
    _setLoading(true);
    _error = null;

    try {
      _emergencies = await _emergencyService.getActiveEmergencies();
      _applyFilters();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadAllEmergencies() async {
    _setLoading(true);
    _error = null;

    try {
      _emergencies = await _emergencyService.getAllEmergencies();
      _applyFilters();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadEmergenciesNeedVolunteers() async {
    _setLoading(true);
    _error = null;

    try {
      _emergencies = await _emergencyService.getEmergenciesNeedVolunteers();
      _applyFilters();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createSOS({
    required String type,
    String? details,
    String? location,
    String? latitude,
    String? longitude,
    bool needVolunteer = false,
    int volunteerCount = 0,
  }) async {
    _setLoading(true);

    try {
      final newEmergency = await _emergencyService.createSOS(
        type: type,
        details: details,
        location: location,
        latitude: latitude,
        longitude: longitude,
        needVolunteer: needVolunteer,
        volunteerCount: volunteerCount,
        userId: _currentUserId,
      );

      _emergencies.insert(0, newEmergency);
      _applyFilters();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateStatus(int id, String status) async {
    _setLoading(true);

    try {
      final updatedEmergency = await _emergencyService.updateStatus(id, status);
      final index = _emergencies.indexWhere((emergency) => emergency.id == id);
      if (index != -1) {
        _emergencies[index] = updatedEmergency;
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggleNeedVolunteer({
    required int id,
    required bool needVolunteer,
    int? volunteerCount,
  }) async {
    _setLoading(true);

    try {
      final updatedEmergency = await _emergencyService.toggleNeedVolunteer(
        id: id,
        needVolunteer: needVolunteer,
        volunteerCount: volunteerCount,
      );

      final index = _emergencies.indexWhere((emergency) => emergency.id == id);
      if (index != -1) {
        _emergencies[index] = updatedEmergency;
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> registerVolunteer({
    required int emergencyId,
    String? userName,
    String? userPhone,
    String? skills,
  }) async {
    _setLoading(true);

    try {
      await _emergencyService.registerVolunteer(
        emergencyId: emergencyId,
        userId: _currentUserId,
        userName: userName,
        userPhone: userPhone,
        skills: skills,
      );

      // Reload emergencies to get updated volunteer data
      await loadAllEmergencies();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    _applyFilters();
    notifyListeners();
  }

  void setType(String type) {
    _selectedType = type;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredEmergencies = _emergencies.where((emergency) {
      final statusMatch =
          _selectedFilter == 'Semua' ||
          (_selectedFilter == 'Aktif' && emergency.status == 'ACTIVE') ||
          (_selectedFilter == 'Butuh Relawan' &&
              emergency.needVolunteer &&
              emergency.status == 'ACTIVE') ||
          (_selectedFilter == 'Selesai' && emergency.status == 'RESOLVED');

      final typeMatch =
          _selectedType == 'Semua' || emergency.type == _selectedType;

      return statusMatch && typeMatch;
    }).toList();

    _filteredEmergencies.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Statistics
  Future<Map<String, dynamic>> getEmergencyStats() async {
    try {
      return await _emergencyService.getEmergencyStats();
    } catch (e) {
      // Fallback to local calculation
      return {
        'total': _emergencies.length,
        'active': _emergencies.where((e) => e.status == 'ACTIVE').length,
        'resolved': _emergencies.where((e) => e.status == 'RESOLVED').length,
        'needVolunteers': _emergencies
            .where((e) => e.needVolunteer && e.status == 'ACTIVE')
            .length,
      };
    }
  }

  // Check if user is already registered as volunteer for an emergency
  bool isUserVolunteer(Emergency emergency) {
    if (_currentUserId == null) return false;
    return emergency.volunteers.any(
      (volunteer) => volunteer.userId == _currentUserId,
    );
  }

  // Check if user can manage emergency (admin or creator)
  bool canManageEmergency(Emergency emergency) {
    // Implement your logic here - for example:
    // return _currentUserId == emergency.userId || _isAdmin;
    return true; // Temporary - replace with actual logic
  }
}
