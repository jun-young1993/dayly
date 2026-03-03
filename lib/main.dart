// import 'package:dayly/config.dart';
// import 'package:dayly/firebase_options.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_ui_auth/firebase_ui_auth.dart';
// import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ui_kit_google_mobile_ads/flutter_ui_kit_google_mobile_ads.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dayly/app.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  await GlobalAdConfig().initialize();
  GlobalAdConfig().setAdVisibility(false);
  AppOpenAdManager.instance.configure(
    androidId: 'ca-app-pub-4656262305566191/4017810905',
    iosId: 'ca-app-pub-4656262305566191/9437357221'
  );
  AppOpenAdManager.instance.loadAd();

  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // FirebaseUIAuth.configureProviders([
  //   EmailAuthProvider(),
  //   GoogleProvider(clientId: GOOGLE_CLIENT_ID),
  // ]);

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}\n${details.stack}');
  };

  runApp(buildDaylyApp());
}
