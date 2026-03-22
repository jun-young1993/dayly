import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// dayly 핵심 이벤트 애널리틱스.
///
/// BIZ-1: 4주간 데이터 수집 후 IAP 도입 타이밍 판단 기준으로 활용.
/// - first_widget_created: 첫 위젯 생성 시
/// - share_tapped: 공유 버튼 탭 시
/// - home_widget_installed: 홈 화면 위젯 설치 완료 시
/// - premium_tapped: 프리미엄 기능 관련 UI 탭 시 (BIZ-6 이후 활성화)
class DaylyAnalytics {
  DaylyAnalytics._();
  static final _analytics = FirebaseAnalytics.instance;

  /// 앱 최초 설치 후 첫 위젯 생성 시 호출.
  static Future<void> logFirstWidgetCreated() async {
    try {
      await _analytics.logEvent(name: 'first_widget_created');
    } catch (e) {
      debugPrint('[DaylyAnalytics] first_widget_created: $e');
    }
  }

  /// 공유 버튼을 탭했을 때 호출.
  static Future<void> logShareTapped() async {
    try {
      await _analytics.logEvent(name: 'share_tapped');
    } catch (e) {
      debugPrint('[DaylyAnalytics] share_tapped: $e');
    }
  }

  /// 홈 화면 위젯 설치가 완료됐을 때 호출.
  static Future<void> logHomeWidgetInstalled() async {
    try {
      await _analytics.logEvent(name: 'home_widget_installed');
    } catch (e) {
      debugPrint('[DaylyAnalytics] home_widget_installed: $e');
    }
  }

  /// 프리미엄 관련 UI를 탭했을 때 호출 (BIZ-6 이후 활성화 예정).
  static Future<void> logPremiumTapped() async {
    try {
      await _analytics.logEvent(name: 'premium_tapped');
    } catch (e) {
      debugPrint('[DaylyAnalytics] premium_tapped: $e');
    }
  }
}
