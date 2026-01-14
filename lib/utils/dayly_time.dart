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

