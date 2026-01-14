import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:dayly/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(buildDaylyApp());
}
