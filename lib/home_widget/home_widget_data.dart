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
    required this.targetDate,
    required this.countdownMode,
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

  /// 원본 목표 날짜 (yyyy-MM-dd). Android 네이티브에서 실시간 D-Day 계산용.
  final String targetDate;

  /// 카운트다운 표시 방식 (days | dMinus | weeksDays | mornings | nights | hidden)
  final String countdownMode;

  Map<String, dynamic> toJson() => {
        'id': id,
        'sentence': sentence,
        'daysCount': daysCount,
        'countdownText': countdownText,
        'targetDateLabel': targetDateLabel,
        'themePreset': themePreset,
        'isPast': isPast,
        'targetDate': targetDate,
        'countdownMode': countdownMode,
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
        targetDate: (json['targetDate'] as String?) ?? '',
        countdownMode: (json['countdownMode'] as String?) ?? 'dMinus',
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
