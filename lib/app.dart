import 'dart:async';

import 'package:dayly/home_widget/home_widget_service.dart';
import 'package:dayly/repositories/notification_repository.dart';
import 'package:dayly/screens/widget_grid_screen.dart';
import 'package:dayly/storage/dayly_widget_storage.dart';
import 'package:dayly/utils/dayly_analytics.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_ui_kit_google_mobile_ads/flutter_ui_kit_google_mobile_ads.dart';
import 'package:flutter_ui_kit_theme/flutter_ui_kit_theme.dart';
import 'package:flutter_ui_kit_l10n/flutter_ui_kit_l10n.dart';

/// App root for Dayly.
///
/// ScreenUtilInit 기준: 390×844 (iPhone 14 Pro 논리 해상도)
/// 태블릿(splitScreenMode: true)에서도 비율 유지.


class DaylyApp extends StatefulWidget {

  const DaylyApp({super.key, required this.themeController});
  final DsThemeController themeController;

  @override
  State<DaylyApp> createState() => _DaylyAppState();
}

class _DaylyAppState extends State<DaylyApp> with WidgetsBindingObserver {
  DsThemeController get _themeController => widget.themeController;
  StreamSubscription<Uri?>? _widgetClickedSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 홈 화면 위젯 탭으로 앱이 열리면 home_widget_installed 이벤트 발생.
    _widgetClickedSub = HomeWidget.widgetClicked.listen((_) {
      unawaited(DaylyAnalytics.logHomeWidgetInstalled());
    });
  }

  @override
  void dispose() {
    _widgetClickedSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      loadDaylyWidgets().then((widgets) async {
        final (widgets: advanced, :anyChanged) = advanceRecurringAll(widgets);
        if (anyChanged) {
          // saveDaylyWidgets 내부에서 HomeWidgetService.updateAll 호출
          await saveDaylyWidgets(advanced);
          // 반복 이벤트 날짜 갱신 시 알림도 재예약
          unawaited(NotificationRepository.instance.syncOnAppStart(advanced));
        } else {
          await HomeWidgetService.updateAll(widgets);
        }
      }).catchError(
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
      builder: (_, child) => ListenableBuilder(
        listenable: _themeController,
        child: child,
        builder: (_, child) => MaterialApp(
          title: 'dayly',
          debugShowCheckedModeBanner: false,
          themeMode: _themeController.themeMode,
          theme: _themeController.lightTheme,
          darkTheme: _themeController.darkTheme,
          locale: _themeController.locale,
          localizationsDelegates: UiKitLocalizations.localizationsDelegates,
          supportedLocales: UiKitLocalizations.supportedLocales,
          home: child,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: WidgetGridScreen(
              themeController: _themeController,
            ),
          ),
          // BannerAdWidget — 에뮬레이터에서 SurfaceProducer GPU 렌더링 불가로 검은 화면 유발.
          // TODO: 실기기 테스트 후 재활성화.
          BannerAdWidget(
            androidId: 'ca-app-pub-4656262305566191/8847465750',
            iosId: 'ca-app-pub-4656262305566191/5810238878',
          ),
        ],
      ),
    );
  }
}



