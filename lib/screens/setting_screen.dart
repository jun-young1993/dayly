import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ui_kit_firebase_auth_gate/flutter_ui_kit_firebase_auth_gate.dart';
import 'package:flutter_ui_kit_setting/flutter_ui_kit_setting.dart';
import 'package:flutter_ui_kit_theme/flutter_ui_kit_theme.dart';
import 'package:flutter_ui_kit_l10n/flutter_ui_kit_l10n.dart';
import 'package:google_sign_in/google_sign_in.dart';


class AppSettingScreen extends StatefulWidget {
  const AppSettingScreen({super.key,
    required this.controller
  });

  final DsThemeController controller;

  @override
  State<AppSettingScreen> createState() => _AppSettingScreenState();
}

class _AppSettingScreenState extends State<AppSettingScreen> {
  DsThemeController get _ctrl => widget.controller;
  @override
  Widget build(BuildContext context) {
    final l10n = UiKitLocalizations.of(context);
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
          if(user != null){
            user.getIdToken()
            .then((jwt){
              log(jwt??'-');
            })
            .catchError((error){
              print(error);
            });
                                  
          }
        return _buildScreen(context, l10n, user);
      },
    );
  }

  Widget _buildScreen(BuildContext context, UiKitLocalizations l10n, User? user) {
    return SettingScreen(
        title: l10n.settings,
        sections: [
          SettingSection(
            title: 'Profile',
            items: [
              SettingAppNavigationAuthTile<User>(
                user: user, 
                loginLabel: l10n.custom((locale) => switch(locale.languageCode) {
                  'ko' =>  '로그인',
                  'ja' => 'ログイン',
                  _ => 'Login'
                }),
                loginSubtitle: l10n.custom((locale) => switch(locale.languageCode) {
                  'ko' =>  '탭 하여 로그인 하세요.',
                  'ja' => 'タップしてログイン',
                  _ => 'Tap to log in'
                }),
                displayName: (u) => u.displayName ?? '-', 
                onTap: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AuthGate(
                        signedIn: Builder(
                          builder: (context) {
                         
                              
                            if(user == null){
                              return Text('hi');
                            }
                            return AuthProfileScreen(
                              user: user,
                              showEdit: true,
                              useEditDisplayName: true,
                              onSignOut: () async {
                                Navigator.of(context).pop();
                                await FirebaseAuth.instance.signOut();
                              },
                              onSave: (String displayName, String? photoUrl) async {
                                await user.updateDisplayName(displayName);
                                await user.updatePhotoURL(photoUrl);
                                await user.reload();
                                return FirebaseAuth.instance.currentUser;
                              },
                            );
                          },
                        ),
                        signedOut: const _SignInEntry(),
                      )
                    )
                  );
                }, 
                
              ),

            ]
          ),
          SettingSection(
            title: l10n.settingsLanguage,
            items: [
              UiKitLocaleToggle(
                currentLocale: _ctrl.locale,
                onLocaleChanged: (l) => _ctrl.setLocale(l),
                label: l10n.settingsLanguage,
              ),
            ]
          ),
          ...buildDefaultSettingSections(
            themeMode: _ctrl.themeMode,
            onThemeModeChanged: (t) => _ctrl.setThemeMode(t),
            brand: _ctrl.brand,
            onBrandChanged: (b) => _ctrl.setBrand(b),
            developerEmail: 'juny3738@gmail.com',
            emailSubject: '[dayly] Support Request',
            shareText: 'https://juny.blog/redirect/app/store/name/dayly',
            appStoreUrl: Platform.isIOS ? 'https://apps.apple.com/us/app/D-Dayly/id6760478559' : null,
            playStoreUrl: Platform.isAndroid ? 'https://play.google.com/store/apps/details?id=juny.dayly' : null,
            homepageUrl: 'https://juny.blog/blog/4743110c-39cf-4c1a-b8f7-059958c4dd4G',
            showBuildNumber: true,
            appName: 'D-Dayly',
            appDescription: ' Beautiful D-Day widgets for your home screen. \r\n Count down to what matters — your way.  ',
          ),
        ]
    );
  }
}

class _SignInEntry extends StatelessWidget {
  const _SignInEntry();

  Future<void> _googleSignIn(BuildContext context) async {
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    await FirebaseAuth.instance.signInWithCredential(credential);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SignInScreen(
      logo: const _Logo(),
      onSignIn: (email, pw) => FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pw,
      ),
      onGoogleSignIn: () async {
        await _googleSignIn(context);
      },
      onNavigateToSignUp: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const _SignUpEntry()),
      ),
    );
  }
}

class _SignUpEntry extends StatelessWidget {
  const _SignUpEntry();

  @override
  Widget build(BuildContext context) {
    return SignUpScreen(
      logo: const _Logo(),
      onSignUp: (email, pw) async {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: pw,
        );
        if (context.mounted) Navigator.pop(context);
      },
      onNavigateToSignIn: () => Navigator.pop(context),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lock_outline, color: Colors.white70),
        SizedBox(width: 8),
        Text(
          'Auth Gate',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}