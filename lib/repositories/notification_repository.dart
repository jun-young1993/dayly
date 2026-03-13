import 'package:dayly/models/dayly_widget_model.dart';
import 'package:dayly/services/notification_scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// D-Day 알림 예약/취소의 단일 진입점.
///
/// 저장소: Hive Box<dynamic> — TypeAdapter 없이 List<int>를 직접 저장.
///   key   = widgetId (String)
///   value = 예약된 알림 ID 목록 (List<int>)
///
/// 설계 원칙:
///   schedule() → 기존 알림 취소(cancel) 먼저 → 재예약 → Hive 저장.
///   이 순서를 반드시 지켜야 좀비 알림 (취소 안 된 중복 알림)이 생기지 않는다.
class NotificationRepository {
  NotificationRepository._();

  static final NotificationRepository instance = NotificationRepository._();

  static const _boxName = 'dayly_notif_v1';

  late final Box<dynamic> _box;
  late final NotificationScheduler _scheduler;
  late final FlutterLocalNotificationsPlugin _plugin;

  bool _initialized = false;
  String _languageCode = 'ko';

  Future<void> init(FlutterLocalNotificationsPlugin plugin) async {
    if (_initialized) return;
    _plugin = plugin;
    _scheduler = NotificationScheduler(plugin);
    _box = await Hive.openBox<dynamic>(_boxName);
    _initialized = true;
  }

  // ── 공개 API ─────────────────────────────────────────────────

  /// 위젯 생성/수정 시 호출.
  /// 기존 알림을 취소하고 새로 예약한다.
  Future<void> schedule(DaylyWidgetModel model, {String languageCode = 'ko'}) async {
    _assertInit();
    _languageCode = languageCode;
    // 1. 기존 알림 취소 (수정 케이스 대응)
    await _cancelStored(model.id);

    // 2. 새 알림 예약
    final ids = await _scheduler.scheduleAll(model, languageCode: languageCode);

    // 3. Hive 저장 (예약된 ID만 기록 — 이미 지난 트리거는 포함 안 됨)
    await _box.put(model.id, ids);

    debugPrint('[notif] schedule ${model.id}: ${ids.length}개 예약됨 $ids');
  }

  /// 위젯 삭제 시 호출.
  Future<void> cancel(String widgetId) async {
    _assertInit();
    await _cancelStored(widgetId);
    await _box.delete(widgetId);
    debugPrint('[notif] cancel $widgetId');
  }

  /// 앱 시작 시 pending 알림과 Hive 상태를 동기화.
  ///
  /// Android 재부팅 후 AlarmManager 알람이 모두 초기화되므로
  /// 앱 진입 시마다 pending 목록을 확인하고 누락된 알림을 복원한다.
  Future<void> syncOnAppStart(List<DaylyWidgetModel> widgets) async {
    _assertInit();

    final pending = await _plugin.pendingNotificationRequests();
    final pendingIds = pending.map((r) => r.id).toSet();

    int rescheduled = 0;
    for (final widget in widgets) {
      final stored = _storedIds(widget.id);

      // 저장된 알림 ID 중 실제로 pending 상태인 게 하나도 없으면 재예약
      final hasLiveNotification =
          stored.isNotEmpty && stored.any(pendingIds.contains);

      if (!hasLiveNotification) {
        final ids = await _scheduler.scheduleAll(widget, languageCode: _languageCode);
        await _box.put(widget.id, ids);
        rescheduled++;
      }
    }

    debugPrint('[notif] syncOnAppStart: ${widgets.length}개 위젯, $rescheduled개 재예약');
  }

  // ── 내부 헬퍼 ────────────────────────────────────────────────

  Future<void> _cancelStored(String widgetId) async {
    final ids = _storedIds(widgetId);
    await _scheduler.cancelAll(ids);
  }

  /// Hive에서 저장된 알림 ID를 안전하게 꺼낸다.
  /// Hive는 List<dynamic>으로 저장하므로 int로 캐스팅한다.
  List<int> _storedIds(String widgetId) {
    final raw = _box.get(widgetId);
    if (raw is! List) return const [];
    return raw.whereType<int>().toList();
  }

  void _assertInit() {
    assert(_initialized, 'NotificationRepository.init()을 먼저 호출하세요.');
  }
}
