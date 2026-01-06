import 'dart:html' as html;

class SettingsService {
  static const String _compactModeKey = 'compact_mode_enabled';
  static const String _soundsEnabledKey = 'sounds_enabled';
  
  static bool _isCompactMode = false;
  static bool _soundsEnabled = true; // Default to enabled
  
  static bool get isCompactMode => _isCompactMode;
  static bool get soundsEnabled => _soundsEnabled;
  
  static Future<void> loadSettings() async {
    try {
      final compactStored = html.window.localStorage[_compactModeKey];
      _isCompactMode = compactStored == 'true';
      
      final soundsStored = html.window.localStorage[_soundsEnabledKey];
      _soundsEnabled = soundsStored != 'false'; // Default to true
    } catch (e) {
      _isCompactMode = false;
      _soundsEnabled = true;
    }
  }
  
  static Future<void> setCompactMode(bool enabled) async {
    try {
      _isCompactMode = enabled;
      html.window.localStorage[_compactModeKey] = enabled.toString();
    } catch (e) {
      // Fallback: just update the in-memory value
      _isCompactMode = enabled;
    }
  }
  
  static Future<void> setSoundsEnabled(bool enabled) async {
    try {
      _soundsEnabled = enabled;
      html.window.localStorage[_soundsEnabledKey] = enabled.toString();
    } catch (e) {
      // Fallback: just update the in-memory value
      _soundsEnabled = enabled;
    }
  }
  
  static void toggleSoundsEnabled() {
    setSoundsEnabled(!_soundsEnabled);
  }
  
  static void toggleCompactMode() {
    setCompactMode(!_isCompactMode);
  }
}
