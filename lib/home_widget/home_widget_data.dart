import 'dart:convert';

/// 홈화면 위젯에 전달되는 경량 데이터 구조체.
///
/// [DaylyWidgetModel]의 네이티브 레이어 전용 직렬화 형태.
/// 네이티브(Android Kotlin / iOS Swift)에서 동일 키로 읽어 사용한다.
class HomeWidgetData {
  const HomeWidgetData({
    required this.id,
    required this.sentence,
    required this.daysCount,
    required this.countdownText,
    required this.targetDateLabel,
    required this.themePreset,
    required this.isPast,
  });

  /// 앱 내 DaylyWidgetModel.id 와 동일
  final String id;

  /// 위젯에 표시할 문구 (primarySentence)
  final String sentence;

  /// D-Day 숫자 (절대값). isPast=true 이면 지난 날.
  final int daysCount;

  /// 실제 표시 텍스트 (예: "D-3", "23일", "3주 2일")
  final String countdownText;

  /// 날짜 레이블 (예: "2026.06.01")
  final String targetDateLabel;

  /// 테마 프리셋 이름 (night | paper | fog | lavender | blush)
  final String themePreset;

  /// D-Day가 이미 지났으면 true
  final bool isPast;

  Map<String, dynamic> toJson() => {
        'id': id,
        'sentence': sentence,
        'daysCount': daysCount,
        'countdownText': countdownText,
        'targetDateLabel': targetDateLabel,
        'themePreset': themePreset,
        'isPast': isPast,
      };

  String toJsonString() => jsonEncode(toJson());

  static HomeWidgetData fromJson(Map<String, dynamic> json) => HomeWidgetData(
        id: (json['id'] as String?) ?? '',
        sentence: (json['sentence'] as String?) ?? '',
        daysCount: (json['daysCount'] as int?) ?? 0,
        countdownText: (json['countdownText'] as String?) ?? '',
        targetDateLabel: (json['targetDateLabel'] as String?) ?? '',
        themePreset: (json['themePreset'] as String?) ?? 'night',
        isPast: (json['isPast'] as bool?) ?? false,
      );

  static HomeWidgetData? fromJsonString(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return fromJson(map);
    } catch (_) {
      return null;
    }
  }
}
