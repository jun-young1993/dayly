import 'package:dayly/config.dart';
import 'package:dayly/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:dayly/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (kDebugMode) {
    // Android 에뮬레이터에서 호스트 PC는 10.0.2.2로 접근해야 함 (localhost X)
    await FirebaseAuth.instance.useAuthEmulator('10.0.2.2', 9099);
  }

  FirebaseUIAuth.configureProviders([
    EmailAuthProvider(),
    GoogleProvider(clientId: GOOGLE_CLIENT_ID),
  ]);

  runApp(buildDaylyApp());
}
