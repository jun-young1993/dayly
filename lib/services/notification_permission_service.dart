import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Android 13+ / iOS 권한 요청 서비스.
///
/// Android 권한 체계:
///   - POST_NOTIFICATIONS (API 33+): 알림 표시
///   - SCHEDULE_EXACT_ALARM  (API 31+): 정확한 시각 알람
///     → 이 권한이 없으면 zonedSchedule이 silently fail.
///       실무 함정 1위: 앱 출시 후 "알림이 안 와요" 리뷰의 주원인.
class NotificationPermissionService {
  NotificationPermissionService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  /// 반환값: 알림 권한 허용 여부.
  /// false라도 schedule을 호출할 수 있지만 알림이 발송되지 않는다.
  Future<bool> request(BuildContext? context) async {
    if (Platform.isAndroid) {
      return _requestAndroid(context);
    } else if (Platform.isIOS) {
      return _requestIOS();
    }
    return true;
  }

  Future<bool> _requestAndroid(BuildContext? context) async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return false;

    // 1단계: POST_NOTIFICATIONS (Android 13+)
    // API 32 이하는 설치 시 자동 부여되므로 이 호출은 무시된다.
    final notifGranted =
        await androidPlugin.requestNotificationsPermission() ?? false;
    if (!notifGranted) return false;

    // 2단계: 정확한 알람 권한 (Android 12+)
    // USE_EXACT_ALARM(API 33, 알람 앱 전용) 또는
    // SCHEDULE_EXACT_ALARM(API 31+, 사용자 허용 필요) 중 하나라도 있으면 OK.
    final exactGranted =
        await androidPlugin.requestExactAlarmsPermission() ?? false;
    if (!exactGranted && context != null && context.mounted) {
      _showExactAlarmRationale(context);
    }

    return notifGranted;
  }

  Future<bool> _requestIOS() async {
    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final granted = await iosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        false;
    return granted;
  }

  void _showExactAlarmRationale(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('정확한 알림 시각을 위해'),
        content: const Text(
          '설정 > 앱 > dayly > 정확한 알람 허용을 켜면\n'
          'D-Day 알림이 정확한 시간에 도착합니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('나중에'),
          ),
        ],
      ),
    );
  }
}
