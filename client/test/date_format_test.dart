import 'package:flutter_test/flutter_test.dart';
import 'package:yakkity/core/utils/date_format.dart';

void main() {
  test('dayLabel: today and yesterday', () {
    final now = DateTime.now();
    expect(dayLabel(now), 'Сегодня');
    expect(dayLabel(now.subtract(const Duration(days: 1))), 'Вчера');
  });

  test('dayLabel: older date has day and month', () {
    final label = dayLabel(DateTime(2020, 3, 5, 12));
    expect(label, '5 марта 2020');
  });

  test('isSameDay compares calendar days', () {
    expect(isSameDay(DateTime(2026, 11, 5, 1), DateTime(2026, 11, 5, 23)), isTrue);
    expect(isSameDay(DateTime(2026, 11, 5, 23), DateTime(2026, 11, 6, 1)), isFalse);
  });
}
