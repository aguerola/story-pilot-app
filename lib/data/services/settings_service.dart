import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  SettingsService(this._prefs);

  final SharedPreferences _prefs;

  static const _subtitleLanguageKey = 'subtitle_language';

  String get subtitleLanguage =>
      _prefs.getString(_subtitleLanguageKey) ?? 'es';

  Future<void> setSubtitleLanguage(String language) async {
    await _prefs.setString(_subtitleLanguageKey, language);
  }
}
