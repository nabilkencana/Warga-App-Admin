// lib/screens/security_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wargaapp_admin/providers/auth_provider.dart';
import 'package:wargaapp_admin/providers/security_provider.dart';
import 'package:wargaapp_admin/screens/login_screen.dart';

class SecurityProfileScreen extends StatefulWidget {
  const SecurityProfileScreen({Key? key}) : super(key: key);

  @override
  _SecurityProfileScreenState createState() => _SecurityProfileScreenState();
}

class _SecurityProfileScreenState extends State<SecurityProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final securityProvider = Provider.of<SecurityProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green[900],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Text(
                      authProvider.userName?.substring(0, 1).toUpperCase() ??
                          'S',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    authProvider.userName ?? 'Security Officer',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'SATPAM - ${authProvider.userEmail}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'SECURITY PERSONNEL',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Stats Cards
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Emergencies',
                      '${securityProvider.emergencies.length}',
                      Icons.warning,
                      Colors.orange,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Response Rate',
                      securityProvider.emergencies.isNotEmpty ? '95%' : '0%',
                      Icons.timer,
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 12),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Patrols',
                      '${securityProvider.patrolLogs.where((log) => log['action'] == 'PATROL_START').length}',
                      Icons.directions_walk,
                      Colors.blue,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Incidents',
                      '${securityProvider.incidents.length}',
                      Icons.report_problem,
                      Colors.red,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Settings Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 12),

                  // Duty Status Toggle
                  Card(
                    child: SwitchListTile(
                      title: Text('Duty Status'),
                      subtitle: Text(
                        securityProvider.isOnDuty
                            ? 'Currently on duty'
                            : 'Currently off duty',
                      ),
                      secondary: Icon(
                        securityProvider.isOnDuty
                            ? Icons.verified_user
                            : Icons.person_off,
                        color: securityProvider.isOnDuty
                            ? Colors.green
                            : Colors.grey,
                      ),
                      value: securityProvider.isOnDuty,
                      onChanged: (value) {
                        if (value) {
                          securityProvider.checkIn();
                        } else {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Check Out'),
                              content: Text(
                                'Are you sure you want to end your duty shift?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    securityProvider.checkOut();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: Text('Check Out'),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    ),
                  ),

                  // Location Services Toggle
                  Card(
                    child: SwitchListTile(
                      title: Text('Location Services'),
                      subtitle: Text(
                        securityProvider.isLocationEnabled
                            ? 'GPS tracking enabled'
                            : 'GPS tracking disabled',
                      ),
                      secondary: Icon(
                        securityProvider.isLocationEnabled
                            ? Icons.location_on
                            : Icons.location_off,
                        color: securityProvider.isLocationEnabled
                            ? Colors.blue
                            : Colors.grey,
                      ),
                      value: securityProvider.isLocationEnabled,
                      onChanged: (value) {
                        if (value) {
                          securityProvider.updateLocation();
                        } else {
                          // Just update the UI state
                          setState(() {
                            // In a real app, you would disable location services here
                          });
                        }
                      },
                    ),
                  ),

                  // Notification Settings
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.notifications, color: Colors.purple),
                      title: Text('Notifications'),
                      subtitle: Text('Emergency alerts, patrol reminders'),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Implement notification settings
                      },
                    ),
                  ),

                  // Account Settings
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.person, color: Colors.blue),
                      title: Text('Account Information'),
                      subtitle: Text('View and update profile'),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Implement account settings
                      },
                    ),
                  ),

                  // About App
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.info, color: Colors.green),
                      title: Text('About WargaApp'),
                      subtitle: Text('Version 1.0.0'),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: 'WargaApp Security',
                          applicationVersion: '1.0.0',
                          applicationLegalese:
                              '© 2025 WargaApp. All rights reserved.',
                          children: [
                            SizedBox(height: 12),
                            Text('Security Dashboard for SATPAM personnel'),
                            SizedBox(height: 8),
                            Text('Features:'),
                            SizedBox(height: 4),
                            Text('• Emergency response system'),
                            Text('• Patrol tracking'),
                            Text('• Incident reporting'),
                            Text('• Real-time location tracking'),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32),

            // Logout Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Logout'),
                        content: Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              await authProvider.logout();
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoginScreen(),
                                ),
                                (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: Text('Logout'),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(Icons.logout, color: Colors.white),
                  label: Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
