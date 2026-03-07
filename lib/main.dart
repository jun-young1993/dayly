import 'dart:async';

import 'package:dayly/home_widget/home_widget_service.dart';
import 'package:dayly/repositories/notification_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_ui_kit_google_mobile_ads/flutter_ui_kit_google_mobile_ads.dart';
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
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );

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

  runApp(buildDaylyApp());

  unawaited(() async {
    try{
      // ── 광고 초기화 ───────────────────────────────────────────────
      await GlobalAdConfig().initialize();
      GlobalAdConfig().setAdVisibility(false);
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
