import 'dart:convert';

import 'package:dayly/models/dayly_widget_model.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _widgetsKey = 'dayly.widgets.v1';

/// Loads and saves the widget list on-device.
///
/// We store an ordered list of [DaylyWidgetModel] as JSON in SharedPreferences.
Future<List<DaylyWidgetModel>> loadDaylyWidgets() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_widgetsKey);
    if (raw == null || raw.isEmpty) return <DaylyWidgetModel>[];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return <DaylyWidgetModel>[];

    return decoded
        .whereType<Map>()
        .map((m) => m.cast<String, Object?>())
        .map(DaylyWidgetModel.fromJson)
        .toList(growable: false);
  } catch (e, st) {
    debugPrint('loadDaylyWidgets failed: $e\n$st');
    return <DaylyWidgetModel>[];
  }
}

Future<void> saveDaylyWidgets(List<DaylyWidgetModel> widgets) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = widgets.map((w) => w.toJson()).toList(growable: false);
    await prefs.setString(_widgetsKey, jsonEncode(jsonList));
  } catch (e, st) {
    debugPrint('saveDaylyWidgets failed: $e\n$st');
  }
}

