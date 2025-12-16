// main.dart - UPDATED WITH AUTHENTICATION
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wargaapp_admin/models/user.dart';
import 'package:wargaapp_admin/providers/emergency_provider.dart';
import 'package:wargaapp_admin/providers/report_provider.dart';
import 'package:wargaapp_admin/screens/admin_dashboard.dart';
import 'package:wargaapp_admin/screens/login_screen.dart';
import 'package:wargaapp_admin/screens/security_dashboard.dart'; // ADD SECURITY DASHBOARD
import 'package:wargaapp_admin/screens/user_detail_screen.dart';
import 'package:wargaapp_admin/providers/auth_provider.dart'; // ADD AUTH PROVIDER
import 'screens/users_screen.dart';
import 'screens/announcements_screen.dart';
import 'screens/emergencies_screen.dart';
import 'screens/volunteers_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/bill_management_screen.dart';
import 'providers/admin_provider.dart';
import 'providers/announcement_provider.dart';
import 'providers/bill_provider.dart';
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
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, AdminProvider>(
          create: (context) => AdminProvider(AdminService('')),
          update: (context, authProvider, adminProvider) {
            final token = authProvider.token;
            return AdminProvider(AdminService(token ?? ''));
          },
        ),
        ChangeNotifierProvider(create: (context) => AnnouncementProvider()),
        ChangeNotifierProvider(create: (context) => ReportProvider()),
        ChangeNotifierProvider(create: (context) => EmergencyProvider()),
        ChangeNotifierProxyProvider<AuthProvider, BillProvider>(
          create: (context) => BillProvider(baseUrl: '', token: ''),
          update: (context, authProvider, billProvider) {
            final token = authProvider.token;
            return BillProvider(
              baseUrl: 'https://wargakita.canadev.my.id',
              token: token ?? '',
            );
          },
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
          '/': (context) {
            final authProvider = Provider.of<AuthProvider>(context);
            // Check if user is authenticated
            if (authProvider.isAuthenticated) {
              // Redirect based on role
              final user = authProvider.user;
              // SATPAM diarahkan ke Security Dashboard
              if (user?.role == 'SECURITY' || user?.originalRole == 'SATPAM') {
                return SecurityDashboard();
              } else {
                return AdminDashboardScreen(token: '',);
              }
            } else {
              return LoginScreen();
            }
          },
          '/login': (context) => LoginScreen(),
          '/users': (context) => UsersScreen(),
          '/announcements': (context) => AnnouncementsScreen(),
          '/emergencies': (context) => EmergenciesScreen(),
          '/volunteers': (context) => VolunteersScreen(),
          '/reports': (context) => ReportsScreen(),
          '/bills': (context) => BillManagementScreen(token: '',),
          '/user-detail': (context) {
            final user = ModalRoute.of(context)!.settings.arguments as User;
            return UserDetailScreen(userId: user.id);
          },
          '/security-dashboard': (context) => SecurityDashboard(),
        },
      ),
    );
  }
}
