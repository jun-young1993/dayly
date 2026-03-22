import 'package:dayly/models/dayly_widget_model.dart';
import 'package:dayly/storage/dayly_widget_storage.dart';
import 'package:dayly/utils/dayly_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('advanceRecurringOnce — annual', () {
    test('normal: 2025-01-15 → 2026-01-15', () {
      final result = advanceRecurringOnce(
        DateTime(2025, 1, 15),
        DaylyRecurringType.annual,
      );
      expect(result, DateTime(2026, 1, 15));
    });

    test('leap → non-leap: 2024-02-29 → 2025-02-28', () {
      final result = advanceRecurringOnce(
        DateTime(2024, 2, 29),
        DaylyRecurringType.annual,
      );
      expect(result, DateTime(2025, 2, 28));
    });
  });

  group('advanceRecurringOnce — monthly', () {
    test('normal: 2025-01-15 → 2025-02-15', () {
      final result = advanceRecurringOnce(
        DateTime(2025, 1, 15),
        DaylyRecurringType.monthly,
      );
      expect(result, DateTime(2025, 2, 15));
    });

    test('last day clamp: 2025-01-31 → 2025-02-28', () {
      final result = advanceRecurringOnce(
        DateTime(2025, 1, 31),
        DaylyRecurringType.monthly,
      );
      expect(result, DateTime(2025, 2, 28));
    });

    test('Feb→Mar: 2025-02-28 → 2025-03-28', () {
      final result = advanceRecurringOnce(
        DateTime(2025, 2, 28),
        DaylyRecurringType.monthly,
      );
      expect(result, DateTime(2025, 3, 28));
    });

    test('Dec→Jan year roll: 2025-12-15 → 2026-01-15', () {
      final result = advanceRecurringOnce(
        DateTime(2025, 12, 15),
        DaylyRecurringType.monthly,
      );
      expect(result, DateTime(2026, 1, 15));
    });
  });

  group('advanceIfPast', () {
    test('multi-cycle: 2023-01-15 annual → 2027-01-15 (today=2026-03-22)', () {
      final result = advanceIfPast(
        DateTime(2023, 1, 15),
        DaylyRecurringType.annual,
        today: DateTime(2026, 3, 22),
      );
      expect(result, DateTime(2027, 1, 15));
    });

    test('already future: unchanged (today=2026-03-22)', () {
      final future = DateTime(2027, 1, 15);
      final result = advanceIfPast(
        future,
        DaylyRecurringType.annual,
        today: DateTime(2026, 3, 22),
      );
      expect(result, future);
    });
  });

  group('advanceRecurringAll', () {
    DaylyWidgetModel _makeWidget({
      bool isRecurring = false,
      DaylyRecurringType? recurringType,
      required DateTime targetDate,
    }) {
      return DaylyWidgetModel(
        id: 'test-id',
        primarySentence: 'test',
        targetDate: targetDate,
        style: const DaylyWidgetStyle.defaults(),
        createdAt: DateTime(2025, 1, 1),
        isRecurring: isRecurring,
        recurringType: recurringType,
      );
    }

    test('mixed: recurring advances, non-recurring unchanged, anyChanged=true',
        () {
      final today = DateTime(2026, 3, 22);
      final recurring = _makeWidget(
        isRecurring: true,
        recurringType: DaylyRecurringType.annual,
        targetDate: DateTime(2025, 1, 15),
      );
      final nonRecurring = _makeWidget(
        targetDate: DateTime(2025, 6, 10),
      );

      final (:widgets, :anyChanged) =
          advanceRecurringAll([recurring, nonRecurring]);

      expect(anyChanged, isTrue);
      // recurring widget advanced to future
      expect(widgets[0].targetDate.isAfter(today), isTrue);
      // non-recurring widget unchanged
      expect(widgets[1].targetDate, DateTime(2025, 6, 10));
    });

    test('none recurring: anyChanged=false', () {
      final w1 = _makeWidget(targetDate: DateTime(2025, 3, 1));
      final w2 = _makeWidget(targetDate: DateTime(2025, 6, 1));

      final (:widgets, :anyChanged) = advanceRecurringAll([w1, w2]);

      expect(anyChanged, isFalse);
      expect(widgets[0].targetDate, DateTime(2025, 3, 1));
      expect(widgets[1].targetDate, DateTime(2025, 6, 1));
    });
  });

  group('DaylyWidgetModel.fromJson backward compat', () {
    test('isRecurring 필드 없는 구버전 JSON → isRecurring=false, recurringType=null',
        () {
      final json = <String, Object?>{
        'id': 'old-id',
        'primarySentence': 'old event',
        'targetDate': '2025-01-15T00:00:00.000',
        'createdAt': '2024-01-01T00:00:00.000',
        'style': {
          'themePreset': 'night',
          'background': {'type': 'solid', 'solidColor': 0xFF111827},
          'numberFormat': 'daysSuffix',
          'countdownMode': 'days',
          'showDivider': true,
          'isWatermarkEnabled': true,
          'isPremium': false,
        },
        'note': '',
        'milestones': <dynamic>[],
        // isRecurring and recurringType intentionally absent
      };

      final model = DaylyWidgetModel.fromJson(json);

      expect(model.isRecurring, isFalse);
      expect(model.recurringType, isNull);
    });
  });
}
