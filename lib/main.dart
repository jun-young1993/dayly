import 'dart:async';

import 'package:dayly/firebase_options.dart';
import 'package:dayly/home_widget/home_widget_service.dart';
import 'package:dayly/repositories/notification_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_ui_kit_google_mobile_ads/flutter_ui_kit_google_mobile_ads.dart';
import 'package:flutter_ui_kit_theme/flutter_ui_kit_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:dayly/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final themeController = DsThemeController();

  // runApp()을 먼저 호출해 스플래시 화면을 즉시 표시.
  // 초기화는 백그라운드 Future로 전달해 FutureBuilder가 완료 시 전환한다.
  runApp(DaylyApp(
    themeController: themeController,
    initFuture: _initialize(themeController),
  ));
}

Future<void> _initialize(DsThemeController themeController) async {
  // 광고 초기화를 가장 먼저 fire-and-forget으로 시작.
  // 나머지 init과 병렬로 진행해 스플래시가 끝날 때쯤 광고가 로드되도록 한다.
  unawaited(_initAds());

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('[main] Firebase.initializeApp failed: $e');
  }

  await GoogleSignIn.instance.initialize();

  tz.initializeTimeZones();
  final tzInfo = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(tzInfo.identifier));

  await Hive.initFlutter();

  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );

  await themeController.init();

  try {
    await NotificationRepository.instance.init(plugin);
  } catch (e) {
    debugPrint('[main] NotificationRepository.init failed: $e — deleting box and retrying');
    await Hive.deleteBoxFromDisk('dayly_notif_v1');
    await NotificationRepository.instance.init(plugin);
  }

  try {
    await HomeWidgetService.init();
  } catch (e) {
    debugPrint('[main] Home widget Service: $e');
  }

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}\n${details.stack}');
  };
}

Future<void> _initAds() async {
  try {
    await GlobalAdConfig().initialize();
    GlobalAdConfig().setAdVisibility(false);
    AppOpenAdManager.instance.cooldown = const Duration(hours: 24);
    AppOpenAdManager.instance.configure(
      androidId: 'ca-app-pub-4656262305566191/4017810905',
      iosId: 'ca-app-pub-4656262305566191/9437357221',
    );
    AppOpenAdManager.instance.loadAd();
  } catch (e) {
    debugPrint('[main] AdMob: $e');
  }
}
