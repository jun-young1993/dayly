import 'dart:convert';

import 'package:dayly/home_widget/home_widget_service.dart';
import 'package:dayly/models/dayly_widget_model.dart';
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

