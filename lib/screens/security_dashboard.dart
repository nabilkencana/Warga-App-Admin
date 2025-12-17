// screens/security_dashboard.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import '../config/api_config.dart';

class SecurityDashboard extends StatefulWidget {
  const SecurityDashboard({Key? key}) : super(key: key);

  @override
  State<SecurityDashboard> createState() => _SecurityDashboardState();
}

class _SecurityDashboardState extends State<SecurityDashboard> {
  bool _isLoading = true;
  List<dynamic> _emergencies = [];
  List<dynamic> _recentLogs = [];
  int _assignedEmergencies = 0;
  Map<String, dynamic>? _securityInfo;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();

    print('🚀 SecurityDashboard initialized');
    print('📱 App base URL: ${ApiConfig.baseUrl}');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      print('👤 User ID: ${authProvider.user?.id}');
      print('🔑 Token available: ${authProvider.token != null}');
      print('🎭 User role: ${authProvider.user?.role}');
      print('🎭 Original role: ${authProvider.originalRole}');
    });

    _verifySecurityId(); // Verifikasi dulu
    _loadDashboardData();
    _startPeriodicUpdates();
  }

  Future<void> _loadDashboardData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final userId = authProvider.user?.id;

      if (token == null || userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      print('🔄 Loading dashboard for User ID: $userId');

      // Gunakan endpoint user-based
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/security/dashboard/user/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode.toString().startsWith('2')) {
        final data = json.decode(response.body);
        print('✅ Dashboard data loaded successfully');

        setState(() {
          _emergencies = data['emergencies'] ?? [];
          _assignedEmergencies = data['assignedEmergencies'] ?? 0;
          _securityInfo = data['securityInfo'];
          _stats = data['stats'];
          _isLoading = false;
        });

        await _loadRecentLogs();
      } else {
        print('❌ Failed to load dashboard: ${response.body}');
        setState(() => _isLoading = false);
      }
    } catch (error) {
      print('❌ Error loading dashboard: $error');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRecentLogs() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final userId = authProvider.user?.id;

      if (token == null || userId == null) return;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/security/logs/user/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode.toString().startsWith('2')) {
        final data = json.decode(response.body);
        setState(() {
          _recentLogs = List.from(data).take(5).toList();
        });
      }
    } catch (error) {
      print('Error loading logs: $error');
    }
  }

  void _startPeriodicUpdates() {
    // Refresh data every 30 seconds
    Future.delayed(Duration(seconds: 30), () {
      if (mounted) {
        _loadDashboardData();
        _startPeriodicUpdates();
      }
    });
  }

  Future<void> _checkIn() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final userId = authProvider.user?.id;

      if (token == null || userId == null) {
        _showSnackbar('Token atau ID tidak valid', isError: true);
        return;
      }

      // Show loading
      showDialog(
  context: context,
  barrierDismissible: false,
  builder: (context) => AlertDialog(
    title: Text(
      'Check-in',
      style: TextStyle(fontWeight: FontWeight.bold),
    ),
    content: Row(
      children: [
        CircularProgressIndicator(color: Colors.grey[700]),
        SizedBox(width: 16),
        Text('Memproses check-in...'),
      ],
    ),
  ),
);


      // Gunakan endpoint user-based
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/security/check-in/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'userId': userId, 'location': 'Posisi saat ini'}),
      );

      Navigator.pop(context);

      if (response.statusCode.toString().startsWith('2')) {
        _showSnackbar('Berhasil check-in');
        await _loadDashboardData();
      } else {
        final errorData = json.decode(response.body);
        _showSnackbar(
          'Gagal check-in: ${errorData['message'] ?? response.reasonPhrase}',
          isError: true,
        );
      }
    } catch (error) {
      _showSnackbar('Gagal check-in: $error', isError: true);
    }
  }

  // Tambahkan fungsi untuk verifikasi security ID
  Future<void> _verifySecurityId() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final userId = authProvider.user?.id;

      if (token == null || userId == null) {
        print('❌ No token or user ID');
        return;
      }

      print('🔍 Verifying if user $userId is security...');

      // Cek apakah user adalah security
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/security/user/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Verification response: ${response.statusCode}');
      print('Verification body: ${response.body}');

      if (response.statusCode.toString().startsWith('2')) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ User is security with ID: ${data['data']['id']}');
        } else {
          print('❌ User is not security personnel');
          _showSnackbar('Anda belum terdaftar sebagai security', isError: true);
        }
      } else if (response.statusCode == 404) {
        print('❌ User not found in security database');
        _showSnackbar('Anda belum terdaftar sebagai security', isError: true);
      }
    } catch (error) {
      print('❌ Error verifying security: $error');
    }
  }

  Future<void> _checkOut() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final userId = authProvider.user?.id;

      if (token == null || userId == null) {
        _showSnackbar('Token atau ID tidak valid', isError: true);
        return;
      }

      // Confirm dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Check-out', style: TextStyle(fontWeight: FontWeight.bold),),
          content: Text('Apakah Anda yakin ingin check-out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Batal',style: TextStyle(color: Colors.grey[700]),),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Ya, Check-out', style: TextStyle(color: Colors.red),),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Check-out'),
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Memproses check-out...'),
            ],
          ),
        ),
      );

      // Gunakan endpoint user-based
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/security/check-out/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'userId': userId}),
      );

      Navigator.pop(context);

      if (response.statusCode.toString().startsWith('2')) {
        _showSnackbar('Berhasil check-out');
        await _loadDashboardData();
      } else {
        final errorData = json.decode(response.body);
        _showSnackbar(
          'Gagal check-out: ${errorData['message'] ?? response.reasonPhrase}',
          isError: true,
        );
      }
    } catch (error) {
      _showSnackbar('Gagal check-out: $error', isError: true);
    }
  }

  Future<void> _updateLocation() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final userId = authProvider.user?.id;

      if (token == null || userId == null) return;

      // Simulate getting location
      const latitude = '-6.2088';
      const longitude = '106.8456';

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/security/update-location/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'userId': userId,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (response.statusCode.toString().startsWith('2')) {
        _showSnackbar('Lokasi berhasil diperbarui');
      }
    } catch (error) {
      _showSnackbar('Gagal update lokasi: $error', isError: true);
    }
  }

  Future<void> _startPatrol() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final userId = authProvider.user?.id;

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/security/patrol/start/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'userId': userId}),
      );

      if (response.statusCode.toString().startsWith('2')) {
        _showSnackbar('Patroli dimulai');
        _loadDashboardData();
      }
    } catch (error) {
      _showSnackbar('Gagal mulai patroli: $error', isError: true);
    }
  }

  Future<void> _endPatrol() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final userId = authProvider.user?.id;

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/security/patrol/end/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'userId': userId}),
      );

      if (response.statusCode.toString().startsWith('2')) {
        _showSnackbar('Patroli selesai');
        _loadDashboardData();
      }
    } catch (error) {
      _showSnackbar('Gagal mengakhiri patroli: $error', isError: true);
    }
  }

  Future<void> _reportIncident(String details) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final userid = authProvider.user?.id;

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/security/incident/report/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'userId': userid, 'details': details}),
      );

      if (response.statusCode.toString().startsWith('2')) {
        _showSnackbar('Laporan insiden berhasil dikirim');
        _loadRecentLogs();
      }
    } catch (error) {
      _showSnackbar('Gagal mengirim laporan: $error', isError: true);
    }
  }

  Future<void> _acceptEmergency(int emergencyId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final userId = authProvider.user?.id;

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/security/emergency/accept/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'userId': userId, 'emergencyId': emergencyId}),
      );

      if (response.statusCode.toString().startsWith('2')) {
        _showSnackbar('Emergency diterima');
        _loadDashboardData();
      }
    } catch (error) {
      _showSnackbar('Gagal menerima emergency: $error', isError: true);
    }
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.grey),
          SizedBox(height: 20),
          Text('Memuat dashboard...', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  String _getShiftName(String? shift) {
    switch (shift) {
      case 'MORNING':
        return 'Pagi';
      case 'AFTERNOON':
        return 'Siang';
      case 'NIGHT':
        return 'Malam';
      case 'FLEXIBLE':
        return 'Fleksibel';
      default:
        return '-';
    }
  }

  IconData _getShiftIcon(String? shift) {
    switch (shift) {
      case 'MORNING':
        return Icons.wb_sunny;
      case 'AFTERNOON':
        return Icons.sunny;
      case 'NIGHT':
        return Icons.nightlight;
      case 'FLEXIBLE':
        return Icons.schedule;
      default:
        return Icons.access_time;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            authProvider.originalRole == 'SATPAM'
                ? 'Satpam Dashboard'
                : 'Security Dashboard',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          backgroundColor: Colors.green.shade800,
        ),
        body: _buildLoadingScreen(),
      );
    }

    final isOnDuty = _securityInfo?['isOnDuty'] ?? false;
    final shift = _securityInfo?['shift'];
    final emergencyCount = _securityInfo?['emergencyCount'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          authProvider.originalRole == 'SATPAM'
              ? 'Satpam Dashboard'
              : 'Security Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.green.shade800,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  return AlertDialog(
                    title: const Text(
                      'Konfirmasi Logout',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    content: const Text(
                      'Apakah kamu yakin ingin keluar dari akun ini?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text(
                          'Batal',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Keluar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  );
                },
              );

              if (confirm == true) {
                await authProvider.logout();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with Security Info
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: Icon(
                            authProvider.originalRole == 'SATPAM'
                                ? Icons.security
                                : Icons.person_pin_circle,
                            color: Colors.green.shade800,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _securityInfo?['nama'] ??
                                    user?.name ??
                                    'Security',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                authProvider.originalRole == 'SATPAM'
                                    ? 'ID: SATPAM-${user?.id.toString().padLeft(4, '0')}'
                                    : 'ID: SEC-${user?.id.toString().padLeft(4, '0')}',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              Text(
                                'Shift: ${_getShiftName(shift)}',
                                style: TextStyle(
                                  color: Colors.blue.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatusCard(
                          icon: Icons.access_time,
                          label: 'Status',
                          value: isOnDuty ? 'On Duty' : 'Off Duty',
                          color: isOnDuty ? Colors.green : Colors.orange,
                        ),
                        _buildStatusCard(
                          icon: Icons.emergency,
                          label: 'Emergency',
                          value: emergencyCount.toString(),
                          color: Colors.red,
                        ),
                        _buildStatusCard(
                          icon: _getShiftIcon(shift),
                          label: 'Shift',
                          value: _getShiftName(shift),
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Duty Control
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kontrol Tugas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isOnDuty
                                ? null
                                : () {
                                    _checkIn();
                                  },
                            icon: Icon(Icons.play_arrow),
                            label: Text('Mulai Tugas'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: !isOnDuty
                                ? null
                                : () {
                                    _checkOut();
                                  },
                            icon: Icon(Icons.stop),
                            label: Text('Selesai'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: !isOnDuty
                                ? null
                                : () {
                                    _startPatrol();
                                  },
                            icon: Icon(Icons.directions_walk),
                            label: Text('Mulai Patroli'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: !isOnDuty
                                ? null
                                : () {
                                    _endPatrol();
                                  },
                            icon: Icon(Icons.directions_walk),
                            label: Text('Akhiri Patroli'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Emergency Section
            if (_emergencies.isNotEmpty)
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Emergency Aktif (${_emergencies.length})',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Chip(
                            label: Text('Ditugaskan: $_assignedEmergencies'),
                            backgroundColor: Colors.red.shade100,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._emergencies.map((emergency) {
                        return _buildEmergencyCard(emergency);
                      }).toList(),
                    ],
                  ),
                ),
              ),
            if (_emergencies.isNotEmpty) const SizedBox(height: 20),

            // Quick Actions
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aksi Cepat',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _buildQuickAction(
                          icon: Icons.location_on,
                          label: 'Update Lokasi',
                          color: Colors.blue.shade700,
                          onTap: _updateLocation,
                        ),
                        _buildQuickAction(
                          icon: Icons.assignment,
                          label: 'Laporan Insiden',
                          color: Colors.orange.shade700,
                          onTap: () => _showReportDialog(),
                        ),
                        _buildQuickAction(
                          icon: Icons.emergency,
                          label: 'Emergency',
                          color: Colors.red.shade700,
                          onTap: () => _showEmergencyDialog(),
                        ),
                        _buildQuickAction(
                          icon: Icons.analytics,
                          label: 'Statistik',
                          color: Colors.purple.shade700,
                          onTap: () => _showStatsDialog(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Recent Activities
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Aktivitas Terbaru',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.refresh),
                          onPressed: () async {
                            final authProvider = Provider.of<AuthProvider>(
                              context,
                              listen: false,
                            );
                            final token = authProvider.token;
                            final userId = authProvider.user?.id;

                            if (token != null && userId != null) {
                              final securityResponse = await http.get(
                                Uri.parse(
                                  '${ApiConfig.baseUrl}/security/user/$userId',
                                ),
                                headers: {
                                  'Authorization': 'Bearer $token',
                                  'Content-Type': 'application/json',
                                },
                              );

                              if (securityResponse.statusCode
                                  .toString()
                                  .startsWith('2')) {
                                json.decode(securityResponse.body);

                                await _loadRecentLogs();
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_recentLogs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          'Tidak ada aktivitas terbaru',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    else
                      ..._recentLogs.map((log) {
                        return _buildActivityItem(log);
                      }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyCard(Map<String, dynamic> emergency) {
    final type = emergency['type'] ?? 'UNKNOWN';
    final severity = emergency['severity'] ?? 'MEDIUM';
    final location = emergency['location'] ?? 'Lokasi tidak diketahui';
    final createdAt = DateTime.parse(emergency['createdAt']).toLocal();
    final responses = emergency['emergencyResponses'] ?? [];

    Color severityColor = Colors.orange;
    if (severity == 'HIGH') severityColor = Colors.red;
    if (severity == 'LOW') severityColor = Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: severityColor.withOpacity(0.1),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: severityColor,
          child: Icon(Icons.warning, color: Colors.white, size: 20),
        ),
        title: Text(
          'Emergency: $type',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(location),
            Text(
              '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: responses.isNotEmpty
            ? Chip(
                label: Text('Ditugaskan'),
                backgroundColor: Colors.green.shade100,
              )
            : ElevatedButton(
                onPressed: () => _acceptEmergency(emergency['id']),
                child: Text('Terima'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      color: color.withOpacity(0.25),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> log) {
    final action = log['action'] ?? 'UNKNOWN';
    final details = log['details'] ?? 'Tidak ada detail';
    final timestamp = DateTime.parse(log['timestamp']).toLocal();
    final timeStr =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

    IconData icon = Icons.info;
    Color color = Colors.blue;

    switch (action) {
      case 'CHECK_IN':
        icon = Icons.play_arrow;
        color = Colors.green;
        break;
      case 'CHECK_OUT':
        icon = Icons.stop;
        color = Colors.red;
        break;
      case 'PATROL_START':
        icon = Icons.directions_walk;
        color = Colors.blue;
        break;
      case 'PATROL_END':
        icon = Icons.directions_walk;
        color = Colors.orange;
        break;
      case 'LOCATION_UPDATE':
        icon = Icons.location_on;
        color = Colors.purple;
        break;
      case 'INCIDENT_REPORT':
        icon = Icons.report;
        color = Colors.orange;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.replaceAll('_', ' '),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  details,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(
            timeStr,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Emergency Response', style: TextStyle(fontWeight: FontWeight.bold),),
        content: Text('Pilih aksi emergency:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: Colors.grey[700]),),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Show emergency list
              _showEmergencyList();
            },
            child: Text('Lihat Daftar', style: TextStyle(color: Colors.red),),
          ),
        ],
      ),
    );
  }

  void _showEmergencyList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Text(
              'Emergency Aktif',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _emergencies.isEmpty
                  ? Center(child: Text('Tidak ada emergency aktif'))
                  : ListView.builder(
                      itemCount: _emergencies.length,
                      itemBuilder: (context, index) {
                        final emergency = _emergencies[index];
                        return _buildEmergencyCard(emergency);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog() {
    final textController = TextEditingController();

final _formKey = GlobalKey<FormState>();
    showDialog(
  context: context,
  barrierDismissible: false,
  builder: (context) => AlertDialog(
    title: const Text(
      'Buat Laporan Insiden',
      style: TextStyle(fontWeight: FontWeight.bold),
    ),
    content: Form(
      key: _formKey,
      child: TextFormField(
        controller: textController,
        maxLines: 4,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Detail insiden tidak boleh kosong';
          }
          return null;
        },
        decoration: const InputDecoration(
          hintText: 'Masukkan detail insiden...',
          border: OutlineInputBorder(),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(
          'Batal',
          style: TextStyle(color: Colors.grey[700]),
        ),
      ),
      ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            _reportIncident(textController.text.trim());
            Navigator.pop(context);
          }
        },
        child: const Text('Kirim', style: TextStyle(color: Colors.orange)),
      ),
    ],
  ),
);
  }

  void _showStatsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Statistik Performa',style: TextStyle(fontWeight: FontWeight.bold),),
        content: _stats == null
            ? Text('Tidak ada data statistik')
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatItem(
                    'Total Response',
                    '${_stats?['totalResponses'] ?? 0}',
                  ),
                  _buildStatItem(
                    'Response Rate',
                    '${_stats?['completionRate'] ?? '0'}%',
                  ),
                  _buildStatItem(
                    'Rata Response Time',
                    '${_stats?['avgResponseTime'] ?? 0} detik',
                  ),
                  _buildStatItem(
                    'Emergency Diselesaikan',
                    '${_securityInfo?['emergencyCount'] ?? 0}',
                  ),
                ],
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
        ],
      ),
    );
  }
}