import 'dart:convert';
import 'dart:io';

import 'package:dayly/home_widget/home_widget_config.dart';
import 'package:dayly/home_widget/home_widget_data.dart';
import 'package:dayly/models/dayly_widget_model.dart';
import 'package:dayly/utils/dayly_countdown_phrase.dart';
import 'package:dayly/utils/dayly_image_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_foundation/path_provider_foundation.dart';

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
  /// [languageCode]는 앱에서 사용자가 선택한 언어 코드 (ko/ja/en).
  /// null이면 기기 시스템 locale을 fallback으로 사용한다.
  static Future<void> updateAll(
    List<DaylyWidgetModel> widgets, {
    String? languageCode,
  }) async {
    try {
      final lang = languageCode ?? PlatformDispatcher.instance.locale.languageCode;
      final dataList = await Future.wait(
        widgets.map((w) => _toHomeWidgetDataAsync(w, lang)),
      );
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

      // SMALL / MEDIUM / LARGE 위젯 모두 갱신 — 각 호출을 독립 try/catch로 격리
      // (어느 한 위젯 실패 시 나머지 갱신이 스킵되는 silent failure 방지)
      try {
        await HomeWidget.updateWidget(
          iOSName: HomeWidgetConfig.iOSWidgetName,
          androidName: HomeWidgetConfig.androidWidgetName,
          qualifiedAndroidName:
              'juny.dayly.${HomeWidgetConfig.androidWidgetName}',
        );
      } catch (e) {
        debugPrint('[HomeWidget] updateWidget(Small) failed: $e');
      }
      // MEDIUM / LARGE
      for (final name in HomeWidgetConfig.androidAdditionalWidgetNames) {
        try {
          await HomeWidget.updateWidget(
            androidName: name,
            qualifiedAndroidName: 'juny.dayly.$name',
          );
        } catch (e) {
          debugPrint('[HomeWidget] updateWidget($name) failed: $e');
        }
      }
    } catch (e) {
      debugPrint('[HomeWidget] updateAll failed: $e');
    }
  }

  /// 특정 위젯 하나를 삭제했을 때 나머지 목록으로 재갱신.
  static Future<void> removeAndUpdate(
    String removedId,
    List<DaylyWidgetModel> remaining, {
    String? languageCode,
  }) async {
    await updateAll(remaining, languageCode: languageCode);
  }

  // ── 내부 헬퍼 ──────────────────────────────────────────────────

  static final _isoDateFormat = DateFormat('yyyy-MM-dd');

  static Future<HomeWidgetData> _toHomeWidgetDataAsync(
    DaylyWidgetModel model, [
    String lang = 'en',
  ]) async {
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

    final resolvedImagePath =
        await _resolveImageForWidget(model.backgroundImagePath);

    return HomeWidgetData(
      id: model.id,
      sentence: model.primarySentence,
      daysCount: days.abs(),
      countdownText: countdownText,
      targetDateLabel: _dateFormat.format(model.targetDate),
      themePreset: model.style.themePreset.name,
      isPast: isPast,
      targetDate: _isoDateFormat.format(model.targetDate),
      countdownMode: model.style.countdownMode.name,
      languageCode: lang,
      backgroundImagePath: resolvedImagePath,
      createdAt: _isoDateFormat.format(model.createdAt),
    );
  }

  /// iOS: 배경 이미지를 App Group 공유 컨테이너로 복사하고 절대 경로를 반환.
  /// Android: 절대 경로로 변환 후 반환. 파일이 존재하지 않으면 null.
  static Future<String?> _resolveImageForWidget(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return imagePath;
    if (!Platform.isIOS) {
      // Android: 절대 경로로 변환하여 네이티브 위젯의 context.filesDir 의존 해석 제거
      return resolveWidgetBackgroundImagePath(imagePath);
    }

    try {
      // 원본 파일 해석
      final appDir = await getApplicationDocumentsDirectory();
      final srcPath = p.isAbsolute(imagePath)
          ? imagePath
          : p.join(appDir.path, imagePath);
      final srcFile = File(srcPath);
      if (!await srcFile.exists()) return null;

      // App Group 공유 컨테이너 경로 획득
      final provider = PathProviderFoundation();
      final containerPath = await provider.getContainerPath(
        appGroupIdentifier: HomeWidgetConfig.appGroupId,
      );
      if (containerPath == null) return null;

      // 공유 컨테이너 내 backgrounds 디렉터리에 복사
      final fileName = p.basename(srcPath);
      final destDir = Directory(p.join(containerPath, 'backgrounds'));
      if (!await destDir.exists()) {
        await destDir.create(recursive: true);
      }
      final destPath = p.join(destDir.path, fileName);
      await srcFile.copy(destPath);

      return destPath;
    } catch (e) {
      debugPrint('[HomeWidget] _resolveImageForWidget failed: $e');
      return null;
    }
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
