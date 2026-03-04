import 'package:dayly/models/dayly_widget_model.dart';
import 'package:dayly/services/notification_id_registry.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// D-Day 하나에 대해 zonedSchedule 알림을 예약하는 단순 서비스.
///
/// 트리거 포인트: D-7, D-3, D-1, D-Day (모두 오전 9시 로컬 기준).
/// 이미 지난 시각은 자동 스킵한다.
class NotificationScheduler {
  NotificationScheduler(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const _notifyHour = 9;
  static const _notifyMinute = 0;

  static const _androidDetails = AndroidNotificationDetails(
    'dayly_dday_channel',
    'D-Day 알림',
    channelDescription: '설정한 D-Day 날짜에 맞춰 알림을 보냅니다',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  static const _iosDetails = DarwinNotificationDetails(
    categoryIdentifier: 'DDAY_REMINDER',
  );

  static const _details = NotificationDetails(
    android: _androidDetails,
    iOS: _iosDetails,
  );

  /// (daysOffset, triggerIndex) 쌍 목록.
  ///
  /// triggerIndex는 [NotificationIdRegistry]의 상수와 매핑된다.
  static const _triggers = [
    (-7, NotificationIdRegistry.kDMinus7),
    (-3, NotificationIdRegistry.kDMinus3),
    (-1, NotificationIdRegistry.kDMinus1),
    (0, NotificationIdRegistry.kDDay),
  ];

  /// [model]에 대한 모든 알림을 예약하고,
  /// 실제 예약된 알림 ID 목록을 반환한다.
  ///
  /// 이미 지난 시각의 알림은 예약하지 않으므로 반환 리스트 길이는 0~4.
  Future<List<int>> scheduleAll(DaylyWidgetModel model) async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduled = <int>[];

    for (final (daysOffset, triggerIndex) in _triggers) {
      final notifDate = model.targetDate.add(Duration(days: daysOffset));
      final scheduledAt = tz.TZDateTime(
        tz.local,
        notifDate.year,
        notifDate.month,
        notifDate.day,
        _notifyHour,
        _notifyMinute,
      );

      // 1분 이상 미래인 경우에만 예약 (이미 지난 알림 스킵)
      if (!scheduledAt.isAfter(now.add(const Duration(minutes: 1)))) continue;

      final id = NotificationIdRegistry.compute(model.id, triggerIndex);
      final body = _buildBody(model.primarySentence, daysOffset);

      // androidScheduleMode: exactAllowWhileIdle
      // → AlarmManager.setExactAndAllowWhileIdle() 사용.
      // Doze 모드(화면 꺼짐 + 충전 중 아님)를 뚫고 정확한 시각에 발송.
      // 일반 setExact()는 Doze에서 배치 처리되어 수 시간 지연 가능.
      await _plugin.zonedSchedule(
        id,
        model.primarySentence,
        body,
        scheduledAt,
        _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        // iOS 구버전 호환 파라미터 (v17에서 required).
        // absoluteTime: 절대 시각 기준 — D-Day 앱에는 항상 이 옵션.
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: model.id, // 탭 시 해당 위젯으로 딥링크용
      );

      scheduled.add(id);
    }

    return scheduled;
  }

  /// 특정 알림 ID 목록을 모두 취소한다.
  Future<void> cancelAll(List<int> ids) async {
    for (final id in ids) {
      await _plugin.cancel(id);
    }
  }

  String _buildBody(String title, int daysOffset) {
    return switch (daysOffset) {
      0  => '오늘이 바로 $title입니다 ✨',
      -1 => '내일이 $title입니다',
      -3 => '3일 후 $title입니다',
      -7 => '7일 후 $title입니다',
      _  => '$title이 다가오고 있습니다',
    };
  }
}
