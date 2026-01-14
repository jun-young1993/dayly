import 'package:dayly/models/dayly_widget_model.dart';
import 'package:dayly/theme/dayly_palette.dart';
import 'package:flutter/material.dart';

/// Minimal, curated theme presets.
///
/// Theme = background + intended mood. Keep the set small and high quality.
enum DaylyThemePreset {
  night,
  paper,
  fog,
  lavender,
  blush,
}

String daylyThemeLabel(DaylyThemePreset preset) {
  switch (preset) {
    case DaylyThemePreset.night:
      return 'Night';
    case DaylyThemePreset.paper:
      return 'Paper';
    case DaylyThemePreset.fog:
      return 'Fog';
    case DaylyThemePreset.lavender:
      return 'Lavender';
    case DaylyThemePreset.blush:
      return 'Blush';
  }
}

DaylyBackgroundStyle backgroundForTheme(DaylyThemePreset preset) {
  switch (preset) {
    case DaylyThemePreset.night:
      return const DaylyBackgroundStyle.gradient(
        gradientColors: DaylyPalette.defaultGradient,
      );
    case DaylyThemePreset.paper:
      return const DaylyBackgroundStyle.solid(solidColor: DaylyPalette.paper);
    case DaylyThemePreset.fog:
      return const DaylyBackgroundStyle.solid(solidColor: DaylyPalette.fog);
    case DaylyThemePreset.lavender:
      return const DaylyBackgroundStyle.solid(
        solidColor: DaylyPalette.lavender,
      );
    case DaylyThemePreset.blush:
      return const DaylyBackgroundStyle.solid(solidColor: DaylyPalette.blush);
  }
}

@immutable
class DaylyThemeDepthSpec {
  const DaylyThemeDepthSpec({
    required this.highlightOpacity,
    required this.vignetteOpacity,
    required this.highlightAlignment,
  });

  /// Opacity of the radial highlight layer (0..1).
  final double highlightOpacity;

  /// Opacity of the vignette layer (0..1).
  final double vignetteOpacity;

  /// Where the highlight “comes from”. Top-left feels like soft daylight.
  final Alignment highlightAlignment;
}

/// Recommended on-text tone per theme (more intentional than luminance heuristic).
Color onTextColorForTheme(DaylyThemePreset preset) {
  switch (preset) {
    case DaylyThemePreset.night:
      return DaylyPalette.offWhite;
    case DaylyThemePreset.paper:
    case DaylyThemePreset.fog:
    case DaylyThemePreset.lavender:
    case DaylyThemePreset.blush:
      return DaylyPalette.inkSoft;
  }
}

/// Subtle depth parameters per theme.
DaylyThemeDepthSpec depthForTheme(DaylyThemePreset preset) {
  switch (preset) {
    case DaylyThemePreset.night:
      return const DaylyThemeDepthSpec(
        highlightOpacity: 0.06,
        vignetteOpacity: 0.10,
        highlightAlignment: Alignment.topCenter,
      );
    case DaylyThemePreset.paper:
      return const DaylyThemeDepthSpec(
        highlightOpacity: 0.10,
        vignetteOpacity: 0.08,
        highlightAlignment: Alignment.topLeft,
      );
    case DaylyThemePreset.fog:
      return const DaylyThemeDepthSpec(
        highlightOpacity: 0.11,
        vignetteOpacity: 0.08,
        highlightAlignment: Alignment.topLeft,
      );
    case DaylyThemePreset.lavender:
      return const DaylyThemeDepthSpec(
        highlightOpacity: 0.11,
        vignetteOpacity: 0.09,
        highlightAlignment: Alignment.topLeft,
      );
    case DaylyThemePreset.blush:
      return const DaylyThemeDepthSpec(
        highlightOpacity: 0.12,
        vignetteOpacity: 0.09,
        highlightAlignment: Alignment.topLeft,
      );
  }
}

/// Optional tint for chip previews.
Color previewColorForTheme(DaylyThemePreset preset) {
  switch (preset) {
    case DaylyThemePreset.night:
      return DaylyPalette.nightB;
    case DaylyThemePreset.paper:
      return DaylyPalette.paper;
    case DaylyThemePreset.fog:
      return DaylyPalette.fog;
    case DaylyThemePreset.lavender:
      return DaylyPalette.lavender;
    case DaylyThemePreset.blush:
      return DaylyPalette.blush;
  }
}

