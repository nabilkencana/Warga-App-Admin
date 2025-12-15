// main.dart - UPDATED WITH BILL MANAGEMENT
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wargaapp_admin/models/user.dart';
import 'package:wargaapp_admin/providers/emergency_provider.dart';
import 'package:wargaapp_admin/providers/report_provider.dart';
import 'package:wargaapp_admin/screens/admin_dashboard.dart';
import 'package:wargaapp_admin/screens/user_detail_screen.dart';
import 'screens/users_screen.dart';
import 'screens/announcements_screen.dart';
import 'screens/emergencies_screen.dart';
import 'screens/volunteers_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/bill_management_screen.dart'; // ADD THIS IMPORT
import 'providers/admin_provider.dart';
import 'providers/announcement_provider.dart';
import 'providers/bill_provider.dart'; // ADD THIS IMPORT
import 'services/admin_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Define your base URL and token
    const String baseUrl =
        'https://wargakita.canadev.my.id'; // Replace with your actual API URL
    const String token =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjEsImVtYWlsIjoibmFiaWxrZW5jYW5hMjBAZ21haWwuY29tIiwicm9sZSI6IkFETUlOIiwibmFtZSI6Ik5hYmlsIEFkbWluIiwiaWF0IjoxNzY1Nzk5MjkyLCJleHAiOjE4NTIxOTkyOTJ9.dKAMleKsfNl4X6p1bbZ4upq2cjZl6RNO9A6xQSAg2H0';

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AdminProvider(AdminService(token,)),
        ),
        ChangeNotifierProvider(create: (context) => AnnouncementProvider()),
        ChangeNotifierProvider(create: (context) => ReportProvider()),
        ChangeNotifierProvider(create: (context) => EmergencyProvider()),
        // ADD BILL PROVIDER
        ChangeNotifierProvider(
          create: (context) => BillProvider(baseUrl: baseUrl, token: token),
        ),
      ],
      child: MaterialApp(
        title: 'WARGA KITA - Admin Dashboard',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Inter',
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => AdminDashboardScreen(token: token),
          '/users': (context) => UsersScreen(),
          '/announcements': (context) => AnnouncementsScreen(),
          '/emergencies': (context) => EmergenciesScreen(),
          '/volunteers': (context) => VolunteersScreen(),
          '/reports': (context) => ReportsScreen(),
          // ADD BILL MANAGEMENT ROUTE
          '/bills': (context) => BillManagementScreen(token: token),
          '/user-detail': (context) {
            final user = ModalRoute.of(context)!.settings.arguments as User;
            return UserDetailScreen(userId: user.id);
          },
        },
      ),
    );
  }
}
