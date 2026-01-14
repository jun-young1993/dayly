import 'dart:ui' as ui;

import 'package:dayly/models/dayly_widget_model.dart';
import 'package:dayly/theme/dayly_palette.dart';
import 'package:dayly/theme/dayly_theme_presets.dart';
import 'package:dayly/utils/dayly_countdown_phrase.dart';
import 'package:dayly/utils/dayly_formatters.dart';
import 'package:dayly/utils/dayly_time.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum DaylyWidgetSize { small, medium, large }

@immutable
class DaylyWidgetCard extends StatelessWidget {
  const DaylyWidgetCard({super.key, required this.model, required this.size});

  final DaylyWidgetModel model;
  final DaylyWidgetSize size;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLarge = size == DaylyWidgetSize.large;
        final isMedium = size == DaylyWidgetSize.medium;

        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 420.0;
        final maxH = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 220.0;

        // In tiny preview tiles (e.g. grid), prioritize "fits" over density.
        final isMicro = maxW < 140 || maxH < 140;

        final baseHorizontalPadding = isLarge
            ? 24.0
            : isMedium
            ? 20.0
            : 16.0; // rule: min 16dp (for real widget sizes)
        final baseVerticalPadding = isLarge
            ? 28.0
            : isMedium
            ? 24.0
            : 20.0; // rule: min 20dp (for real widget sizes)

        final horizontalPadding = isMicro
            ? (maxW * 0.10).clamp(6.0, 12.0)
            : baseHorizontalPadding;
        final verticalPadding = isMicro
            ? (maxH * 0.12).clamp(6.0, 14.0)
            : baseVerticalPadding;

        final density = isMicro ? (maxH / 220).clamp(0.70, 0.92) : 1.0;

        final dayDiff = calculateDayDifference(
          now: DateTime.now(),
          target: model.targetDate,
        );
        final numberText =
            model.style.countdownMode == DaylyCountdownMode.hidden
            ? ''
            : buildCountdownPhrase(
                mode: _mapCountdownMode(model.style),
                dayDiff: dayDiff,
              );

        final sentenceBase = isLarge
            ? 17.0
            : isMedium
            ? 15.0
            : 14.0;
        final sentenceStyle = GoogleFonts.gowunDodum(
          fontSize: (sentenceBase * density).clamp(10.0, 18.0),
          fontWeight: FontWeight.w300,
          height: 1.55, // calmer, breathable (rule: >= 1.4)
          letterSpacing: isMicro ? 0 : 0.1,
        );

        final numberFontSize = (sentenceStyle.fontSize! * 1.82)
            .clamp(16.0, 40.0)
            .toDouble();
        final numberStyle = GoogleFonts.robotoMono(
          fontSize: numberFontSize, // rule: 1.6x-2.0x
          fontWeight: FontWeight.w800,
          height: 1.05,
          fontFeatures: const <ui.FontFeature>[ui.FontFeature.tabularFigures()],
        );

        final dateStyle = GoogleFonts.gowunDodum(
          fontSize:
              ((isLarge
                          ? 13.0
                          : isMedium
                          ? 12.0
                          : 11.0) *
                      density)
                  .clamp(9.0, 13.0),
          fontWeight: FontWeight.w400,
          height: 1.35,
        ).copyWith(color: _withOpacity(_resolveOnBackgroundColor(model), 0.58));

        final onBackground = _resolveOnBackgroundColor(model);
        final sentenceColor = _withOpacity(onBackground, 0.92);
        final numberColor = _withOpacity(onBackground, 0.98);
        final watermarkColor = _withOpacity(onBackground, 0.36);
        final depth = depthForTheme(model.style.themePreset);

        final showDate = !isMicro && size != DaylyWidgetSize.small;
        final showDivider = !isMicro && model.style.showDivider && isLarge;
        final showWatermark = !isMicro && _isWatermarkVisible(model.style);
        final dividerOpacity = model.style.themePreset == DaylyThemePreset.night
            ? 0.26
            : 0.16;
        final numberShadow = isMicro
            ? const <Shadow>[]
            : <Shadow>[
                Shadow(
                  offset: const Offset(0, 1),
                  blurRadius: 10,
                  color: _withOpacity(
                    model.style.themePreset == DaylyThemePreset.night
                        ? Colors.black
                        : Colors.black,
                    model.style.themePreset == DaylyThemePreset.night
                        ? 0.22
                        : 0.08,
                  ),
                ),
              ];

        final content = Center(
          child: FittedBox(
            fit: isMicro ? BoxFit.scaleDown : BoxFit.none,
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  model.primarySentence,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: sentenceStyle.copyWith(color: sentenceColor),
                ),
                SizedBox(height: (isLarge ? 16.0 : 12.0) * density),
                if (model.style.countdownMode != DaylyCountdownMode.hidden)
                  Text(
                    numberText,
                    textAlign: TextAlign.center,
                    style: numberStyle.copyWith(
                      color: numberColor,
                      shadows: numberShadow,
                    ),
                  ),
                SizedBox(height: (isLarge ? 10.0 : 8.0) * density),
                if (showDate)
                  Text(
                    formatKoreanDotDate(model.targetDate),
                    textAlign: TextAlign.center,
                    style: dateStyle,
                  ),
                if (showDivider) ...<Widget>[
                  SizedBox(height: 18.0 * density),
                  _EmotionalDivider(
                    color: _withOpacity(onBackground, dividerOpacity),
                  ),
                ],
                if (showWatermark) ...<Widget>[
                  SizedBox(height: (isLarge ? 22.0 : 14.0) * density),
                  Text(
                    'dayly',
                    style: GoogleFonts.roboto(
                      fontSize: (11.0 * density).clamp(9.0, 11.0),
                      fontWeight: FontWeight.w500,
                      color: watermarkColor,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );

        final baseDecoration = BoxDecoration(
          color: model.style.background.type == DaylyBackgroundType.solid
              ? model.style.background.solidColor
              : null,
          gradient: model.style.background.type == DaylyBackgroundType.gradient
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors:
                      model.style.background.gradientColors ??
                      const <Color>[Color(0xFF111827), Color(0xFF1F2937)],
                )
              : null,
        );

        final highlight = DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: depth.highlightAlignment,
              radius: 1.05,
              colors: <Color>[
                _withOpacity(Colors.white, depth.highlightOpacity),
                _withOpacity(Colors.white, 0),
              ],
              stops: const <double>[0, 0.75],
            ),
          ),
        );
        final vignette = DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.05,
              colors: <Color>[
                _withOpacity(Colors.transparent, 0),
                _withOpacity(Colors.black, depth.vignetteOpacity),
              ],
              stops: const <double>[0.62, 1],
            ),
          ),
        );

        return ClipRRect(
          borderRadius: BorderRadius.circular(isLarge ? 22 : 18),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              DecoratedBox(decoration: baseDecoration),
              if (!isMicro) highlight,
              if (!isMicro) vignette,
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: DefaultTextStyle(
                  style: TextStyle(color: onBackground),
                  child: content,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

bool _isWatermarkVisible(DaylyWidgetStyle style) {
  if (style.isPremium) return false;
  return style.isWatermarkEnabled;
}

DaylyCountdownMode _mapCountdownMode(DaylyWidgetStyle style) {
  // Keep backwards compatibility: if someone still toggles numberFormat,
  // it maps to a countdown mode.
  if (style.countdownMode != DaylyCountdownMode.days) {
    return style.countdownMode;
  }
  return style.numberFormat == DaylyNumberFormat.dMinus
      ? DaylyCountdownMode.dMinus
      : DaylyCountdownMode.days;
}

Color _resolveOnBackgroundColor(DaylyWidgetModel model) {
  // Prefer curated theme intent.
  final presetTone = onTextColorForTheme(model.style.themePreset);

  // Fallback heuristic for unexpected custom backgrounds.
  final background = model.style.background;
  if (background.type == DaylyBackgroundType.solid &&
      background.solidColor != null) {
    final luminance = background.solidColor!.computeLuminance();
    return luminance > 0.6 ? DaylyPalette.inkSoft : DaylyPalette.offWhite;
  }
  return presetTone;
}

Color _withOpacity(Color color, double opacity) {
  return color.withValues(alpha: opacity);
}

class _EmotionalDivider extends StatelessWidget {
  const _EmotionalDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 10,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(
            3,
            (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: DecoratedBox(
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: const SizedBox(width: 3.5, height: 3.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
