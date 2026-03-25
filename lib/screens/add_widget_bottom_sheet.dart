import 'dart:ui';

import 'package:dayly/models/dayly_widget_model.dart'; // generateWidgetId 포함
import 'package:dayly/theme/dayly_theme_presets.dart';
import 'package:dayly/utils/dayly_time.dart';
import 'package:dayly/widgets/recurring_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_ui_kit_l10n/flutter_ui_kit_l10n.dart';
import 'package:google_fonts/google_fonts.dart';

// ──────────────────────────────────────────────────────────────
// Public API
// ──────────────────────────────────────────────────────────────

/// "CREATE NEW MOMENT" 전체화면 모달.
///
/// 슬라이드-업 애니메이션으로 진입, Navigator.pop(model)으로 결과 반환.
/// 모든 수치에 flutter_screenutil 적용.
Future<DaylyWidgetModel?> showAddWidgetBottomSheet({
  required BuildContext context,
}) {
  return Navigator.of(context).push<DaylyWidgetModel>(
    PageRouteBuilder<DaylyWidgetModel>(
      fullscreenDialog: true,
      opaque: false,
      barrierColor: Colors.transparent,
      pageBuilder: (context, animation, _) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: const _AddMomentScreen(),
          ),
        );
      },
    ),
  );
}

// ──────────────────────────────────────────────────────────────
// 아이콘 옵션 데이터
// ──────────────────────────────────────────────────────────────

class _IconOption {
  const _IconOption({
    required this.icon,
    required this.gradient,
    required this.themePreset,
    required this.countdownMode,
  });

  final IconData icon;
  final List<Color> gradient;
  final DaylyThemePreset themePreset;
  final DaylyCountdownMode countdownMode;
}

const _kIconOptions = <_IconOption>[
  _IconOption(
    icon: Icons.cake_outlined,
    gradient: <Color>[Color(0xFF6C63FF), Color(0xFF9B8FFF)],
    themePreset: DaylyThemePreset.night,
    countdownMode: DaylyCountdownMode.days,
  ),
  _IconOption(
    icon: Icons.flight_outlined,
    gradient: <Color>[Color(0xFF4ECDC4), Color(0xFF44A08D)],
    themePreset: DaylyThemePreset.fog,
    countdownMode: DaylyCountdownMode.days,
  ),
  _IconOption(
    icon: Icons.favorite_outline,
    gradient: <Color>[Color(0xFFFF6B6B), Color(0xFFFF8E53)],
    themePreset: DaylyThemePreset.blush,
    countdownMode: DaylyCountdownMode.mornings,
  ),
  _IconOption(
    icon: Icons.star_outline,
    gradient: <Color>[Color(0xFFFFD93D), Color(0xFFFFC107)],
    themePreset: DaylyThemePreset.lavender,
    countdownMode: DaylyCountdownMode.days,
  ),
  _IconOption(
    icon: Icons.celebration_outlined,
    gradient: <Color>[Color(0xFF74B9FF), Color(0xFF0984E3)],
    themePreset: DaylyThemePreset.night,
    countdownMode: DaylyCountdownMode.dMinus,
  ),
  _IconOption(
    icon: Icons.school_outlined,
    gradient: <Color>[Color(0xFF55EFC4), Color(0xFF00B894)],
    themePreset: DaylyThemePreset.paper,
    countdownMode: DaylyCountdownMode.days,
  ),
  _IconOption(
    icon: Icons.music_note_outlined,
    gradient: <Color>[Color(0xFFFF9FF3), Color(0xFFF368E0)],
    themePreset: DaylyThemePreset.blush,
    countdownMode: DaylyCountdownMode.nights,
  ),
  _IconOption(
    icon: Icons.edit_note_outlined,
    gradient: <Color>[Color(0xFFFECB74), Color(0xFFFFA502)],
    themePreset: DaylyThemePreset.paper,
    countdownMode: DaylyCountdownMode.days,
  ),
];

// ──────────────────────────────────────────────────────────────
// 화면
// ──────────────────────────────────────────────────────────────

class _AddMomentScreen extends StatefulWidget {
  const _AddMomentScreen();

  @override
  State<_AddMomentScreen> createState() => _AddMomentScreenState();
}

class _AddMomentScreenState extends State<_AddMomentScreen> {
  final _nameController = TextEditingController();
  late DateTime _targetDate;
  var _selectedIconIndex = 0;
  DaylyRecurringType? _selectedRecurring;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().toLocal();
    _targetDate = DateTime(now.year, now.month, now.day + 30);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _nameController.text.trim().isNotEmpty;

  String get _dDayLabel {
    final d = calculateDayDifference(now: DateTime.now(), target: _targetDate);
    if (d == 0) return 'D-Day';
    if (d > 0) return 'D-$d';
    return 'D+${d.abs()}';
  }

  void _submit() {
    if (!_canSubmit) return;
    HapticFeedback.mediumImpact();

    final option = _kIconOptions[_selectedIconIndex];
    final style = DaylyWidgetStyle.defaults().copyWith(
      themePreset: option.themePreset,
      background: backgroundForTheme(option.themePreset),
      countdownMode: option.countdownMode,
      numberFormat: option.countdownMode == DaylyCountdownMode.dMinus
          ? DaylyNumberFormat.dMinus
          : DaylyNumberFormat.daysSuffix,
    );

    Navigator.of(context).pop(
      DaylyWidgetModel(
        id: generateWidgetId(),
        primarySentence: _nameController.text.trim(),
        targetDate: _targetDate,
        style: style,
        createdAt: DateTime.now(),
        isRecurring: _selectedRecurring != null,
        recurringType: _selectedRecurring,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: <Widget>[
          // 배경 그라데이션
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? <Color>[const Color(0xFF0D1F3C), const Color(0xFF0A0E1A)]
                    : <Color>[cs.surfaceContainerLow, cs.surface],
              ),
            ),
          ),
          // 장식 빛 — 우상단
          Positioned(
            top: -80.h,
            right: -60.w,
            child: Container(
              width: 220.w,
              height: 220.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    cs.primary.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _TopBar(onClose: () => Navigator.of(context).pop()),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        _NameField(
                          controller: _nameController,
                          onChanged: () => setState(() {}),
                        ),
                        SizedBox(height: 24.h),
                        _DateSection(
                          targetDate: _targetDate,
                          dDayLabel: _dDayLabel,
                          onDateChanged: (d) => setState(() => _targetDate = d),
                        ),
                        SizedBox(height: 24.h),
                        RecurringSection(
                          selected: _selectedRecurring,
                          onChanged: (v) =>
                              setState(() => _selectedRecurring = v),
                        ),
                        SizedBox(height: 24.h),
                        _IconSection(
                          options: _kIconOptions,
                          selectedIndex: _selectedIconIndex,
                          onSelected: (i) =>
                              setState(() => _selectedIconIndex = i),
                        ),
                        SizedBox(height: 32.h),
                      ],
                    ),
                  ),
                ),
                _SaveButton(enabled: _canSubmit, onTap: _submit),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 서브 위젯
// ──────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = UiKitLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(8.w, 8.h, 16.w, 0),
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: onClose,
            icon: Icon(Icons.close, color: cs.onSurfaceVariant, size: 22.sp),
          ),
          SizedBox(width: 4.w),
          Text(
            l10n.custom((locale) => switch (locale.languageCode) {
              'ko' => '새 순간 만들기',
              'ja' => '新しいモーメントを作成',
              _ => 'CREATE NEW MOMENT',
            }),
            style: GoogleFonts.montserrat(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final l10n = UiKitLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.custom((locale) => switch (locale.languageCode) {
            'ko' => '순간의 이름',
            'ja' => 'モーメントの名前',
            _ => 'Name your moment',
          }),
          style: GoogleFonts.montserrat(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: cs.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        SizedBox(height: 8.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : Colors.white.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: TextField(
                controller: controller,
                maxLines: 1,
                style: GoogleFonts.montserrat(
                  color: cs.onSurface,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 14.h,
                  ),
                  hintText: l10n.custom((locale) => switch (locale.languageCode) {
                    'ko' => '예) 첫 번째 기념일',
                    'ja' => '例）最初の記念日',
                    _ => 'e.g. Our First Anniversary',
                  }),
                  hintStyle: GoogleFonts.montserrat(
                    color: cs.onSurface.withValues(alpha: 0.24),
                    fontSize: 14.sp,
                  ),
                ),
                onChanged: (_) => onChanged(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DateSection extends StatelessWidget {
  const _DateSection({
    required this.targetDate,
    required this.dDayLabel,
    required this.onDateChanged,
  });

  final DateTime targetDate;
  final String dDayLabel;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final l10n = UiKitLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // 레이블 + D-Day 라이브 배지
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              l10n.custom((locale) => switch (locale.languageCode) {
                'ko' => '날짜 선택',
                'ja' => '日付選択',
                _ => 'Date Selection',
              }),
              style: GoogleFonts.montserrat(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
                letterSpacing: 0.8,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : cs.surfaceContainer,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Text(
                dDayLabel,
                style: GoogleFonts.robotoMono(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface.withValues(alpha: 0.70),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        // 인라인 캘린더 (글래스 카드)
        ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white.withValues(alpha: 0.60),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                    surface: Colors.transparent,
                  ),
                ),
                child: CalendarDatePicker(
                  initialDate: targetDate,
                  firstDate: DateTime(DateTime.now().year - 10),
                  lastDate: DateTime(DateTime.now().year + 30),
                  onDateChanged: onDateChanged,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IconSection extends StatelessWidget {
  const _IconSection({
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_IconOption> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = UiKitLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.custom((locale) => switch (locale.languageCode) {
            'ko' => '아이콘 & 색상',
            'ja' => 'アイコン & カラー',
            _ => 'Icon & Color',
          }),
          style: GoogleFonts.montserrat(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: cs.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 66.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = selectedIndex == index;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelected(index);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  margin: EdgeInsets.only(right: 10.w),
                  width: 56.w,
                  height: 56.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: option.gradient,
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.85)
                          : Colors.transparent,
                      width: 2.0,
                    ),
                    boxShadow: isSelected
                        ? <BoxShadow>[
                            BoxShadow(
                              color: option.gradient[0].withValues(alpha: 0.55),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(option.icon, color: Colors.white, size: 26.sp),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final l10n = UiKitLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24.w,
        8.h,
        24.w,
        MediaQuery.of(context).padding.bottom + 16.h,
      ),
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 56.h,
              decoration: BoxDecoration(
                color: enabled
                    ? isDark
                        ? Colors.white.withValues(alpha: 0.18)
                        : cs.primary.withValues(alpha: 0.12)
                    : isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: enabled
                      ? isDark
                          ? Colors.white.withValues(alpha: 0.30)
                          : cs.primary.withValues(alpha: 0.40)
                      : isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : cs.outlineVariant,
                ),
              ),
              child: Center(
                child: Text(
                  l10n.custom((locale) => switch (locale.languageCode) {
                    'ko' => '저장하기',
                    'ja' => '保存する',
                    _ => 'SAVE MOMENT',
                  }),
                  style: GoogleFonts.montserrat(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: enabled
                        ? isDark
                            ? Colors.white
                            : cs.primary
                        : cs.onSurface.withValues(alpha: 0.24),
                    letterSpacing: 2.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

