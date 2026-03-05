import 'package:dayly/home_widget/home_widget_service.dart';
import 'package:dayly/screens/widget_grid_screen.dart';
import 'package:dayly/storage/dayly_widget_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_ui_kit_google_mobile_ads/flutter_ui_kit_google_mobile_ads.dart';
import 'package:flutter_ui_kit_theme/flutter_ui_kit_theme.dart';

/// App root for Dayly.
///
/// ScreenUtilInit 기준: 390×844 (iPhone 14 Pro 논리 해상도)
/// 태블릿(splitScreenMode: true)에서도 비율 유지.
Widget buildDaylyApp() => const _DaylyApp();

class _DaylyApp extends StatefulWidget {
  const _DaylyApp();

  @override
  State<_DaylyApp> createState() => _DaylyAppState();
}

class _DaylyAppState extends State<_DaylyApp> with WidgetsBindingObserver {
  ThemeMode _themeMode = ThemeMode.system;
  DsBrand _brand = DsBrand.violet;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      loadDaylyWidgets().then(HomeWidgetService.updateAll).catchError(
            (e) => debugPrint('[App] widget refresh failed: $e'),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) => MaterialApp(
        title: 'dayly',
        debugShowCheckedModeBanner: false,
        themeMode: _themeMode,
        theme: _brand.lightTheme(),
        darkTheme: _brand.darkTheme(),
        home: child,
      ),
      child: Column(
        children: [
          Expanded(
            child: WidgetGridScreen(
              themeMode: _themeMode,
              onThemeModeChanged: (m) => setState(() => _themeMode = m),
              brand: _brand,
              onBrandToggled: (b) => setState(
                () => _brand =b,
              ),
            ),
          ),
          BannerAdWidget(
            androidId: 'ca-app-pub-4656262305566191/8847465750',
            iosId: 'ca-app-pub-4656262305566191/5810238878',
          ),
        ],
      ),
    );
  }
}



