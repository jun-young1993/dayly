import 'package:flutter/material.dart';
import 'package:flutter_ui_kit_setting/flutter_ui_kit_setting.dart';
import 'package:flutter_ui_kit_theme/flutter_ui_kit_theme.dart';

class AppSettingScreen extends StatefulWidget {
  const AppSettingScreen({super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.brand,
    required this.onBrandChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final DsBrand brand;
  final ValueChanged<DsBrand> onBrandChanged;

  @override
  State<AppSettingScreen> createState() => _AppSettingScreenState();
}

class _AppSettingScreenState extends State<AppSettingScreen> {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SettingScreen(
        title: 'Setting',
        sections: [
          SettingSection(
              items: [
                SettingThemeToggleTile(
                  themeMode: widget.themeMode,
                  onChanged: widget.onThemeModeChanged                ),
                SettingBrandToggleTile(
                    brand: widget.brand, onChanged: widget.onBrandChanged)
              ]
          ),
          // ── 개발자 ─────────────────────────────────────────────
          SettingSection(
            title: 'Developer',
            items: [
              SettingDeveloperEmailTile(
                email: 'juny3738@gmail.com',
                label: 'Contact Developer',
                subject: '[dayly] Support Request',
              ),
            ],
          ),
          // ── 앱 정보 ────────────────────────────────────────────
          SettingSection(
            title: 'About',
            items: [
              SettingAppVersionTile(
                label: 'App Version',
                showBuildNumber: true,
              ),
              SettingTile(
                label: 'dayly',
                subtitle: 'More emotional widgets, more engaging sharing, clearer information.',
                leading: Icon(Icons.widgets_outlined, color: theme.colorScheme.primary),
              ),
            ],
          ),
        ]
    );
  }


}