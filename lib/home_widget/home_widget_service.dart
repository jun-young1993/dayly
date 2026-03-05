import 'dart:convert';

import 'package:dayly/home_widget/home_widget_config.dart';
import 'package:dayly/home_widget/home_widget_data.dart';
import 'package:dayly/models/dayly_widget_model.dart';
import 'package:dayly/utils/dayly_countdown_phrase.dart';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

/// iOS / Android 홈화면 위젯에 데이터를 전달하고 갱신을 트리거하는 서비스.
///
/// 흐름:
///   앱 위젯 CRUD → [DaylyWidgetStorage] → [HomeWidgetService.updateAll]
///       → home_widget 패키지 → SharedPreferences(Android) / UserDefaults(iOS)
///       → 네이티브 위젯 갱신
class HomeWidgetService {
  const HomeWidgetService._();

  static final _dateFormat = DateFormat('yyyy.MM.dd');

  /// 앱 시작 시 한 번 호출 — App Group ID 등록 (iOS 필수).
  static Future<void> init() async {
    try {
      await HomeWidget.setAppGroupId(HomeWidgetConfig.appGroupId);
    } catch (e) {
      debugPrint('[HomeWidget] init failed: $e');
    }
  }

  /// 위젯 목록 전체를 네이티브 레이어에 저장하고 위젯 UI를 갱신한다.
  ///
  /// [widgets]가 비어 있으면 빈 JSON 배열을 저장하고 "empty" 플래그를 세운다.
  static Future<void> updateAll(List<DaylyWidgetModel> widgets) async {
    try {
      final dataList = widgets.map(_toHomeWidgetData).toList();
      final jsonString = jsonEncode(dataList.map((d) => d.toJson()).toList());

      await HomeWidget.saveWidgetData(
        HomeWidgetConfig.keyWidgetsJson,
        jsonString,
      );

      // 가장 가까운 D-Day ID를 대표로 저장 (Fallback용)
      if (widgets.isNotEmpty) {
        final nearest = _nearestWidget(widgets);
        await HomeWidget.saveWidgetData(
          HomeWidgetConfig.keySelectedWidgetId,
          nearest.id,
        );
      }

      await HomeWidget.updateWidget(
        iOSName: HomeWidgetConfig.iOSWidgetName,
        androidName: HomeWidgetConfig.androidWidgetName,
        qualifiedAndroidName:
            'juny.dayly.${HomeWidgetConfig.androidWidgetName}',
      );
    } catch (e) {
      debugPrint('[HomeWidget] updateAll failed: $e');
    }
  }

  /// 특정 위젯 하나를 삭제했을 때 나머지 목록으로 재갱신.
  static Future<void> removeAndUpdate(
    String removedId,
    List<DaylyWidgetModel> remaining,
  ) async {
    await updateAll(remaining);
  }

  // ── 내부 헬퍼 ──────────────────────────────────────────────────

  static HomeWidgetData _toHomeWidgetData(DaylyWidgetModel model) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(
      model.targetDate.year,
      model.targetDate.month,
      model.targetDate.day,
    );
    final diff = target.difference(today);
    final days = diff.inDays;
    final isPast = days < 0;

    final countdownText = buildCountdownPhrase(
      mode: model.style.countdownMode,
      dayDiff: days,
    );

    return HomeWidgetData(
      id: model.id,
      sentence: model.primarySentence,
      daysCount: days.abs(),
      countdownText: countdownText,
      targetDateLabel: _dateFormat.format(model.targetDate),
      themePreset: model.style.themePreset.name,
      isPast: isPast,
    );
  }

  static DaylyWidgetModel _nearestWidget(List<DaylyWidgetModel> widgets) {
    final now = DateTime.now();
    return widgets.reduce((a, b) {
      final aDiff = (a.targetDate.difference(now)).inDays.abs();
      final bDiff = (b.targetDate.difference(now)).inDays.abs();
      return aDiff <= bDiff ? a : b;
    });
  }
}
