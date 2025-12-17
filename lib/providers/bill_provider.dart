// providers/bill_provider.dart - UPDATED
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class UserBill {
  final String id;
  final String title;
  final String description;
  final double amount;
  final DateTime dueDate;
  final DateTime? paidAt;
  final String status;
  final Map<String, dynamic> user;
  final String? paymentId;
  final int daysOverdue;

  UserBill({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.dueDate,
    this.paidAt,
    required this.status,
    required this.user,
    this.paymentId,
    required this.daysOverdue,
  });

  factory UserBill.fromJson(Map<String, dynamic> json) {
    final dueDate = DateTime.parse(json['dueDate']);
    final now = DateTime.now();
    final daysOverdue = dueDate.isBefore(now)
        ? now.difference(dueDate).inDays
        : 0;

    return UserBill(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Tagihan',
      description: json['description']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      dueDate: dueDate,
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      status: json['status']?.toString() ?? 'PENDING',
      user: json['user'] ?? {'id': 0, 'namaLengkap': 'Unknown', 'email': ''},
      paymentId: json['paymentId']?.toString(),
      daysOverdue: daysOverdue,
    );
  }

  // Enhanced status with more detailed information
  String get statusText {
    switch (status) {
      case 'PAID':
        return 'LUNAS';
      case 'OVERDUE':
        return 'NUNGGAK (${daysOverdue}h)';
      case 'CANCELLED':
        return 'DIBATALKAN';
      default:
        return daysOverdue > 0 ? 'TERLAMBAT (${daysOverdue}h)' : 'BELUM BAYAR';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'PAID':
        return Color(0xFF4CAF50);
      case 'OVERDUE':
        return Color(0xFFF44336);
      case 'CANCELLED':
        return Colors.grey;
      default:
        return daysOverdue > 0 ? Color(0xFFFF9800) : Color(0xFFFFC107);
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'PAID':
        return Icons.check_circle;
      case 'OVERDUE':
        return Icons.warning;
      case 'CANCELLED':
        return Icons.cancel;
      default:
        return daysOverdue > 0 ? Icons.schedule : Icons.pending;
    }
  }

  bool get isPaid => status == 'PAID';
  bool get isOverdue => status == 'OVERDUE' || daysOverdue > 0;
  bool get isPending => status == 'PENDING' && daysOverdue == 0;
}

class BillSummary {
  final int totalBills;
  final int pendingBills;
  final int paidBills;
  final int overdueBills;
  final double totalAmount;
  final double pendingAmount;
  final double paidAmount;

  BillSummary({
    required this.totalBills,
    required this.pendingBills,
    required this.paidBills,
    required this.overdueBills,
    required this.totalAmount,
    required this.pendingAmount,
    required this.paidAmount,
  });

  factory BillSummary.fromJson(Map<String, dynamic> json) {
    return BillSummary(
      totalBills: (json['totalBills'] as num?)?.toInt() ?? 0,
      pendingBills: (json['pendingBills'] as num?)?.toInt() ?? 0,
      paidBills: (json['paidBills'] as num?)?.toInt() ?? 0,
      overdueBills: (json['overdueBills'] as num?)?.toInt() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      pendingAmount: (json['pendingAmount'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
    );
  }

  double get collectionRate {
    return totalAmount > 0 ? (paidAmount / totalAmount) * 100 : 0;
  }
}

class BillProvider with ChangeNotifier {
  final String baseUrl;
  final String token;

  List<UserBill> _bills = [];
  BillSummary _summary = BillSummary(
    totalBills: 0,
    pendingBills: 0,
    paidBills: 0,
    overdueBills: 0,
    totalAmount: 0,
    pendingAmount: 0,
    paidAmount: 0,
  );
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  int _statusFilter = 0; // 0:All, 1:Paid, 2:Pending, 3:Overdue

  List<UserBill> get bills => _bills;
  BillSummary get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  int get statusFilter => _statusFilter;

  // Get filtered bills based on search and status filter
  List<UserBill> get filteredBills {
    var filtered = _bills;

    // Apply status filter
    if (_statusFilter == 1) {
      filtered = filtered.where((bill) => bill.isPaid).toList();
    } else if (_statusFilter == 2) {
      filtered = filtered.where((bill) => bill.isPending).toList();
    } else if (_statusFilter == 3) {
      filtered = filtered.where((bill) => bill.isOverdue).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (bill) =>
                bill.user['namaLengkap']?.toString().toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false,
          )
          .toList();
    }

    return filtered;
  }

  BillProvider({required this.baseUrl, required this.token});

  // Set filters
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(int filter) {
    _statusFilter = filter;
    notifyListeners();
  }

  Future<void> loadBills({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse(
        '$baseUrl/bills',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode.toString().startsWith('2')) {
        final data = json.decode(response.body);
        if (data is Map && data.containsKey('bills')) {
          _bills = (data['bills'] as List)
              .map((billJson) => UserBill.fromJson(billJson))
              .toList();
        } else {
          _bills = [];
        }
        _error = null;
      } else {
        _error = 'Failed to load bills: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadBillSummary() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bills/summary'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode.toString().startsWith('2')) {
        final data = json.decode(response.body);
        _summary = BillSummary.fromJson(data);
      }
    } catch (e) {
      print('Error loading summary: $e');
    }
    notifyListeners();
  }

  // Mark bill as paid
  Future<bool> markAsPaid(String billId, String method) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bills/$billId/pay'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'method': method}),
      );

      if (response.statusCode.toString().startsWith('2')) {
        // Refresh data
        await loadBills();
        await loadBillSummary();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Error: $e';
      notifyListeners();
      return false;
    }
  }

  // Create new bill
  Future<bool> createBill({
    required String title,
    required String description,
    required double amount,
    required DateTime dueDate,
    required int userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bills'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'title': title,
          'description': description,
          'amount': amount,
          'dueDate': dueDate.toIso8601String(),
          'userId': userId,
        }),
      );

      if (response.statusCode.toString().startsWith('2')) {
        await loadBills();
        await loadBillSummary();
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Error: $e';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> createBulkBills({
    required String title,
    required String description,
    required double amount,
    required DateTime dueDate,
    required List<Map<String, dynamic>> users,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      int successCount = 0;
      int totalUsers = users.length;
      
      print('🔄 Creating bulk bills for $totalUsers users...');

      for (int i = 0; i < users.length; i++) {
        final user = users[i];
        final userId = user['id'];
        
        if (userId == null) {
          print('⚠️ Skipping user without ID: $user');
          continue;
        }

        print('📝 Creating bill for user $userId (${i + 1}/$totalUsers)');
        
        final response = await http.post(
          Uri.parse('$baseUrl/bills'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'title': title,
            'description': description,
            'amount': amount,
            'dueDate': dueDate.toIso8601String(),
            'userId': userId,
          }),
        );

        if (response.statusCode == 201 || response.statusCode == 200) {
          successCount++;
          print('✅ Bill created for user $userId');
        } else {
          print('❌ Failed to create bill for user $userId: ${response.statusCode} - ${response.body}');
        }

        // Small delay to avoid overwhelming the server
        await Future.delayed(Duration(milliseconds: 100));
      }

      // Refresh data
      await loadBills();
      await loadBillSummary();
      
      print('🎉 Bulk creation completed: $successCount/$totalUsers successful');
      
      return successCount > 0;
    } catch (e) {
      _error = 'Error creating bulk bills: $e';
      print('❌ Bulk creation error: $e');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ PERBAIKAN: Get users from the existing endpoint
  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      print('🔍 Fetching users from API...');
      
      final response = await http.get(
        Uri.parse('$baseUrl/users?limit=1000'), // Tambahkan limit besar untuk dapat semua user
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 Users API Response: ${response.statusCode}');
      
      if (response.statusCode.toString().startsWith('2')) {
        final data = json.decode(response.body);
        print('📊 Users API Data: $data');
        
        // Handle different response structures
        if (data is Map && data.containsKey('data')) {
          // Format: { "data": [...], "meta": {...} }
          final users = (data['data'] as List).cast<Map<String, dynamic>>();
          print('✅ Found ${users.length} users in data field');
          return users;
        } else if (data is Map && data.containsKey('users')) {
          // Format: { "users": [...] }
          final users = (data['users'] as List).cast<Map<String, dynamic>>();
          print('✅ Found ${users.length} users in users field');
          return users;
        } else if (data is List) {
          // Format: [...]
          print('✅ Found ${data.length} users in array');
          return data.cast<Map<String, dynamic>>();
        } else {
          print('❌ Unknown users response format');
          return [];
        }
      } else {
        print('❌ Failed to fetch users: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching users: $e');
      return [];
    }
  }
}