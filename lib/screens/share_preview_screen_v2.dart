import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:dayly/utils/dayly_image_utils.dart';

import 'package:dayly/models/dayly_widget_model.dart';
import 'package:dayly/utils/dayly_time.dart';
import 'package:dayly/theme/dayly_theme_presets.dart';
import 'package:dayly/utils/dayly_sentence_templates.dart';
import 'package:dayly/utils/dayly_share_export.dart';
import 'package:dayly/widgets/dayly_widget_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_ui_kit_l10n/flutter_ui_kit_l10n.dart';
import 'package:dayly/utils/dayly_analytics.dart';

class SharePreviewScreenV2 extends StatefulWidget {
  const SharePreviewScreenV2({
    super.key,
    required this.initialModel,
  });

  final DaylyWidgetModel initialModel;

  @override
  State<SharePreviewScreenV2> createState() => _SharePreviewScreenV2State();
}

class _SharePreviewScreenV2State extends State<SharePreviewScreenV2> {
  final GlobalKey _captureKey = GlobalKey();
  late DaylyWidgetModel _model;
  var _isSharing = false;
  String? _resolvedImagePath;

  @override
  void initState() {
    super.initState();
    _model = widget.initialModel;
    _resolveImage();
  }

  Future<void> _resolveImage() async {
    final resolved = await resolveWidgetBackgroundImagePath(
      _model.backgroundImagePath,
    );
    if (mounted) setState(() => _resolvedImagePath = resolved);
  }

  Future<void> _shareCurrentPreview() async {
    if (_isSharing) return;
    final l10n = UiKitLocalizations.of(context);
    setState(() => _isSharing = true);
    unawaited(DaylyAnalytics.logShareTapped());

    try {
      // Wait for the current frame to finish rendering before capturing.
      final completer = Completer<void>();
      SchedulerBinding.instance.addPostFrameCallback((_) => completer.complete());
      await completer.future;

      final pngBytes = await captureBoundaryPng(boundaryKey: _captureKey);

      final dayDiff = calculateDayDifference(
        now: DateTime.now(),
        target: _model.targetDate,
      );
      final dDayText = dayDiff == 0
          ? 'D-Day'
          : dayDiff > 0
              ? 'D-$dayDiff'
              : 'D+${dayDiff.abs()}';
      final storeUrl = Platform.isIOS
          ? 'https://apps.apple.com/app/id6760478559'
          : 'https://play.google.com/store/apps/details?id=juny.dayly';
      final shareText = '${_model.primarySentence} ($dDayText)\n\ndayly - $storeUrl';

      await sharePngBytes(
        pngBytes: pngBytes,
        fileName: 'dayly-share.png',
        text: shareText,
      );
    } catch (e, st) {
      debugPrint('share failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.custom((locale) => switch (locale.languageCode) {
            'ko' => '공유에 실패했습니다. 다시 시도해주세요.',
            'ja' => '共有に失敗しました。もう一度お試しください。',
            _ => 'Sharing failed. Please try again.',
          }))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _editSentence() async {
    final controller = TextEditingController(text: _model.primarySentence);
     final l10n = UiKitLocalizations.of(context);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                l10n.custom((locale) => switch(locale.languageCode) {
                  'ko' => '문구 편집',
                  'ja' =>  '文言編集',
                  _ => 'Sentence Editing'
                }),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(l10n.custom((locale) => switch (locale.languageCode) {
                'ko' => '날짜만이 아닌, 그 날의 의미를 담아보세요. (최대 2줄)',
                'ja' => '日付だけでなく、その日の意味を込めましょう。（最大2行）',
                _ => 'Tell us why it matters, not just the date. (Max 2 lines)',
              })),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 2,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: l10n.custom((locale) => switch (locale.languageCode) {
                    'ko' => '예) 다시 만날 때까지 23일',
                    'ja' => '例）再会まで23日',
                    _ => 'e.g. 23 days until we meet again',
                  }),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(controller.text.trim()),
                child: Text(l10n.custom((locale) => switch (locale.languageCode) {
                  'ko' => '적용',
                  'ja' => '適用',
                  _ => 'Apply',
                })),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (result == null) return;
    if (result.isEmpty) return;
    setState(() => _model = _model.copyWith(primarySentence: result));
  }

  Future<void> _openTemplateGenerator() async {
    final request = await showModalBottomSheet<DaylyTemplateRequest>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final now = DateTime.now().toLocal();
        final target = _model.targetDate.toLocal();
        final dayDiff = DateTime(target.year, target.month, target.day)
            .difference(DateTime(now.year, now.month, now.day))
            .inDays;
        return _TemplateSheet(
          initialDayDiff: dayDiff,
          initialCountdownMode: _model.style.countdownMode,
        );
      },
    );

    if (request == null) return;
    final sentence = generateDaylySentence(request);
    if (sentence.trim().isEmpty) return;
    setState(() => _model = _model.copyWith(primarySentence: sentence.trim()));
  }

  Future<void> _editTargetDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _model.targetDate,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 30),
    );
    if (picked == null) return;
    setState(() => _model = _model.copyWith(targetDate: picked));
  }

  Future<void> _pickCountdownMode() async {
    final l10n = UiKitLocalizations.of(context);
    final picked = await showModalBottomSheet<DaylyCountdownMode>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  l10n.custom((locale) => switch (locale.languageCode) {
                    'ko' => '표현 방식',
                    'ja' => '表現スタイル',
                    _ => 'Expression Style',
                  }),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: DaylyCountdownMode.values.map((mode) {
                    return ChoiceChip(
                      label: Text(_countdownModeLabel(mode, context)),
                      selected: _model.style.countdownMode == mode,
                      onSelected: (_) => Navigator.of(context).pop(mode),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked == null) return;
    setState(() => _model = _model.copyWith(style: _model.style.copyWith(countdownMode: picked)));
  }

  Future<void> _pickThemePreset() async {
    final l10n = UiKitLocalizations.of(context);
    final picked = await showModalBottomSheet<DaylyThemePreset>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  l10n.custom((locale) => switch (locale.languageCode) {
                    'ko' => '테마',
                    'ja' => 'テーマ',
                    _ => 'Theme',
                  }),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: DaylyThemePreset.values.map((preset) {
                    return ChoiceChip(
                      label: Text(daylyThemeLabel(preset)),
                      selected: _model.style.themePreset == preset,
                      avatar: CircleAvatar(
                        radius: 8,
                        backgroundColor: previewColorForTheme(preset),
                      ),
                      onSelected: (_) => Navigator.of(context).pop(preset),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked == null) return;
    setState(
      () => _model = _model.copyWith(
        style: _model.style.copyWith(
          themePreset: picked,
          background: backgroundForTheme(picked),
        ),
      ),
    );
  }

  void _togglePremium() {
    HapticFeedback.selectionClick();
    final nextPremium = !_model.style.isPremium;
    setState(() => _model = _model.copyWith(style: _model.style.copyWith(isPremium: nextPremium)));
  }

  void _toggleDivider() {
    HapticFeedback.selectionClick();
    setState(() => _model = _model.copyWith(style: _model.style.copyWith(showDivider: !_model.style.showDivider)));
  }

  String _formatDate(DateTime date) =>
      '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';

  String _countdownModeLabel(DaylyCountdownMode mode, BuildContext ctx) {
    final l10n = UiKitLocalizations.of(ctx);
    return l10n.custom((locale) => switch (locale.languageCode) {
      'ko' => switch (mode) {
        DaylyCountdownMode.days => '23일 남음',
        DaylyCountdownMode.dMinus => 'D-23',
        DaylyCountdownMode.weeksDays => '3주 23일',
        DaylyCountdownMode.mornings => '42번의 아침',
        DaylyCountdownMode.nights => '42번의 밤',
        DaylyCountdownMode.hidden => '숫자 숨김',
      },
      'ja' => switch (mode) {
        DaylyCountdownMode.days => '23日後',
        DaylyCountdownMode.dMinus => 'D-23',
        DaylyCountdownMode.weeksDays => '3週23日',
        DaylyCountdownMode.mornings => '42回の朝',
        DaylyCountdownMode.nights => '42回の夜',
        DaylyCountdownMode.hidden => '数字を隠す',
      },
      _ => switch (mode) {
        DaylyCountdownMode.days => '23 days left',
        DaylyCountdownMode.dMinus => 'D-23',
        DaylyCountdownMode.weeksDays => '3 weeks 23 days',
        DaylyCountdownMode.mornings => '42 mornings',
        DaylyCountdownMode.nights => '42 nights',
        DaylyCountdownMode.hidden => 'hide numbers',
      },
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = UiKitLocalizations.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_model);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E1A),
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: <Widget>[
            // Background gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Color(0xFF0D1F3C), Color(0xFF0A0E1A)],
                ),
              ),
            ),
            // Decorative light — top right
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
                      const Color(0xFF6C63FF).withValues(alpha: 0.08),
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
                  // Custom top bar
                  Padding(
                    padding: EdgeInsets.fromLTRB(8.w, 8.h, 16.w, 0),
                    child: Row(
                      children: <Widget>[
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(_model),
                          icon: Icon(Icons.close, color: Colors.white54, size: 22.sp),
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            l10n.custom((locale) => switch (locale.languageCode) {
                              'ko' => '편집',
                              'ja' => '編集',
                              _ => 'EDIT MOMENT',
                            }),
                            style: GoogleFonts.montserrat(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                        if (_isSharing)
                          SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white54,
                            ),
                          )
                        else
                          IconButton(
                            onPressed: _shareCurrentPreview,
                            tooltip: l10n.custom((locale) => switch (locale.languageCode) {
                              'ko' => '공유',
                              'ja' => '共有',
                              _ => 'Share',
                            }),
                            icon: Icon(Icons.ios_share, color: Colors.white54, size: 22.sp),
                          ),
                      ],
                    ),
                  ),
                  // Scroll content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          // Preview label
                          Text(
                            l10n.custom((locale) => switch (locale.languageCode) {
                              'ko' => '미리보기',
                              'ja' => 'プレビュー',
                              _ => 'Preview',
                            }),
                            style: GoogleFonts.montserrat(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.white38,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          // Preview glass card
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20.r),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(20.r),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.10),
                                  ),
                                ),
                                padding: EdgeInsets.all(16.w),
                                child: Center(
                                  child: RepaintBoundary(
                                    key: _captureKey,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(maxWidth: 300.w),
                                      child: DaylyWidgetCard(
                                        model: _model,
                                        size: DaylyWidgetSize.large,
                                        resolvedImagePath: _resolvedImagePath,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 24.h),
                          // Edit options label
                          Text(
                            l10n.custom((locale) => switch (locale.languageCode) {
                              'ko' => '편집 옵션',
                              'ja' => '編集オプション',
                              _ => 'Edit Options',
                            }),
                            style: GoogleFonts.montserrat(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.white38,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          // _GlassEditTile(
                          //   icon: Icons.auto_awesome,
                          //   label: '문장 템플릿',
                          //   value: '관계 × 톤 × 이벤트로 자동 생성',
                          //   onTap: _openTemplateGenerator,
                          // ),
                          SizedBox(height: 8.h),
                          _GlassEditTile(
                            icon: Icons.edit_note,
                            label: l10n.custom((locale) => switch (locale.languageCode) {
                              'ko' => '문구 편집',
                              'ja' => '文言編集',
                              _ => 'Sentence Editing',
                            }),
                            value: _model.primarySentence,
                            onTap: _editSentence,
                          ),
                          SizedBox(height: 8.h),
                          _GlassEditTile(
                            icon: Icons.event,
                            label: l10n.custom((locale) => switch (locale.languageCode) {
                              'ko' => '날짜',
                              'ja' => '日付',
                              _ => 'Date',
                            }),
                            value: _formatDate(_model.targetDate),
                            onTap: _editTargetDate,
                          ),
                          SizedBox(height: 8.h),
                          _GlassEditTile(
                            icon: Icons.palette_outlined,
                            label: l10n.custom((locale) => switch (locale.languageCode) {
                              'ko' => '테마',
                              'ja' => 'テーマ',
                              _ => 'Theme',
                            }),
                            value: daylyThemeLabel(_model.style.themePreset),
                            onTap: _pickThemePreset,
                          ),
                          SizedBox(height: 8.h),
                          _GlassEditTile(
                            icon: Icons.numbers,
                            label: l10n.custom((locale) => switch (locale.languageCode) {
                              'ko' => '표현 방식',
                              'ja' => '表現スタイル',
                              _ => 'Expression Style',
                            }),
                            value: _countdownModeLabel(_model.style.countdownMode, context),
                            onTap: _pickCountdownMode,
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _GlassToggleTile(
                                  icon: Icons.more_horiz,
                                  label: l10n.custom((locale) => switch (locale.languageCode) {
                                    'ko' => '구분선',
                                    'ja' => '区切り線',
                                    _ => 'Divider',
                                  }),
                                  isOn: _model.style.showDivider,
                                  onTap: _toggleDivider,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: _GlassToggleTile(
                                  icon: Icons.workspace_premium,
                                  label: l10n.custom((locale) => switch (locale.languageCode) {
                                    'ko' => '프리미엄',
                                    'ja' => 'プレミアム',
                                    _ => 'Premium',
                                  }),
                                  isOn: _model.style.isPremium,
                                  onTap: _togglePremium,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 32.h),
                        ],
                      ),
                    ),
                  ),
                  // Bottom share button
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      24.w,
                      8.h,
                      24.w,
                      MediaQuery.of(context).padding.bottom + 16.h,
                    ),
                    child: GestureDetector(
                      onTap: _isSharing
                          ? null
                          : () {
                              HapticFeedback.mediumImpact();
                              _shareCurrentPreview();
                            },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.r),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 56.h,
                            decoration: BoxDecoration(
                              color: !_isSharing
                                  ? Colors.white.withValues(alpha: 0.18)
                                  : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: !_isSharing
                                    ? Colors.white.withValues(alpha: 0.30)
                                    : Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Center(
                              child: _isSharing
                                  ? SizedBox(
                                      width: 20.w,
                                      height: 20.w,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white54,
                                      ),
                                    )
                                  : Text(
                                      l10n.custom((locale) => switch (locale.languageCode) {
                                        'ko' => '공유하기',
                                        'ja' => '共有する',
                                        _ => 'SHARE MOMENT',
                                      }),
                                      style: GoogleFonts.montserrat(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 2.5,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Glass edit tile
// ──────────────────────────────────────────────────────────────

class _GlassEditTile extends StatelessWidget {
  const _GlassEditTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              children: <Widget>[
                Icon(icon, color: Colors.white60, size: 20.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        label,
                        style: GoogleFonts.montserrat(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white38,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        value,
                        style: GoogleFonts.montserrat(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white24, size: 18.sp),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Glass toggle tile
// ──────────────────────────────────────────────────────────────

class _GlassToggleTile extends StatelessWidget {
  const _GlassToggleTile({
    required this.icon,
    required this.label,
    required this.isOn,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isOn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isOn
                  ? Colors.white.withValues(alpha: 0.14)
                  : Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: isOn
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.10),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
            child: Row(
              children: <Widget>[
                Icon(
                  icon,
                  color: isOn ? Colors.white : Colors.white38,
                  size: 18.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.montserrat(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: isOn ? Colors.white : Colors.white38,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Text(
                  isOn ? 'ON' : 'OFF',
                  style: GoogleFonts.robotoMono(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: isOn ? Colors.white60 : Colors.white24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Template sheet
// ──────────────────────────────────────────────────────────────

class _TemplateSheet extends StatefulWidget {
  const _TemplateSheet({
    required this.initialDayDiff,
    required this.initialCountdownMode,
  });

  final int initialDayDiff;
  final DaylyCountdownMode initialCountdownMode;

  @override
  State<_TemplateSheet> createState() => _TemplateSheetState();
}

class _TemplateSheetState extends State<_TemplateSheet> {
  var _relationship = DaylyRelationshipType.couple;
  var _tone = DaylyTone.calm;
  late DaylyCountdownMode _mode;
  final _eventController = TextEditingController(text: 'Wedding');

  @override
  void initState() {
    super.initState();
    _mode = widget.initialCountdownMode;
  }

  @override
  void dispose() {
    _eventController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final request = DaylyTemplateRequest(
      relationshipType: _relationship,
      tone: _tone,
      eventLabel: _eventController.text,
      dayDiff: widget.initialDayDiff,
      countdownMode: _mode,
    );
    final preview = generateDaylySentence(request);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Sentence Template',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text('Choose a sentence instead of just numbers.'),
            const SizedBox(height: 14),
            const _SectionLabel(text: 'Relationship'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <_ChipSpec<DaylyRelationshipType>>[
                _ChipSpec(DaylyRelationshipType.couple, 'Couple'),
                _ChipSpec(DaylyRelationshipType.family, 'Family'),
                _ChipSpec(DaylyRelationshipType.solo, 'Solo'),
                _ChipSpec(DaylyRelationshipType.goal, 'Goal'),
              ].map((spec) {
                return ChoiceChip(
                  label: Text(spec.label),
                  selected: _relationship == spec.value,
                  onSelected: (_) => setState(() => _relationship = spec.value),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            const _SectionLabel(text: 'Tone'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <_ChipSpec<DaylyTone>>[
                _ChipSpec(DaylyTone.calm, 'Calm'),
                _ChipSpec(DaylyTone.flutter, 'Excited'),
                _ChipSpec(DaylyTone.longing, 'Longing'),
                _ChipSpec(DaylyTone.playful, 'Playful'),
              ].map((spec) {
                return ChoiceChip(
                  label: Text(spec.label),
                  selected: _tone == spec.value,
                  onSelected: (_) => setState(() => _tone = spec.value),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            const _SectionLabel(text: 'Expression Style'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DaylyCountdownMode.values.map((mode) {
                final label = switch (mode) {
                  DaylyCountdownMode.days => '23 days',
                  DaylyCountdownMode.dMinus => 'D-23',
                  DaylyCountdownMode.weeksDays => '3 weeks 2 days',
                  DaylyCountdownMode.mornings => '42 mornings',
                  DaylyCountdownMode.nights => '42 nights',
                  DaylyCountdownMode.hidden => 'hide numbers',
                };
                return ChoiceChip(
                  label: Text(label),
                  selected: _mode == mode,
                  onSelected: (_) => setState(() => _mode = mode),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            const _SectionLabel(text: 'Event(Optional)'),
            const SizedBox(height: 8),
            TextField(
              controller: _eventController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'e.g. Wedding / Discharge / Exam / Trip',
              ),
            ),
            const SizedBox(height: 14),
            const _SectionLabel(text: 'Preview'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(preview, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(request),
              child: const Text('Apply this sentence'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w700));
  }
}

class _ChipSpec<T> {
  const _ChipSpec(this.value, this.label);
  final T value;
  final String label;
}
