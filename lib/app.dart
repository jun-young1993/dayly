import 'dart:async';
import 'dart:ui';

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
import 'package:google_fonts/google_fonts.dart';

/// App root for Dayly.
///
/// ScreenUtilInit 기준: 390×844 (iPhone 14 Pro 논리 해상도)
/// 태블릿(splitScreenMode: true)에서도 비율 유지.


class DaylyApp extends StatefulWidget {

  const DaylyApp({
    super.key,
    required this.themeController,
    required this.initFuture,
  });
  final DsThemeController themeController;
  /// main()의 초기화 작업 완료를 알리는 Future.
  /// 완료 전엔 스플래시 화면을 표시하고, 완료되면 메인 화면으로 전환한다.
  final Future<void> initFuture;

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
    _widgetClickedSub = HomeWidget.widgetClicked.listen((_) {
      unawaited(DaylyAnalytics.logHomeWidgetInstalled());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshWidgets());

    // 초기화 완료 시 App Open 광고 표시 시도.
    // _initAds()가 병렬로 먼저 시작됐으므로 init이 끝날 때쯤 광고가 로드된 상태.
    // 쿨다운(24h) 내이거나 로드 안 됐으면 자동으로 건너뜀.
    widget.initFuture.then((_) {
      if (mounted) {
        AppOpenAdManager.instance.showAdIfAvailable();
      }
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
      _refreshWidgets();
    }
  }

  void _refreshWidgets() {
    loadDaylyWidgets().then((widgets) async {
      final (widgets: advanced, :anyChanged) = advanceRecurringAll(widgets);
      if (anyChanged) {
        await saveDaylyWidgets(advanced);
        unawaited(NotificationRepository.instance.syncOnAppStart(advanced));
      } else {
        await HomeWidgetService.updateAll(widgets);
      }
    }).catchError((Object e) {
      debugPrint('[App] widget refresh failed: $e');
    });
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        Expanded(
          child: WidgetGridScreen(
            themeController: _themeController,
          ),
        ),
        BannerAdWidget(
          androidId: 'ca-app-pub-4656262305566191/8847465750',
          iosId: 'ca-app-pub-4656262305566191/5810238878',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) => DsThemeBuilder(
        controller: _themeController,
        child: child,
        builder: (theme, child) => MaterialApp(
          title: 'D-Dayly',
          debugShowCheckedModeBanner: false,
          themeMode: theme.themeMode,
          theme: theme.lightTheme,
          darkTheme: theme.darkTheme,
          locale: theme.locale,
          localizationsDelegates: UiKitLocalizations.localizationsDelegates,
          supportedLocales: UiKitLocalizations.supportedLocales,
          home: child,
        ),
      ),
      child: FutureBuilder<void>(
        future: widget.initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _SplashScreen();
          }
          return _buildMainContent();
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 스플래시 화면 — 초기화 완료 전까지 표시
// ──────────────────────────────────────────────────────────────

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D1F3C), Color(0xFF0A0E1A)],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'D-Dayly',
                  style: GoogleFonts.montserrat(
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: Colors.white.withValues(alpha: 0.40),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
