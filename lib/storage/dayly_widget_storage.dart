import 'dart:convert';

import 'package:dayly/home_widget/home_widget_service.dart';
import 'package:dayly/models/dayly_widget_model.dart';
import 'package:dayly/utils/dayly_time.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _widgetsKey = 'dayly.widgets.v1';

/// Cached [SharedPreferences] instance to avoid repeated async lookups.
SharedPreferences? _prefsCache;

Future<SharedPreferences> _getPrefs() async {
  return _prefsCache ??= await SharedPreferences.getInstance();
}

/// Loads and saves the widget list on-device.
///
/// We store an ordered list of [DaylyWidgetModel] as JSON in SharedPreferences.
Future<List<DaylyWidgetModel>> loadDaylyWidgets() async {
  try {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_widgetsKey);
    if (raw == null || raw.isEmpty) return <DaylyWidgetModel>[];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return <DaylyWidgetModel>[];

    return decoded
        .whereType<Map>()
        .map((m) => m.cast<String, Object?>())
        .map(DaylyWidgetModel.fromJson)
        .toList();
  } catch (e, st) {
    debugPrint('loadDaylyWidgets failed: $e\n$st');
    return <DaylyWidgetModel>[];
  }
}

/// 반복 이벤트 위젯의 targetDate를 현재 날짜 이후로 진행한다.
///
/// - `isRecurring=false` 위젯은 그대로 패스
/// - 변경된 위젯이 하나라도 있으면 `anyChanged=true`
({List<DaylyWidgetModel> widgets, bool anyChanged}) advanceRecurringAll(
  List<DaylyWidgetModel> widgets,
) {
  bool anyChanged = false;
  final today = DateTime.now();
  final todayNorm = DateTime(today.year, today.month, today.day);
  final advanced = widgets.map((w) {
    if (!w.isRecurring || w.recurringType == null) return w;
    final newDate = advanceIfPast(w.targetDate, w.recurringType!);
    // guard=1200 도달 후 여전히 과거이면 손상된 데이터 — 반복 비활성화
    if (newDate.isBefore(todayNorm)) {
      debugPrint('[dayly] advanceRecurringAll: guard limit hit for ${w.id}, '
          'disabling recurring');
      anyChanged = true;
      return w.copyWith(isRecurring: false);
    }
    if (newDate == w.targetDate) return w;
    anyChanged = true;
    // 새 주기 시작 — createdAt 리셋으로 progress 게터 정상화
    return w.copyWith(targetDate: newDate, createdAt: today);
  }).toList();
  return (widgets: advanced, anyChanged: anyChanged);
}

/// [languageCode]는 앱 언어 코드 (ko/ja/en). null이면 기기 locale 사용.
Future<void> saveDaylyWidgets(
  List<DaylyWidgetModel> widgets, {
  String? languageCode,
}) async {
  try {
    final prefs = await _getPrefs();
    final jsonList = widgets.map((w) => w.toJson()).toList(growable: false);
    await prefs.setString(_widgetsKey, jsonEncode(jsonList));
    // 저장 후 홈화면 위젯 갱신
    await HomeWidgetService.updateAll(widgets, languageCode: languageCode);
  } catch (e, st) {
    debugPrint('saveDaylyWidgets failed: $e\n$st');
  }
}

