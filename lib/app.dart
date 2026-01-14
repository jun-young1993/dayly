import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

import 'package:dayly/screens/widget_grid_screen.dart';

/// App root for Dayly.
///
/// Core rule: widget-first. The primary entry is the Share Preview screen,
/// which mirrors the widget and is the first thing users see.
Widget buildDaylyApp() {
  final firebaseAuthProviders = [EmailAuthProvider()];

  return MaterialApp(
    title: 'dayly',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF111827)),
    ),
    initialRoute: FirebaseAuth.instance.currentUser == null ? '/auth' : '/home',
    routes: {
      '/auth': (context) {
        return SignInScreen(
          providers: firebaseAuthProviders,
          actions: [
            AuthStateChangeAction<UserCreated>((context, state) {}),
            AuthStateChangeAction<SignedIn>((context, state) {}),
          ],
        );
      },
      '/home': (context) {
        return const WidgetGridScreen();
      },
    },
  );
}
