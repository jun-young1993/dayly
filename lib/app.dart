import 'package:dayly/screens/widget_grid_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_ui_kit_google_mobile_ads/flutter_ui_kit_google_mobile_ads.dart';

/// App root for Dayly.
///
/// ScreenUtilInit 기준: 390×844 (iPhone 14 Pro 논리 해상도)
/// 태블릿(splitScreenMode: true)에서도 비율 유지.
Widget buildDaylyApp() {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (_, child) => MaterialApp(
      title: 'dayly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E1A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
          surface: const Color(0xFF0D1F3C),
          onSurface: Colors.white,
        ),
      ),
      home: child,
    ),
    child: Column(
      children: [
        Expanded(child: WidgetGridScreen()),
        BannerAdWidget(androidId: 'ca-app-pub-4656262305566191/8847465750', iosId: 'ca-app-pub-4656262305566191/5810238878'),
      ],
    ),
  );
}
