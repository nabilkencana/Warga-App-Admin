// lib/screens/security_emergencies_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wargaapp_admin/providers/security_provider.dart';
import 'package:wargaapp_admin/widgets/security_emergency_card.dart';

class SecurityEmergenciesScreen extends StatefulWidget {
  const SecurityEmergenciesScreen({Key? key}) : super(key: key);

  @override
  _SecurityEmergenciesScreenState createState() =>
      _SecurityEmergenciesScreenState();
}

class _SecurityEmergenciesScreenState extends State<SecurityEmergenciesScreen> {
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
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active Emergencies',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${securityProvider.pendingEmergencyCount} pending, ${securityProvider.emergencies.length} total',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey[200]),

          // Emergencies List
          Expanded(
            child: securityProvider.isLoading
                ? Center(child: CircularProgressIndicator())
                : securityProvider.emergencies.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 64, color: Colors.green),
                        SizedBox(height: 16),
                        Text(
                          'No Active Emergencies',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'All emergencies have been responded to',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await securityProvider.refreshEmergencies();
                    },
                    child: ListView.builder(
                      padding: EdgeInsets.only(bottom: 80),
                      itemCount: securityProvider.emergencies.length,
                      itemBuilder: (context, index) {
                        final emergency = securityProvider.emergencies[index];
                        final isResponded =
                            emergency['status'] == 'RESPONDING' ||
                            emergency['status'] == 'HANDLING';

                        return SecurityEmergencyCard(
                          emergency: emergency,
                          isResponded: isResponded,
                          onRespond: !isResponded
                              ? () {
                                  securityProvider.respondToEmergency(
                                    emergency['id'],
                                    emergency['type'] ?? 'Emergency',
                                  );
                                }
                              : null,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
