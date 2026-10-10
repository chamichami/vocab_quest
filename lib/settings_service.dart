import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  static const _kVolume = 'settings_volume';
  static const _kMusic = 'settings_music';
  static const _track = 'bgm.wav';

  final AudioPlayer _player = AudioPlayer();
  double _volume = 0.7;
  bool _musicOn = true;
  bool _foreground = true;

  double get volume => _volume;
  bool get musicOn => _musicOn;

  Future<void> init() async {
    _player.audioCache.prefix = 'lib/assets/audio/';
    try {
      final p = await SharedPreferences.getInstance();
      _volume = p.getDouble(_kVolume) ?? _volume;
      _musicOn = p.getBool(_kMusic) ?? _musicOn;
    } catch (_) {}
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
    } catch (_) {}
    _sync();
  }

  Future<void> setVolume(double v, {bool save = true}) async {
    _volume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _sync();
    if (save) {
      final p = await SharedPreferences.getInstance();
      await p.setDouble(_kVolume, _volume);
    }
  }

  Future<void> setMusicOn(bool on) async {
    _musicOn = on;
    notifyListeners();
    await _sync();
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kMusic, on);
  }

  void setForeground(bool foreground) {
    _foreground = foreground;
    _sync();
  }

  Future<void> _sync() async {
    try {
      await _player.setVolume(_volume);
      final shouldPlay = _musicOn && _volume > 0 && _foreground;
      if (shouldPlay) {
        if (_player.state == PlayerState.paused) {
          await _player.resume();
        } else if (_player.state != PlayerState.playing) {
          await _player.play(AssetSource(_track));
        }
      } else if (_player.state == PlayerState.playing) {
        await _player.pause();
      }
    } catch (e) {
      debugPrint('Audio unavailable: $e');
    }
  }
}
