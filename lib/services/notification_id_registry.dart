/// 알림 ID 결정론적 생성기.
///
/// [widgetId]와 [triggerIndex]로 항상 같은 int ID를 반환한다.
/// 장점: 재설치 후에도 동일 widgetId → 동일 알림 ID → cancel() 가능.
///
/// ID 구조 (32-bit signed int, 양수 보장):
///   상위 27bit = widgetId.hashCode.abs() & 0x07FFFFFF
///   하위  4bit = triggerIndex (0~3)
///   최대값 = 0x7FFFFFFF (2147483647) — flutter_local_notifications 32-bit 제한 준수.
///
/// 한 위젯당 최대 4개 알림 (D-7, D-3, D-1, D-Day).
/// 위젯 16개 × 4알림 = 64개 → Android AlarmManager 상한과 정확히 일치.
class NotificationIdRegistry {
  const NotificationIdRegistry._();

  // triggerIndex 상수 — NotificationScheduler.triggers 순서와 반드시 일치해야 한다.
  static const int kDMinus7 = 0;
  static const int kDMinus3 = 1;
  static const int kDMinus1 = 2;
  static const int kDDay = 3;

  static const int maxTriggers = 4;
  static const int maxWidgets = 16; // 64 / 4

  /// [widgetId] × [triggerIndex] → 고유 알림 ID.
  static int compute(String widgetId, int triggerIndex) {
    assert(triggerIndex >= 0 && triggerIndex < maxTriggers);
    final hash = widgetId.hashCode.abs() & 0x07FFFFFF;
    return (hash << 4) | (triggerIndex & 0xF);
  }

  /// 특정 위젯의 모든 알림 ID 목록 반환.
  static List<int> allFor(String widgetId) {
    return List.generate(maxTriggers, (i) => compute(widgetId, i));
  }
}
