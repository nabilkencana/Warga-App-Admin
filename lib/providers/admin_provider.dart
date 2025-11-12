// providers/admin_provider.dart - PERBAIKAN
import 'package:flutter/foundation.dart';
import '../services/admin_service.dart';
import '../models/dashboard_stats.dart';
import '../models/user.dart';

class AdminProvider with ChangeNotifier {
  final AdminService _adminService;

  DashboardStats? _dashboardStats;
  List<User> _recentUsers = []; // 5 user terbaru untuk dashboard
  List<User> _allUsers = []; // Semua user untuk users screen
  bool _isLoading = false;
  bool _isLoadingUsers = false;
  String? _error;

  AdminProvider(this._adminService);

  DashboardStats? get dashboardStats => _dashboardStats;
  List<User> get recentUsers => _recentUsers;
  List<User> get allUsers => _allUsers;
  bool get isLoading => _isLoading;
  bool get isLoadingUsers => _isLoadingUsers;
  String? get error => _error;

  Future<void> loadDashboardData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        _loadDashboardStats(),
        _loadRecentUsers(), // Hanya load 5 user untuk dashboard
      ]);
    } catch (e) {
      _error = e.toString();
      print('Error loading dashboard data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // METHOD BARU UNTUK LOAD SEMUA USER
  Future<void> loadAllUsers() async {
    _isLoadingUsers = true;
    _error = null;
    notifyListeners();

    try {
      await _loadAllUsers();
    } catch (e) {
      _error = e.toString();
      print('Error loading all users: $e');
    } finally {
      _isLoadingUsers = false;
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
      print('Loaded ${_recentUsers.length} recent users for dashboard');
    } catch (e) {
      print('Error loading recent users: $e');
      rethrow;
    }
  }

  // METHOD BARU UNTUK LOAD SEMUA USER
  Future<void> _loadAllUsers() async {
    try {
      _allUsers = await _adminService.getAllUsers();
      print('Loaded ${_allUsers.length} all users for users screen');
    } catch (e) {
      print('Error loading all users: $e');
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Method untuk menambah user baru
  void addUser(User newUser) {
    _allUsers.insert(0, newUser); // Tambah ke semua users
    _recentUsers.insert(0, newUser); // Juga tambah ke recent users
    if (_recentUsers.length > 5) {
      _recentUsers = _recentUsers.take(5).toList(); // Maintain hanya 5 terbaru
    }
    notifyListeners();
  }
}