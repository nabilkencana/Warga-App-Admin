// providers/admin_provider.dart
import 'package:flutter/foundation.dart';
import 'package:user_management_app/models/dashboard_stats.dart';
import 'package:user_management_app/models/user.dart';
import 'package:user_management_app/services/admin_service.dart';

class AdminProvider with ChangeNotifier {
  final AdminService _adminService;

  DashboardStats? _dashboardStats;
  List<User> _recentUsers = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  AdminProvider(this._adminService);

  DashboardStats? get dashboardStats => _dashboardStats;
  List<User> get recentUsers => _recentUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  Future<void> loadDashboardData() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([_loadDashboardStats(), _loadRecentUsers()]);
      _isInitialized = true;
    } catch (e) {
      _error = e.toString();
      print('Error loading dashboard data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadDashboardStats() async {
    try {
      _dashboardStats = await _adminService.getDashboardStats();
    } catch (e) {
      print('Error loading dashboard stats: $e');
      rethrow;
    }
  }

  Future<void> _loadRecentUsers() async {
    try {
      _recentUsers = await _adminService.getRecentUsers();
      print('Loaded ${_recentUsers.length} users');
    } catch (e) {
      print('Error loading recent users: $e');
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void refresh() {
    _isInitialized = false;
    loadDashboardData();
  }
}
