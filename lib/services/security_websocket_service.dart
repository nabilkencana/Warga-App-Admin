import 'package:socket_io_client/socket_io_client.dart' as IO;

class SecurityWebSocketService {
  static const String baseUrl = 'https://wargakita.canadev.my.id/security';

  late IO.Socket socket;
  Function(Map<String, dynamic>)? onEmergencyAlarm;
  Function(Map<String, dynamic>)? onEmergencyDispatch;
  Function(Map<String, dynamic>)? onConnected;
  Function(String reason)? onDisconnected;
  Function(String error)? onError;



  void connect(int securityId) {

    socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setQuery({'securityId': securityId})
          .enableAutoConnect()
          .build(),
    );

    socket.onConnect((_) {
      print('🟢 Security socket connected');
    });

    socket.onDisconnect((_) {
      onDisconnected?.call('Connection closed');
    });


    socket.on('security_connected', (data) {
      onConnected?.call(data['data']);
    });

    socket.on('emergency_alarm', (data) {
      print('🚨 EMERGENCY ALARM RECEIVED');
      onEmergencyAlarm?.call(data['data']);
    });

    socket.on('emergency_dispatch', (data) {
      onEmergencyDispatch?.call(data['data']);
    });

    socket.onConnectError((err) {
      onError?.call(err.toString());
    });

    socket.onError((err) {
      onError?.call(err.toString());
    });

  }

  // === EMIT EVENTS ===

  void acceptEmergency(int emergencyId) {
    socket.emit('accept_emergency', {'emergencyId': emergencyId});
  }

  void arriveAtEmergency(int emergencyId) {
    socket.emit('arrive_at_emergency', {'emergencyId': emergencyId});
  }

  void completeEmergency(int emergencyId, String actionTaken, {String? notes}) {
    socket.emit('complete_emergency', {
      'emergencyId': emergencyId,
      'actionTaken': actionTaken,
      'notes': notes,
    });
  }

  void updateLocation(double lat, double lng) {
    socket.emit('update_location', {
      'latitude': lat.toString(),
      'longitude': lng.toString(),
    });
  }

  void testAlarm() {
    socket.emit('test_alarm');
  }

  void disconnect() {
    socket.disconnect();
  }
}
