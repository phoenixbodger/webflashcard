import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';

class EnhancedTTSService {
  static final EnhancedTTSService _instance = EnhancedTTSService._internal();
  factory EnhancedTTSService() => _instance;
  EnhancedTTSService._internal();

  FlutterTts? _flutterTts;
  AudioPlayer? _audioPlayer;
  bool _isInitialized = false;
  String _currentLanguage = 'en-US';
  bool _isSpeaking = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _flutterTts = FlutterTts();
    _audioPlayer = AudioPlayer();

    // Enhanced TTS settings for better quality
    await _flutterTts!.setLanguage('en-US');
    await _flutterTts!.setSpeechRate(0.90); // Slower for better quality
    await _flutterTts!.setVolume(1.0);
    await _flutterTts!.setPitch(1.0);
    await _flutterTts!.awaitSpeakCompletion(true);

    // Set up handlers to track speaking state
    _flutterTts!.setStartHandler(() {
      _isSpeaking = true;
    });

    _flutterTts!.setCompletionHandler(() {
      _isSpeaking = false;
    });

    _flutterTts!.setErrorHandler((msg) {
      _isSpeaking = false;
    });

    // Try to set better voices for different languages
    await _setOptimalVoices();

    _isInitialized = true;
  }

  Future<void> _setOptimalVoices() async {
    try {
      // Try different high-quality voices
      final voices = [
        {"name": "Karen", "locale": "en-US"},    // macOS
        {"name": "Samantha", "locale": "en-US"}, // iOS
        {"name": "Microsoft David", "locale": "en-US"}, // Windows
        {"name": "Google US English", "locale": "en-US"}, // Android
      ];

      for (final voice in voices) {
        try {
          await _flutterTts!.setVoice(voice);
          break; // Use first successful voice
        } catch (e) {
          continue; // Try next voice
        }
      }
    } catch (e) {
      // Fallback to default voice
    }
  }

  Future<String> _detectLanguage(String text) async {
    // Check for Chinese characters
    if (text.contains(RegExp(r'[\u4e00-\u9fff]'))) {
      return 'zh-CN';
    }
    
    // Check for Japanese characters
    if (text.contains(RegExp(r'[\u3040-\u309f\u30a0-\u30ff]')) || // Hiragana/Katakana
        text.contains(RegExp(r'[\u4e00-\u9fff]'))) { // Kanji
      return 'ja-JP';
    }
    
    // Check for Korean characters
    if (text.contains(RegExp(r'[\uac00-\ud7af]'))) { // Hangul
      return 'ko-KR';
    }
    
    // Check for Arabic characters
    if (text.contains(RegExp(r'[\u0600-\u06ff]'))) {
      return 'ar-SA';
    }
    
    // Check for Cyrillic characters (Russian)
    if (text.contains(RegExp(r'[\u0400-\u04ff]'))) {
      return 'ru-RU';
    }
    
    // Check for Thai characters
    if (text.contains(RegExp(r'[\u0e00-\u0e7f]'))) {
      return 'th-TH';
    }
    
    // Check for Hindi characters
    if (text.contains(RegExp(r'[\u0900-\u097f]'))) {
      return 'hi-IN';
    }
    
    // Check for Hebrew characters
    if (text.contains(RegExp(r'[\u0590-\u05ff]'))) {
      return 'he-IL';
    }
    
    // Default to English
    return 'en-US';
  }

  Future<void> setLanguage(String language) async {
    if (!_isInitialized) await initialize();
    try {
      await _flutterTts!.setLanguage(language);
      _currentLanguage = language;
    } catch (e) {
      // Fallback to default
      await _flutterTts!.setLanguage('en-US');
      _currentLanguage = 'en-US';
    }
  }

  Future<void> speakWithFlutterTTS(String text, {bool? useAutoDetect}) async {
    if (!_isInitialized) await initialize();
    
    try {
      // Only auto-detect if user hasn't manually set language
      final shouldAutoDetect = useAutoDetect ?? true;
      
      if (shouldAutoDetect) {
        // Auto-detect language
        final detectedLanguage = await _detectLanguage(text);
        
        // Switch to detected language if needed
        if (detectedLanguage != _currentLanguage) {
          await _flutterTts!.setLanguage(detectedLanguage);
          _currentLanguage = detectedLanguage;
        }
      } else {
        // Use manually set language - ensure it's set
        await _flutterTts!.setLanguage(_currentLanguage);
      }
      
      // Speak with enhanced quality
      await _flutterTts!.speak(text);
      
    } catch (e) {
      // Fallback to basic speech
      await _flutterTts!.speak(text);
    }
  }

  Future<void> speakWithWebAPI(String text, {bool? useAutoDetect}) async {
    // This would integrate with a web API like Kokoro or other high-quality TTS
    // For now, we'll use a placeholder implementation
    
    try {
      // Example: Call to a TTS API (this is a placeholder)
      // final response = await http.post(
      //   Uri.parse('https://api.tts-service.com/synthesize'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({
      //     'text': text,
      //     'language': _currentLanguage,
      //     'voice': 'premium-voice',
      //   }),
      // );
      
      // if (response.statusCode == 200) {
      //   // Play the audio response
      //   await _audioPlayer!.play(UrlSource('audio_url'));
      // }
      
      // For now, fallback to Flutter TTS with same auto-detect setting
      await speakWithFlutterTTS(text, useAutoDetect: useAutoDetect);
    } catch (e) {
      // Fallback to Flutter TTS
      await speakWithFlutterTTS(text, useAutoDetect: useAutoDetect);
    }
  }

  Future<void> speak(String text, {bool useHighQuality = true, bool useAutoDetect = true}) async {
    if (useHighQuality) {
      // Try high-quality options first
      await speakWithWebAPI(text, useAutoDetect: useAutoDetect);
    } else {
      // Use Flutter TTS directly
      await speakWithFlutterTTS(text, useAutoDetect: useAutoDetect);
    }
  }

  Future<void> stop() async {
    if (_flutterTts != null) {
      await _flutterTts!.stop();
    }
    if (_audioPlayer != null) {
      await _audioPlayer!.stop();
    }
  }

  Future<bool> isSpeaking() async {
    if (_flutterTts != null) {
      try {
        // FlutterTts doesn't have isSpeaking getter, so we'll track state manually
        return _isSpeaking;
      } catch (e) {
        return false;
      }
    }
    return false;
  }
  
  void setSpeakingState(bool isSpeaking) {
    _isSpeaking = isSpeaking;
  }
}
