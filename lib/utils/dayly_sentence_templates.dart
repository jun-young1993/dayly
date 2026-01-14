import 'package:dayly/models/dayly_widget_model.dart';
import 'package:flutter/foundation.dart';
import 'package:dayly/utils/dayly_countdown_phrase.dart';

enum DaylyRelationshipType {
  couple,
  family,
  solo,
  goal,
}

enum DaylyTone {
  calm,
  flutter,
  longing,
  playful,
}

@immutable
class DaylyTemplateRequest {
  const DaylyTemplateRequest({
    required this.relationshipType,
    required this.tone,
    required this.eventLabel,
    required this.dayDiff,
    required this.countdownMode,
  });

  final DaylyRelationshipType relationshipType;
  final DaylyTone tone;

  /// Optional label like "결혼식", "입대", "전역", "시험", etc.
  final String eventLabel;

  final int dayDiff;
  final DaylyCountdownMode countdownMode;
}

/// Deterministic “AI-like” template generator (lightweight, offline).
///
/// Rule alignment:
/// - Sentence explains WHY it matters.
/// - Avoid calendar/tool wording.
/// - Number never leads the sentence.
String generateDaylySentence(DaylyTemplateRequest request) {
  final phrase = buildCountdownPhrase(
    mode: request.countdownMode,
    dayDiff: request.dayDiff,
  );

  final event = request.eventLabel.trim().isEmpty ? '그날' : request.eventLabel.trim();

  switch (request.relationshipType) {
    case DaylyRelationshipType.couple:
      return _coupleTone(request.tone, phrase, event);
    case DaylyRelationshipType.family:
      return _familyTone(request.tone, phrase, event);
    case DaylyRelationshipType.solo:
      return _soloTone(request.tone, phrase, event);
    case DaylyRelationshipType.goal:
      return _goalTone(request.tone, phrase, event);
  }
}

String _coupleTone(DaylyTone tone, String phrase, String event) {
  switch (tone) {
    case DaylyTone.calm:
      return '우리는 다시 만날 때까지 $phrase';
    case DaylyTone.flutter:
      return '$event까지 $phrase, 설레는 마음으로';
    case DaylyTone.longing:
      return '그리운 너에게 닿기까지 $phrase';
    case DaylyTone.playful:
      return '$event까지 $phrase… 참을 수 있겠어?';
  }
}

String _familyTone(DaylyTone tone, String phrase, String event) {
  switch (tone) {
    case DaylyTone.calm:
      return '우리의 $event까지 $phrase';
    case DaylyTone.flutter:
      return '함께 웃을 $event까지 $phrase';
    case DaylyTone.longing:
      return '보고 싶은 얼굴을 만나기까지 $phrase';
    case DaylyTone.playful:
      return '$event까지 $phrase! 우리 준비됐지?';
  }
}

String _soloTone(DaylyTone tone, String phrase, String event) {
  switch (tone) {
    case DaylyTone.calm:
      return '나를 위한 $event까지 $phrase';
    case DaylyTone.flutter:
      return '$event까지 $phrase, 나에게 기대를';
    case DaylyTone.longing:
      return '조금 더 단단해질 때까지 $phrase';
    case DaylyTone.playful:
      return '$event까지 $phrase—오늘도 한 발!';
  }
}

String _goalTone(DaylyTone tone, String phrase, String event) {
  switch (tone) {
    case DaylyTone.calm:
      return '$event까지 $phrase, 차분하게';
    case DaylyTone.flutter:
      return '$event까지 $phrase, 가슴이 뛴다';
    case DaylyTone.longing:
      return '기다려온 $event까지 $phrase';
    case DaylyTone.playful:
      return '$event까지 $phrase. 웃으면서 가자';
  }
}

