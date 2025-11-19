// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:user_management_app/models/user.dart';
import 'package:user_management_app/providers/emergency_provider.dart';
import 'package:user_management_app/providers/report_provider.dart';
import 'package:user_management_app/screens/admin_dashboard.dart';
import 'package:user_management_app/screens/user_detail_screen.dart';
import 'screens/users_screen.dart';
import 'screens/announcements_screen.dart';
import 'screens/emergencies_screen.dart';
import 'screens/volunteers_screen.dart';
import 'screens/reports_screen.dart';
import 'providers/admin_provider.dart';
import 'providers/announcement_provider.dart';
import 'services/admin_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) =>
              AdminProvider(AdminService('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjEsImVtYWlsIjoibmFiaWxrZW5jYW5hMjBAZ21haWwuY29tIiwicm9sZSI6ImFkbWluIiwiaWF0IjoxNzYzNTA5Mzk1LCJleHAiOjE3NjM1OTU3OTV9.sQ9BxVL8vOsv9_tfCAxwVfC6-Tex0hexF5TnJbEVak0')),
        ),
        ChangeNotifierProvider(create: (context) => AnnouncementProvider()),
        ChangeNotifierProvider(create: (context) => ReportProvider()),
        ChangeNotifierProvider(
          create: (context) => EmergencyProvider(),
        ), // Tambahkan ini
      ],
      child: MaterialApp(
        title: 'WARGA KITA',
        theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Inter'),
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => AdminDashboardScreen(token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjEsImVtYWlsIjoibmFiaWxrZW5jYW5hMjBAZ21haWwuY29tIiwicm9sZSI6ImFkbWluIiwiaWF0IjoxNzYzNTA5Mzk1LCJleHAiOjE3NjM1OTU3OTV9.sQ9BxVL8vOsv9_tfCAxwVfC6-Tex0hexF5TnJbEVak0'),

          '/users': (context) => UsersScreen(),
          '/announcements': (context) => AnnouncementsScreen(),
          '/emergencies': (context) => EmergenciesScreen(),
          '/volunteers': (context) => VolunteersScreen(),
          '/reports': (context) => ReportsScreen(),
          '/user-detail': (context) {
            final user = ModalRoute.of(context)!.settings.arguments as User;
            return UserDetailScreen(userId: user.id);
          },
        },
      ),
    );
  }
}
