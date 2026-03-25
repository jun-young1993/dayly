/// Returns the day difference (target - now) in whole days.
///
/// - Future target => positive
/// - Past target => negative
///
/// We normalize to local date boundaries so the value is stable throughout the day.
int calculateDayDifference({required DateTime now, required DateTime target}) {
  final nowLocal = now.toLocal();
  final targetLocal = target.toLocal();
  final normalizedNow = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
  final normalizedTarget =
      DateTime(targetLocal.year, targetLocal.month, targetLocal.day);
  return normalizedTarget.difference(normalizedNow).inDays;
}

// ──────────────────────────────────────────────────────────────
// 반복 이벤트 (BIZ-4)
// ──────────────────────────────────────────────────────────────

/// 반복 주기 타입.
enum DaylyRecurringType { annual, monthly }

DateTime _toDate(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

bool _isLeapYear(int year) =>
    (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);

/// targetDate를 한 사이클 진행한다.
///
/// - annual: 같은 월/일, 다음 해 (Feb 29 + 비윤년 → Feb 28)
/// - monthly: 같은 일, 다음 달 (단월 클램프: Jan 31 → Feb 28/29)
DateTime advanceRecurringOnce(DateTime date, DaylyRecurringType type) {
  if (type == DaylyRecurringType.annual) {
    final nextYear = date.year + 1;
    final targetDay = (date.month == 2 && date.day == 29 && !_isLeapYear(nextYear))
        ? 28
        : date.day;
    return DateTime(nextYear, date.month, targetDay);
  } else {
    final nextMonth = date.month == 12 ? 1 : date.month + 1;
    final nextYear = date.month == 12 ? date.year + 1 : date.year;
    // DateTime(y, m+1, 0).day = 해당 월의 마지막 날
    final lastDayOfNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
    final targetDay = date.day.clamp(1, lastDayOfNextMonth);
    return DateTime(nextYear, nextMonth, targetDay);
  }
}

/// targetDate가 오늘(today)보다 과거면 미래가 될 때까지 반복 진행한다.
///
/// [today]를 주입하면 테스트에서 결정론적으로 실행할 수 있다.
/// guard=1200: 100년치 monthly도 커버, 무한루프 방지.
DateTime advanceIfPast(
  DateTime targetDate,
  DaylyRecurringType type, {
  DateTime? today,
}) {
  final todayNorm = _toDate(today ?? DateTime.now());
  var result = targetDate;
  var guard = 0;
  while (result.isBefore(todayNorm) && guard < 1200) {
    result = advanceRecurringOnce(result, type);
    guard++;
  }
  return result;
}

// ──────────────────────────────────────────────────────────────
// DaylyRecurringType 레이블 (T1/T2 — 순수 함수, 테스트 가능)
// ──────────────────────────────────────────────────────────────

/// `DaylyRecurringType?` 값을 언어 코드에 맞는 표시 문자열로 변환.
///
/// null = "없음 / None / なし", annual = "매년 / Yearly / 毎年",
/// monthly = "매월 / Monthly / 毎月"
extension DaylyRecurringTypeX on DaylyRecurringType? {
  String label(String languageCode) => switch (this) {
        DaylyRecurringType.annual => switch (languageCode) {
            'ko' => '매년',
            'ja' => '毎年',
            _ => 'Yearly',
          },
        DaylyRecurringType.monthly => switch (languageCode) {
            'ko' => '매월',
            'ja' => '毎月',
            _ => 'Monthly',
          },
        null => switch (languageCode) {
            'ko' => '없음',
            'ja' => 'なし',
            _ => 'None',
          },
      };
}

