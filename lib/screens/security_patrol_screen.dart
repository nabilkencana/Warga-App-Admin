// lib/screens/security_patrol_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wargaapp_admin/providers/security_provider.dart';

class SecurityPatrolScreen extends StatefulWidget {
  const SecurityPatrolScreen({Key? key}) : super(key: key);

  @override
  _SecurityPatrolScreenState createState() => _SecurityPatrolScreenState();
}

class _SecurityPatrolScreenState extends State<SecurityPatrolScreen> {
  @override
  Widget build(BuildContext context) {
    final securityProvider = Provider.of<SecurityProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.directions_walk, color: Colors.blue, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Patrol Management',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            securityProvider.isOnDuty
                                ? 'On Duty - ${securityProvider.isPatrolling ? "Patrolling" : "Available"}'
                                : 'Off Duty',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Stats Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Patrols Today',
                        '${securityProvider.patrolLogs.where((log) => log['action'] == 'PATROL_START').length}',
                        Icons.directions_walk,
                        Colors.blue,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Response Time',
                        securityProvider.patrolLogs.isNotEmpty ? '5m' : 'N/A',
                        Icons.timer,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey[200]),

          // Main Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Duty Status Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Duty Status',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        securityProvider.isOnDuty
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        color: securityProvider.isOnDuty
                                            ? Colors.green
                                            : Colors.red,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        securityProvider.isOnDuty
                                            ? 'ON DUTY'
                                            : 'OFF DUTY',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: securityProvider.isOnDuty
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    securityProvider.isOnDuty
                                        ? 'Shift started'
                                        : 'Not checked in',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  if (!securityProvider.isOnDuty) {
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
                                            onPressed: () =>
                                                Navigator.pop(context),
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
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: securityProvider.isOnDuty
                                      ? Colors.red
                                      : Colors.green,
                                ),
                                child: Text(
                                  securityProvider.isOnDuty
                                      ? 'Check Out'
                                      : 'Check In',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Patrol Status Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Patrol Status',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        securityProvider.isPatrolling
                                            ? Icons.directions_walk
                                            : Icons.pause_circle_filled,
                                        color: securityProvider.isPatrolling
                                            ? Colors.blue
                                            : Colors.orange,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        securityProvider.isPatrolling
                                            ? 'PATROLLING'
                                            : 'STOPPED',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: securityProvider.isPatrolling
                                              ? Colors.blue
                                              : Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    securityProvider.isPatrolling
                                        ? 'Active patrol in progress'
                                        : 'No active patrol',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: securityProvider.isOnDuty
                                    ? () {
                                        if (!securityProvider.isPatrolling) {
                                          securityProvider.startPatrol();
                                        } else {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text('End Patrol'),
                                              content: Text(
                                                'Are you sure you want to end the current patrol?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    securityProvider
                                                        .endPatrol();
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.orange,
                                                      ),
                                                  child: Text('End Patrol'),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: securityProvider.isPatrolling
                                      ? Colors.orange
                                      : Colors.blue,
                                ),
                                child: Text(
                                  securityProvider.isPatrolling
                                      ? 'End Patrol'
                                      : 'Start Patrol',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Location Status Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Location Services',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        securityProvider.isLocationEnabled
                                            ? Icons.location_on
                                            : Icons.location_off,
                                        color:
                                            securityProvider.isLocationEnabled
                                            ? Colors.green
                                            : Colors.red,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        securityProvider.isLocationEnabled
                                            ? 'ENABLED'
                                            : 'DISABLED',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              securityProvider.isLocationEnabled
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    securityProvider.isLocationEnabled
                                        ? 'GPS tracking active'
                                        : 'Location services off',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              if (securityProvider.currentPosition != null)
                                Chip(
                                  label: Text('Live'),
                                  backgroundColor: Colors.green[100],
                                  avatar: Icon(
                                    Icons.circle,
                                    size: 8,
                                    color: Colors.green,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  Spacer(),

                  // Patrol Logs
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.history,
                                size: 20,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Recent Patrol Logs',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          if (securityProvider.patrolLogs.isEmpty)
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                'No patrol logs yet',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            )
                          else
                            Column(
                              children: securityProvider.patrolLogs
                                  .take(3)
                                  .map(
                                    (log) => ListTile(
                                      leading: Icon(
                                        _getActionIcon(log['action']),
                                        size: 20,
                                        color: Colors.blue,
                                      ),
                                      title: Text(
                                        _getActionText(log['action']),
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      subtitle: Text(
                                        _formatTime(log['timestamp']),
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      dense: true,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  )
                                  .toList(),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'CHECK_IN':
        return Icons.login;
      case 'CHECK_OUT':
        return Icons.logout;
      case 'PATROL_START':
        return Icons.directions_walk;
      case 'PATROL_END':
        return Icons.stop;
      case 'EMERGENCY_RESPONSE':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }

  String _getActionText(String action) {
    switch (action) {
      case 'CHECK_IN':
        return 'Started duty shift';
      case 'CHECK_OUT':
        return 'Ended duty shift';
      case 'PATROL_START':
        return 'Started patrol';
      case 'PATROL_END':
        return 'Ended patrol';
      case 'EMERGENCY_RESPONSE':
        return 'Responded to emergency';
      default:
        return action;
    }
  }

  String _formatTime(String timestamp) {
    try {
      final time = DateTime.parse(timestamp);
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Just now';
    }
  }
}
