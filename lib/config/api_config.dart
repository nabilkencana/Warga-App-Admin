// config/api_config.dart
class ApiConfig {
  // Ganti dengan base URL backend Anda
  static const String baseUrl = 'https://wargakita.canadev.my.id';

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
