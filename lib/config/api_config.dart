// config/api_config.dart
class ApiConfig {
  // Ganti dengan base URL backend Anda
  static const String baseUrl = 'https://wargakita.canadev.my.id';

  // WebSocket URL untuk real-time notifications
  static const String webSocketUrl = 'wss://wargakita.canadev.my.id';

  // Timeout untuk API requests (dalam detik)
  static const int apiTimeout = 30;

  // App version
  static const String appVersion = '1.0.0';

  // Default user role untuk admin app
  static const List<String> allowedRoles = [
    'ADMIN',
    'SUPER_ADMIN',
    'SECURITY',
    'SATPAM',
  ];

  // Pagination settings
  static const int defaultPageSize = 20;
  static const int announcementsPerPage = 10;

  // Date format
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';

  // Notification settings
  static const int notificationPollingInterval = 30; // detik
  static const int maxNotifications = 50;

  // Debug mode
  static const bool debugMode = true;

  // Endpoints
  static const String securityDashboard = '/security/dashboard';
  static const String checkIn = '/security/check-in';
  static const String checkOut = '/security/check-out';
  static const String updateLocation = '/security/update-location';
  static const String startPatrol = '/security/patrol/start';
  static const String endPatrol = '/security/patrol/end';
  static const String reportIncident = '/security/incident/report';
  static const String acceptEmergency = '/security/emergency/accept';
  static const String securityLogs = '/security/logs';
}
