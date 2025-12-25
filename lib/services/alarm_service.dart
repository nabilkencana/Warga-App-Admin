import 'package:audioplayers/audioplayers.dart';

class AlarmService {
  static final AudioPlayer _player = AudioPlayer();
  static bool _playing = false;

  static Future<void> play() async {
    if (_playing) return;

    _playing = true;
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(1.0);
    await _player.play(AssetSource('sounds/emergency_alarm.mp3'));

    print('🔊 Alarm playing');
  }

  static Future<void> stop() async {
    _playing = false;
    await _player.stop();
    print('🔇 Alarm stopped');
  }
}
