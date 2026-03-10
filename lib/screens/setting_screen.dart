import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_ui_kit_setting/flutter_ui_kit_setting.dart';
import 'package:flutter_ui_kit_theme/flutter_ui_kit_theme.dart';
import 'package:flutter_ui_kit_l10n/flutter_ui_kit_l10n.dart';

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
    final theme = Theme.of(context);
    final l10n = UiKitLocalizations.of(context);
    return SettingScreen(
        title: l10n.settings,
        sections: [
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
            shareText: 'http://juny.blog/redirect/app/store/name/dayly',
            appStoreUrl: Platform.isIOS ? 'https://apps.apple.com/us/app/frame-time-pro/id6759611898' : null,
            playStoreUrl: Platform.isAndroid ? 'https://play.google.com/store/apps/details?id=juny.dayly' : null,
            homepageUrl: 'https://juny.blog',
            showBuildNumber: true,
            appName: 'dayly',
            appDescription: 'More emotional widgets, more engaging sharing, clearer information.',
          ),
        ]
    );
  }


}