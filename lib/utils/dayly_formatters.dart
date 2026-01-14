import 'package:intl/intl.dart';

/// Formats a date like "2026.02.14 (토)".
///
/// Rule: date is secondary meta info and must not visually compete.
String formatKoreanDotDate(DateTime date) {
  final local = date.toLocal();
  final dayPart = DateFormat('yyyy.MM.dd').format(local);
  final weekdayKorean = _weekdayKorean(local.weekday);
  return '$dayPart ($weekdayKorean)';
}

String _weekdayKorean(int weekday) {
  // DateTime.weekday: Mon=1 ... Sun=7
  switch (weekday) {
    case DateTime.monday:
      return '월';
    case DateTime.tuesday:
      return '화';
    case DateTime.wednesday:
      return '수';
    case DateTime.thursday:
      return '목';
    case DateTime.friday:
      return '금';
    case DateTime.saturday:
      return '토';
    case DateTime.sunday:
      return '일';
    default:
      return '';
  }
}

