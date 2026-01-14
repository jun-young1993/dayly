import 'package:dayly/models/dayly_widget_model.dart';

/// Returns a human-friendly "time sense" phrase for the widget sentence.
///
/// Examples:
/// - days -> "23일"
/// - weeksDays -> "3주 2일"
/// - mornings -> "42번의 아침"
/// - nights -> "42번의 밤"
/// - hidden -> "" (caller decides how to render)
String buildCountdownPhrase({
  required DaylyCountdownMode mode,
  required int dayDiff,
}) {
  final days = dayDiff.abs();
  switch (mode) {
    case DaylyCountdownMode.days:
      return '$days일';
    case DaylyCountdownMode.dMinus:
      // Rule-friendly: keep "D-23" (no D+).
      // Request: future/upcoming => D- , past/after => D+
      // dayDiff = (target - now).inDays
      // - dayDiff >= 0 : target is today or in the future
      // - dayDiff < 0  : target already passed
      return dayDiff >= 0 ? 'D-$days' : 'D+$days';
    case DaylyCountdownMode.weeksDays:
      final weeks = days ~/ 7;
      final remainderDays = days % 7;
      if (weeks <= 0) return '$days일';
      if (remainderDays == 0) return '$weeks주';
      return '$weeks주 $remainderDays일';
    case DaylyCountdownMode.mornings:
      return '$days번의 아침';
    case DaylyCountdownMode.nights:
      return '$days번의 밤';
    case DaylyCountdownMode.hidden:
      return '';
  }
}

