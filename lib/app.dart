import 'package:dayly/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:dayly/screens/widget_grid_screen.dart';

/// App root for Dayly.
///
/// Core rule: widget-first. The primary entry is the Share Preview screen,
/// which mirrors the widget and is the first thing users see.
Widget buildDaylyApp() {
  return MaterialApp(
    title: 'dayly',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF111827),
        brightness: Brightness.dark,
      ),
    ),
    home: AuthGate(child: WidgetGridScreen()),
  );
}
