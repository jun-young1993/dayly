import 'package:flutter/material.dart';

import 'package:dayly/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(buildDaylyApp());
}
