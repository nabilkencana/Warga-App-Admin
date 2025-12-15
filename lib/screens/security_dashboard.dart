// lib/screens/security_dashboard.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wargaapp_admin/providers/auth_provider.dart';
import 'package:wargaapp_admin/providers/security_provider.dart';
import 'package:wargaapp_admin/screens/login_screen.dart';
import 'package:wargaapp_admin/screens/security_emergencies_screen.dart';
import 'package:wargaapp_admin/screens/security_incidents_screen.dart';
import 'package:wargaapp_admin/screens/security_patrol_screen.dart';
import 'package:wargaapp_admin/screens/security_profile_screen.dart';


class SecurityDashboardScreen extends StatefulWidget {
  const SecurityDashboardScreen({Key? key}) : super(key: key);

  @override
  _SecurityDashboardScreenState createState() =>
      _SecurityDashboardScreenState();
}

class _SecurityDashboardScreenState extends State<SecurityDashboardScreen> {
  int _selectedIndex = 0;
  Timer? _locationTimer;
  Timer? _emergencyTimer;

  static final List<Widget> _widgetOptions = [
    SecurityEmergenciesScreen(),
    SecurityPatrolScreen(),
    SecurityIncidentsScreen(),
    SecurityProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeSecurity();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _emergencyTimer?.cancel();
    super.dispose();
  }

  void _initializeSecurity() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final securityProvider = context.read<SecurityProvider>();

      // Initialize security data
      securityProvider.initializeSecurity(authProvider.userId!);

      // Start periodic location updates (every 30 seconds)
      _locationTimer = Timer.periodic(Duration(seconds: 30), (timer) {
        securityProvider.updateLocation();
      });

      // Start periodic emergency check (every 10 seconds)
      _emergencyTimer = Timer.periodic(Duration(seconds: 10), (timer) {
        securityProvider.checkNewEmergencies();
      });
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = context.read<AuthProvider>();
              final securityProvider = context.read<SecurityProvider>();

              // Check out dari duty jika sedang bertugas
              if (securityProvider.isOnDuty) {
                await securityProvider.checkOut();
              }

              // Logout
              await authProvider.logout();

              // Navigate ke login screen
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    if (_selectedIndex == 0) {
      // Emergencies tab
      return FloatingActionButton.extended(
        onPressed: () {
          context.read<SecurityProvider>().refreshEmergencies();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Emergencies refreshed')));
        },
        icon: Icon(Icons.refresh),
        label: Text('Refresh'),
        backgroundColor: Colors.blue[800],
      );
    } else if (_selectedIndex == 1) {
      // Patrol tab
      return Consumer<SecurityProvider>(
        builder: (context, provider, child) {
          return FloatingActionButton.extended(
            onPressed: () {
              if (!provider.isOnDuty) {
                provider.checkIn();
              } else if (!provider.isPatrolling) {
                provider.startPatrol();
              } else {
                provider.endPatrol();
              }
            },
            icon: Icon(_getPatrolIcon(provider)),
            label: Text(_getPatrolText(provider)),
            backgroundColor: _getPatrolColor(provider),
          );
        },
      );
    }
    return SizedBox.shrink();
  }

  IconData _getPatrolIcon(SecurityProvider provider) {
    if (!provider.isOnDuty) return Icons.login;
    if (!provider.isPatrolling) return Icons.directions_walk;
    return Icons.stop;
  }

  String _getPatrolText(SecurityProvider provider) {
    if (!provider.isOnDuty) return 'Check In';
    if (!provider.isPatrolling) return 'Start Patrol';
    return 'End Patrol';
  }

  Color _getPatrolColor(SecurityProvider provider) {
    if (!provider.isOnDuty) return Colors.green;
    if (!provider.isPatrolling) return Colors.blue;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final securityProvider = Provider.of<SecurityProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.security, size: 24),
            SizedBox(width: 8),
            Text('Security Dashboard'),
            SizedBox(width: 8),
            if (securityProvider.isOnDuty) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'ON DUTY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.green[900],
        actions: [
          // Emergency Alert Badge
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.warning),
                onPressed: () {
                  setState(() {
                    _selectedIndex = 0;
                  });
                },
              ),
              if (securityProvider.pendingEmergencyCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${securityProvider.pendingEmergencyCount}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          // Profile Menu
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profile') {
                setState(() {
                  _selectedIndex = 3;
                });
              } else if (value == 'logout') {
                _handleLogout();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person, size: 20),
                      SizedBox(width: 8),
                      Text('Profile'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Logout', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ];
            },
            child: Padding(
              padding: EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: Text(
                  authProvider.userName?.substring(0, 1).toUpperCase() ?? 'S',
                  style: TextStyle(
                    color: Colors.green[900],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          _widgetOptions[_selectedIndex],

          // Emergency Alert Overlay
          if (securityProvider.hasNewEmergencyAlert)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _buildEmergencyAlert(),
            ),

          // Status Bar
          Positioned(
            bottom: 70,
            left: 16,
            right: 16,
            child: _buildStatusBar(securityProvider),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.warning),
            label: 'Emergency',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_walk),
            label: 'Patrol',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Incidents',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green[900],
        unselectedItemColor: Colors.grey[600],
        selectedFontSize: 12,
        unselectedFontSize: 12,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildEmergencyAlert() {
    return Consumer<SecurityProvider>(
      builder: (context, provider, child) {
        final emergency = provider.latestEmergency;
        if (emergency == null) return SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            provider.clearEmergencyAlert();
            // Navigate to emergency detail
            _showEmergencyDetail(emergency);
          },
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getEmergencyColor(emergency['severity']),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.white, size: 30),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🚨 NEW EMERGENCY ALERT',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        emergency['type'] ?? 'Emergency',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        emergency['location'] ?? 'Location unknown',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: provider.clearEmergencyAlert,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBar(SecurityProvider provider) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
              SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    provider.isOnDuty ? Icons.circle : Icons.circle_outlined,
                    size: 12,
                    color: provider.isOnDuty ? Colors.green : Colors.grey,
                  ),
                  SizedBox(width: 4),
                  Text(
                    provider.isOnDuty ? 'On Duty' : 'Off Duty',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: provider.isOnDuty ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Patrol',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
              SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    provider.isPatrolling ? Icons.directions_walk : Icons.pause,
                    size: 12,
                    color: provider.isPatrolling ? Colors.blue : Colors.grey,
                  ),
                  SizedBox(width: 4),
                  Text(
                    provider.isPatrolling ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: provider.isPatrolling ? Colors.blue : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Emergencies',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
              SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.warning, size: 12, color: Colors.orange),
                  SizedBox(width: 4),
                  Text(
                    '${provider.pendingEmergencyCount} pending',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Location',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
              SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    provider.isLocationEnabled
                        ? Icons.location_on
                        : Icons.location_off,
                    size: 12,
                    color: provider.isLocationEnabled
                        ? Colors.blue
                        : Colors.grey,
                  ),
                  SizedBox(width: 4),
                  Text(
                    provider.isLocationEnabled ? 'Active' : 'Off',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: provider.isLocationEnabled
                          ? Colors.blue
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getEmergencyColor(String severity) {
    switch (severity) {
      case 'CRITICAL':
        return Colors.red;
      case 'HIGH':
        return Colors.orange;
      case 'MEDIUM':
        return Colors.yellow[700]!;
      case 'LOW':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  void _showEmergencyDetail(Map<String, dynamic> emergency) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Emergency Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              emergency['type'] ?? 'Emergency',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Location: ${emergency['location'] ?? 'Unknown'}',
              style: TextStyle(color: Colors.grey[700]),
            ),
            SizedBox(height: 4),
            Text(
              'Severity: ${emergency['severity'] ?? 'MEDIUM'}',
              style: TextStyle(
                color: _getEmergencyColor(emergency['severity'] ?? 'MEDIUM'),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            if (emergency['details'] != null)
              Text('Details: ${emergency['details']}'),
            SizedBox(height: 12),
            Text(
              'Reported: ${_formatDateTime(emergency['createdAt'])}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<SecurityProvider>().respondToEmergency(
                emergency['id'],
                emergency['type'] ?? 'Emergency',
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Respond Now'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String dateTime) {
    try {
      final date = DateTime.parse(dateTime);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Just now';
    }
  }
}
