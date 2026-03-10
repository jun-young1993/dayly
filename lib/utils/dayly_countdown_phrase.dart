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
      return dayDiff >= 0 ? '$days days left' : '$days days ago';
    case DaylyCountdownMode.dMinus:
      // dayDiff = (target - now).inDays
      // - dayDiff > 0  : target is in the future
      // - dayDiff == 0 : today is D-Day
      // - dayDiff < 0  : target already passed
      if (dayDiff == 0) return 'D-Day';
      return dayDiff > 0 ? 'D-$days' : 'D+$days';
    case DaylyCountdownMode.weeksDays:
      final weeks = days ~/ 7;
      final remainderDays = days % 7;
      if (weeks <= 0) return '$days days';
      if (remainderDays == 0) return '$weeks weeks';
      return '$weeks weeks $remainderDays days';
    case DaylyCountdownMode.mornings:
      return '$days mornings';
    case DaylyCountdownMode.nights:
      return '$days nights';
    case DaylyCountdownMode.hidden:
      return '';
  }
}

