import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storypilot/data/services/usage_limit_service.dart';

void main() {
  late SharedPreferences prefs;
  late UsageLimitService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    service = UsageLimitService(prefs);
  });

  test('allows up to 3 anonymous questions per day', () {
    expect(service.canAskAnonymously(), isTrue);
    expect(service.remainingQuestions(), 3);

    service.recordAnonymousQuestion();
    expect(service.remainingQuestions(), 2);
    expect(service.canAskAnonymously(), isTrue);

    service.recordAnonymousQuestion();
    service.recordAnonymousQuestion();
    expect(service.remainingQuestions(), 0);
    expect(service.canAskAnonymously(), isFalse);
  });

  test('resets count on a new day', () {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final month = yesterday.month.toString().padLeft(2, '0');
    final day = yesterday.day.toString().padLeft(2, '0');
    final dateKey = '${yesterday.year}-$month-$day';

    prefs
      ..setString('anonymous_ask_date', dateKey)
      ..setInt('anonymous_ask_count', 3);

    expect(service.canAskAnonymously(), isTrue);
    expect(service.remainingQuestions(), 3);
  });
}
