import 'package:flutter_test/flutter_test.dart';
import 'package:rebudget/core/models/ledger_models.dart';

void main() {
  group('money storage', () {
    test('parses decimal CNY amounts as integer fen', () {
      expect(parseFen('28.5'), 2850);
      expect(parseFen('0.01'), 1);
      expect(parseFen('28.567'), isNull);
      expect(parseFen('-1'), isNull);
    });

    test('formats integer fen without floating point artefacts', () {
      expect(formatFen(2850), '¥28.50');
      expect(formatFen(1), '¥0.01');
    });
  });

  test('business dates use a stable local calendar key', () {
    expect(dateKey(DateTime(2026, 7, 3)), '2026-07-03');
  });

  group('analytics ranges', () {
    test('week starts on Monday and ends before next Monday', () {
      final range = analyticsRange(AnalyticsPeriod.week, DateTime(2026, 7, 23));
      expect(dateKey(range.start), '2026-07-20');
      expect(dateKey(range.end!), '2026-07-27');
    });

    test('month and year use exclusive next boundaries', () {
      final month = analyticsRange(AnalyticsPeriod.month, DateTime(2026, 7, 23));
      final year = analyticsRange(AnalyticsPeriod.year, DateTime(2026, 7, 23));
      expect(dateKey(month.start), '2026-07-01');
      expect(dateKey(month.end!), '2026-08-01');
      expect(dateKey(year.start), '2026-01-01');
      expect(dateKey(year.end!), '2027-01-01');
    });
  });
}
