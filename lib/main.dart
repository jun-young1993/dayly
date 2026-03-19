import 'dart:async';

import 'package:dayly/home_widget/home_widget_service.dart';
import 'package:dayly/repositories/notification_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_ui_kit_google_mobile_ads/flutter_ui_kit_google_mobile_ads.dart';
import 'package:flutter_ui_kit_theme/flutter_ui_kit_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:dayly/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  // ── 타임존 초기화 ─────────────────────────────────────────────
  // 반드시 runApp() 이전에 초기화해야 한다.
  // tz.TZDateTime을 쓰려면 최신 타임존 DB 로드가 선행되어야 함.
  tz.initializeTimeZones();
  // flutter_timezone 5.x: getLocalTimezone()은 TimezoneInfo를 반환.
  // .identifier = IANA 표준 이름 (예: "Asia/Seoul")
  final tzInfo = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(tzInfo.identifier));

  // ── Hive 초기화 ───────────────────────────────────────────────
  await Hive.initFlutter();

  // ── flutter_local_notifications 초기화 ───────────────────────
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );

  final themeController = DsThemeController();
  await themeController.init();



  // ── NotificationRepository 초기화 ────────────────────────────
  // Hive 박스가 이전 세션에서 비정상 종료된 경우 삭제 후 재시도.
  try {
    await NotificationRepository.instance.init(plugin);
  } catch (e) {
    debugPrint('[main] NotificationRepository.init failed: $e — deleting box and retrying');
    await Hive.deleteBoxFromDisk('dayly_notif_v1');
    await NotificationRepository.instance.init(plugin);
  }
  try{
    // ── 홈화면 위젯 초기화 (iOS App Group ID 등록) ─────────────────
    await HomeWidgetService.init();
  }catch(e){
    debugPrint('[main] Home widget Service: $e');
  }
  
  

  
  

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}\n${details.stack}');
  };

  runApp(DaylyApp(themeController: themeController));

  unawaited(() async {
    try{
      // ── 광고 초기화 ───────────────────────────────────────────────
      await GlobalAdConfig().initialize();
      // GlobalAdConfig().setAdVisibility(false);

      // App Open 광고: AppLifecycleState.resumed 마다 전면 광고를 표시함.
      // 쿨다운 없이 활성화 시 포그라운드 전환마다 광고가 노출되어 UX 훼손.
      // 에뮬레이터에서 GPU 렌더링 불가 시 검은 화면으로 표시되는 문제 확인.
      // TODO: flutter_ui_kit_google_mobile_ads에 쿨다운(1h) 추가 후 재활성화.
      // TODO: flutter_ui_kit_google_mobile_ads에 쿨다운(1h) 추가 후 재활성화.
      // App Open Ad: 쿨다운 없이 resumed마다 전면 광고가 떠 검은 화면 유발 — 비활성화
      AppOpenAdManager.instance.configure(
        androidId: 'ca-app-pub-4656262305566191/4017810905',
        iosId: 'ca-app-pub-4656262305566191/9437357221',
      );
      AppOpenAdManager.instance.loadAd();
    }catch(e){
      debugPrint('[main] AdMob: $e');
    }
  }());
  
}
