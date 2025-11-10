// providers/admin_provider.dart
import 'package:flutter/foundation.dart';
import '../services/admin_service.dart';
import '../models/dashboard_stats.dart';
import '../models/user.dart';

class AdminProvider with ChangeNotifier {
  final AdminService _adminService;

  DashboardStats? _dashboardStats;
  List<User> _recentUsers = [];
  bool _isLoading = false;
  String? _error;

  AdminProvider(this._adminService);

  DashboardStats? get dashboardStats => _dashboardStats;
  List<User> get recentUsers => _recentUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([_loadDashboardStats(), _loadRecentUsers()]);
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
    } catch (e) {
      print('Error loading recent users: $e');
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
