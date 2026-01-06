import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import 'settings_service.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  AudioPlayer? _audioPlayer;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _audioPlayer = AudioPlayer();
    _isInitialized = true;
  }

  Future<void> _playSoundWeb(String fileName) async {
    try {
      final audio = html.AudioElement('assets/sounds/$fileName');
      audio.play();
    } catch (e) {
      if (kDebugMode) {
        print('Error playing web sound $fileName: $e');
      }
    }
  }

  Future<void> _playSoundMobile(String fileName) async {
    if (!_isInitialized) await initialize();
    try {
      await _audioPlayer!.play(AssetSource('assets/sounds/$fileName'));
    } catch (e) {
      if (kDebugMode) {
        print('Error playing mobile sound $fileName: $e');
      }
    }
  }

  Future<void> playGameStart() async {
    if (!SettingsService.soundsEnabled) return;
    
    if (kIsWeb) {
      await _playSoundWeb('game-start.mp3');
    } else {
      await _playSoundMobile('game-start.mp3');
    }
  }

  Future<void> playGameOver() async {
    if (!SettingsService.soundsEnabled) return;
    
    if (kIsWeb) {
      await _playSoundWeb('game-over.mp3');
    } else {
      await _playSoundMobile('game-over.mp3');
    }
  }

  Future<void> playCorrect() async {
    if (!SettingsService.soundsEnabled) return;
    
    if (kIsWeb) {
      await _playSoundWeb('correct.mp3');
    } else {
      await _playSoundMobile('correct.mp3');
    }
  }

  Future<void> playError() async {
    if (!SettingsService.soundsEnabled) return;
    
    if (kIsWeb) {
      await _playSoundWeb('error.mp3');
    } else {
      await _playSoundMobile('error.mp3');
    }
  }

  void dispose() {
    _audioPlayer?.dispose();
    _isInitialized = false;
  }
}
