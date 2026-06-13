import 'package:shared_preferences/shared_preferences.dart';

class UsageLimitService {
  UsageLimitService(this._prefs);

  static const maxAnonymousQuestionsPerDay = 3;

  static const _dateKey = 'anonymous_ask_date';
  static const _countKey = 'anonymous_ask_count';

  final SharedPreferences _prefs;

  String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  void _ensureCurrentDay() {
    final today = _todayKey();
    if (_prefs.getString(_dateKey) != today) {
      _prefs
        ..setString(_dateKey, today)
        ..setInt(_countKey, 0);
    }
  }

  bool canAskAnonymously() {
    _ensureCurrentDay();
    return (_prefs.getInt(_countKey) ?? 0) < maxAnonymousQuestionsPerDay;
  }

  void recordAnonymousQuestion() {
    _ensureCurrentDay();
    final count = (_prefs.getInt(_countKey) ?? 0) + 1;
    _prefs.setInt(_countKey, count);
  }

  int remainingQuestions() {
    _ensureCurrentDay();
    final count = _prefs.getInt(_countKey) ?? 0;
    return maxAnonymousQuestionsPerDay - count;
  }
}
