// import 'package:dayly/config.dart';
// import 'package:dayly/firebase_options.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_ui_auth/firebase_ui_auth.dart';
// import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dayly/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

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
