// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:user_management_app/screens/admin_dashboard.dart';
import 'providers/admin_provider.dart';
import 'services/admin_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Dashboard',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ChangeNotifierProvider( 
        create: (context) => AdminProvider(
          AdminService('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjQsImVtYWlsIjoic2h1dHRhbnByYW1lc3RpQGdtYWlsLmNvbSIsInJvbGUiOiJhZG1pbiIsImlhdCI6MTc2MjY5OTIwMCwiZXhwIjoxNzYyNzg1NjAwfQ.7pWlM6YBlkJgZktMqrNXc9ouJF8dP00bf1rSKRHwEzI'), // Ganti dengan token yang valid
        ),
        child: AdminDashboardScreen(
          token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjQsImVtYWlsIjoic2h1dHRhbnByYW1lc3RpQGdtYWlsLmNvbSIsInJvbGUiOiJhZG1pbiIsImlhdCI6MTc2MjY5OTIwMCwiZXhwIjoxNzYyNzg1NjAwfQ.7pWlM6YBlkJgZktMqrNXc9ouJF8dP00bf1rSKRHwEzI', // Ganti dengan token yang valid
        ),
      ),
    );
  }
}
