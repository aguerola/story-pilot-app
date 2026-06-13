import 'package:shared_preferences/shared_preferences.dart';
import 'package:storypilot/config/gemini_model.dart';

class SettingsService {
  SettingsService(this._prefs);

  final SharedPreferences _prefs;

  static const _subtitleLanguageKey = 'subtitle_language';
  static const _geminiModelKey = 'gemini_model';

  String get subtitleLanguage =>
      _prefs.getString(_subtitleLanguageKey) ?? 'es';

  Future<void> setSubtitleLanguage(String language) async {
    await _prefs.setString(_subtitleLanguageKey, language);
  }

  GeminiModel get geminiModel =>
      GeminiModel.fromId(_prefs.getString(_geminiModelKey) ?? '');

  Future<void> setGeminiModel(GeminiModel model) async {
    await _prefs.setString(_geminiModelKey, model.id);
  }
}
