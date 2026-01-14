import 'package:flutter/material.dart';

/// Curated, minimal palette for a high-end "emotional typography" widget.
///
/// Rule alignment:
/// - Soft solids / subtle gradients
/// - No harsh colors
/// - Calm, screenshot-worthy backgrounds
class DaylyPalette {
  const DaylyPalette._();

  // Text tones (avoid pure white / pure black for calmer contrast)
  static const offWhite = Color(0xFFF4F6FA);
  static const ink = Color(0xFF0B1220);
  static const inkSoft = Color(0xFF121A2B); // slightly lifted ink for gentler contrast

  // Muted dark gradient (default)
  static const nightA = Color(0xFF0B1220); // deep ink
  static const nightB = Color(0xFF111827); // charcoal navy

  // Soft solids (curated pastel set)
  static const paper = Color(0xFFF7F2EA); // warm paper (slightly cleaner)
  static const fog = Color(0xFFE9F0F7); // cool fog blue
  static const lavender = Color(0xFFF1ECF8); // pale lavender mist
  static const blush = Color(0xFFF8EDEF); // soft blush pink
  static const mint = Color(0xFFEAF4F0); // muted mint (optional)

  static const defaultGradient = <Color>[nightA, nightB];
}

