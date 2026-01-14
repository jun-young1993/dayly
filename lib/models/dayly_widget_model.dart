import 'package:flutter/material.dart';

import 'package:dayly/theme/dayly_palette.dart';
import 'package:dayly/theme/dayly_theme_presets.dart';

/// Display format for the D-Day number.
///
/// Rule: only "23일" or "D-23" are allowed.
enum DaylyNumberFormat {
  daysSuffix,
  dMinus,
}

/// Expanded "time sense" display modes.
///
/// Rule alignment: keep the widget emotional; avoid raw number obsession.
/// Note: We intentionally do NOT introduce D+ here (rule & product restraint).
enum DaylyCountdownMode {
  days,
  dMinus,
  weeksDays,
  mornings,
  nights,
  hidden,
}

/// Background types allowed by the rule.
enum DaylyBackgroundType {
  solid,
  gradient,
  photo,
}

@immutable
class DaylyBackgroundStyle {
  const DaylyBackgroundStyle.solid({
    required this.solidColor,
  })  : type = DaylyBackgroundType.solid,
        gradientColors = null,
        photoAssetPath = null;

  const DaylyBackgroundStyle.gradient({
    required this.gradientColors,
  })  : type = DaylyBackgroundType.gradient,
        solidColor = null,
        photoAssetPath = null;

  /// Photo is supported conceptually but kept as an asset-path stub for now.
  /// Rule notes: blur + dark overlay + automatic contrast adjustment.
  const DaylyBackgroundStyle.photo({
    required this.photoAssetPath,
  })  : type = DaylyBackgroundType.photo,
        solidColor = null,
        gradientColors = null;

  final DaylyBackgroundType type;
  final Color? solidColor;
  final List<Color>? gradientColors;
  final String? photoAssetPath;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'type': type.name,
      'solidColor': solidColor?.toARGB32(),
      'gradientColors': gradientColors?.map((c) => c.toARGB32()).toList(),
      'photoAssetPath': photoAssetPath,
    };
  }

  static DaylyBackgroundStyle fromJson(Map<String, Object?> json) {
    final typeName = json['type'];
    final parsedType = DaylyBackgroundType.values.firstWhere(
      (v) => v.name == typeName,
      orElse: () => DaylyBackgroundType.solid,
    );

    switch (parsedType) {
      case DaylyBackgroundType.solid:
        return DaylyBackgroundStyle.solid(
          solidColor: Color((json['solidColor'] as int?) ?? 0xFF111827),
        );
      case DaylyBackgroundType.gradient:
        final raw = (json['gradientColors'] as List?) ?? const <int>[];
        final colors = raw.whereType<int>().map(Color.new).toList();
        return DaylyBackgroundStyle.gradient(
          gradientColors: colors.isEmpty
              ? const <Color>[Color(0xFF111827), Color(0xFF1F2937)]
              : colors,
        );
      case DaylyBackgroundType.photo:
        return DaylyBackgroundStyle.photo(
          photoAssetPath: (json['photoAssetPath'] as String?) ?? '',
        );
    }
  }
}

@immutable
class DaylyWidgetStyle {
  const DaylyWidgetStyle({
    required this.themePreset,
    required this.background,
    required this.numberFormat,
    required this.countdownMode,
    required this.showDivider,
    required this.isWatermarkEnabled,
    required this.isPremium,
  });

  /// Default: dark gradient + watermark enabled (free).
  const DaylyWidgetStyle.defaults()
      : themePreset = DaylyThemePreset.night,
        background = const DaylyBackgroundStyle.gradient(
          gradientColors: DaylyPalette.defaultGradient,
        ),
        numberFormat = DaylyNumberFormat.daysSuffix,
        countdownMode = DaylyCountdownMode.days,
        showDivider = true,
        isWatermarkEnabled = true,
        isPremium = false;

  final DaylyThemePreset themePreset;
  final DaylyBackgroundStyle background;
  final DaylyNumberFormat numberFormat;
  final DaylyCountdownMode countdownMode;
  final bool showDivider;
  final bool isWatermarkEnabled;

  /// Premium removes watermark.
  final bool isPremium;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'themePreset': themePreset.name,
      'background': background.toJson(),
      'numberFormat': numberFormat.name,
      'countdownMode': countdownMode.name,
      'showDivider': showDivider,
      'isWatermarkEnabled': isWatermarkEnabled,
      'isPremium': isPremium,
    };
  }

  static DaylyWidgetStyle fromJson(Map<String, Object?> json) {
    final backgroundJson = (json['background'] as Map?)?.cast<String, Object?>();
    final numberFormatName = json['numberFormat'];
    final countdownModeName = json['countdownMode'];
    final themePresetName = json['themePreset'];
    return DaylyWidgetStyle(
      themePreset: DaylyThemePreset.values.firstWhere(
        (v) => v.name == themePresetName,
        orElse: () => DaylyThemePreset.night,
      ),
      background: backgroundJson == null
          ? const DaylyBackgroundStyle.solid(solidColor: Color(0xFF111827))
          : DaylyBackgroundStyle.fromJson(backgroundJson),
      numberFormat: DaylyNumberFormat.values.firstWhere(
        (v) => v.name == numberFormatName,
        orElse: () => DaylyNumberFormat.daysSuffix,
      ),
      countdownMode: DaylyCountdownMode.values.firstWhere(
        (v) => v.name == countdownModeName,
        orElse: () => DaylyCountdownMode.days,
      ),
      showDivider: (json['showDivider'] as bool?) ?? true,
      isWatermarkEnabled: (json['isWatermarkEnabled'] as bool?) ?? true,
      isPremium: (json['isPremium'] as bool?) ?? false,
    );
  }

  DaylyWidgetStyle copyWith({
    DaylyThemePreset? themePreset,
    DaylyBackgroundStyle? background,
    DaylyNumberFormat? numberFormat,
    DaylyCountdownMode? countdownMode,
    bool? showDivider,
    bool? isWatermarkEnabled,
    bool? isPremium,
  }) {
    return DaylyWidgetStyle(
      themePreset: themePreset ?? this.themePreset,
      background: background ?? this.background,
      numberFormat: numberFormat ?? this.numberFormat,
      countdownMode: countdownMode ?? this.countdownMode,
      showDivider: showDivider ?? this.showDivider,
      isWatermarkEnabled: isWatermarkEnabled ?? this.isWatermarkEnabled,
      isPremium: isPremium ?? this.isPremium,
    );
  }
}

@immutable
class DaylyWidgetModel {
  const DaylyWidgetModel({
    required this.primarySentence,
    required this.targetDate,
    required this.style,
  });

  /// Rule-aligned starter content.
  factory DaylyWidgetModel.defaults({DateTime? now}) {
    final safeNow = (now ?? DateTime.now()).toLocal();
    final defaultTarget = DateTime(
      safeNow.year,
      safeNow.month,
      safeNow.day,
    ).add(const Duration(days: 23));
    return DaylyWidgetModel(
      primarySentence: '우리는 다시 만날 때까지 23일',
      targetDate: defaultTarget,
      style: const DaylyWidgetStyle.defaults(),
    );
  }

  /// Rule: max 2 lines in UI. Keep model as plain text, enforce in UI layer.
  final String primarySentence;
  final DateTime targetDate;
  final DaylyWidgetStyle style;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'primarySentence': primarySentence,
      'targetDate': targetDate.toIso8601String(),
      'style': style.toJson(),
    };
  }

  static DaylyWidgetModel fromJson(Map<String, Object?> json) {
    final styleJson = (json['style'] as Map?)?.cast<String, Object?>();
    return DaylyWidgetModel(
      primarySentence: (json['primarySentence'] as String?) ?? '',
      targetDate: DateTime.tryParse((json['targetDate'] as String?) ?? '') ??
          DateTime.now(),
      style: styleJson == null
          ? const DaylyWidgetStyle.defaults()
          : DaylyWidgetStyle.fromJson(styleJson),
    );
  }

  DaylyWidgetModel copyWith({
    String? primarySentence,
    DateTime? targetDate,
    DaylyWidgetStyle? style,
  }) {
    return DaylyWidgetModel(
      primarySentence: primarySentence ?? this.primarySentence,
      targetDate: targetDate ?? this.targetDate,
      style: style ?? this.style,
    );
  }
}

