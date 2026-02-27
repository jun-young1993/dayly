import 'dart:async';
import 'dart:ui';

import 'package:dayly/models/dayly_widget_model.dart';
import 'package:dayly/theme/dayly_theme_presets.dart';
import 'package:dayly/utils/dayly_sentence_templates.dart';
import 'package:dayly/utils/dayly_share_export.dart';
import 'package:dayly/widgets/dayly_widget_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

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

  @override
  void initState() {
    super.initState();
    _model = widget.initialModel;
  }

  Future<void> _shareCurrentPreview() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      await Future<void>.delayed(const Duration(milliseconds: 16));
      final pngBytes = await captureBoundaryPng(boundaryKey: _captureKey);
      await sharePngBytes(
        pngBytes: pngBytes,
        fileName: 'dayly-share.png',
        text: 'dayly',
      );
    } catch (e, st) {
      // ignore: avoid_print
      print('share failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('공유에 실패했어요. 다시 시도해 주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _editSentence() async {
    final controller = TextEditingController(text: _model.primarySentence);
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
              const Text(
                '문장 수정',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text('날짜가 아니라, "왜 중요한지"를 말해 주세요. (최대 2줄)'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 2,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '예) 우리는 다시 만날 때까지 23일',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(controller.text.trim()),
                child: const Text('적용'),
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
                const Text(
                  '표현 방식',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: DaylyCountdownMode.values.map((mode) {
                    return ChoiceChip(
                      label: Text(_countdownModeLabel(mode)),
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
                const Text(
                  '테마',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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

  String _countdownModeLabel(DaylyCountdownMode mode) => switch (mode) {
        DaylyCountdownMode.days => '23일',
        DaylyCountdownMode.dMinus => 'D-23',
        DaylyCountdownMode.weeksDays => '3주 2일',
        DaylyCountdownMode.mornings => '42번의 아침',
        DaylyCountdownMode.nights => '42번의 밤',
        DaylyCountdownMode.hidden => '숫자 숨김',
      };

  @override
  Widget build(BuildContext context) {
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
            // 배경 그라데이션
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Color(0xFF0D1F3C), Color(0xFF0A0E1A)],
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
                  // 커스텀 상단 바
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
                            'EDIT MOMENT',
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
                            tooltip: '공유',
                            icon: Icon(Icons.ios_share, color: Colors.white54, size: 22.sp),
                          ),
                      ],
                    ),
                  ),
                  // 스크롤 컨텐츠
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          // 미리보기 레이블
                          Text(
                            'Preview',
                            style: GoogleFonts.montserrat(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.white38,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          // 미리보기 글래스 카드
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
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 24.h),
                          // 편집 옵션 레이블
                          Text(
                            'Edit Options',
                            style: GoogleFonts.montserrat(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.white38,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          _GlassEditTile(
                            icon: Icons.auto_awesome,
                            label: '문장 템플릿',
                            value: '관계 × 톤 × 이벤트로 자동 생성',
                            onTap: _openTemplateGenerator,
                          ),
                          SizedBox(height: 8.h),
                          _GlassEditTile(
                            icon: Icons.edit_note,
                            label: '문장 수정',
                            value: _model.primarySentence,
                            onTap: _editSentence,
                          ),
                          SizedBox(height: 8.h),
                          _GlassEditTile(
                            icon: Icons.event,
                            label: '날짜',
                            value: _formatDate(_model.targetDate),
                            onTap: _editTargetDate,
                          ),
                          SizedBox(height: 8.h),
                          _GlassEditTile(
                            icon: Icons.palette_outlined,
                            label: '테마',
                            value: daylyThemeLabel(_model.style.themePreset),
                            onTap: _pickThemePreset,
                          ),
                          SizedBox(height: 8.h),
                          _GlassEditTile(
                            icon: Icons.numbers,
                            label: '표현 방식',
                            value: _countdownModeLabel(_model.style.countdownMode),
                            onTap: _pickCountdownMode,
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _GlassToggleTile(
                                  icon: Icons.more_horiz,
                                  label: '디바이더',
                                  isOn: _model.style.showDivider,
                                  onTap: _toggleDivider,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: _GlassToggleTile(
                                  icon: Icons.workspace_premium,
                                  label: 'Premium',
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
                  // 하단 공유 버튼
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
                                      'SHARE MOMENT',
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
// 글래스 편집 타일
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
// 글래스 토글 타일
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
// 템플릿 시트
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
  final _eventController = TextEditingController(text: '결혼식');

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
              '문장 템플릿',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text('숫자 대신 "문장"을 고르는 경험을 만들어요.'),
            const SizedBox(height: 14),
            const _SectionLabel(text: '관계'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <_ChipSpec<DaylyRelationshipType>>[
                _ChipSpec(DaylyRelationshipType.couple, '커플'),
                _ChipSpec(DaylyRelationshipType.family, '가족'),
                _ChipSpec(DaylyRelationshipType.solo, '혼자'),
                _ChipSpec(DaylyRelationshipType.goal, '목표'),
              ].map((spec) {
                return ChoiceChip(
                  label: Text(spec.label),
                  selected: _relationship == spec.value,
                  onSelected: (_) => setState(() => _relationship = spec.value),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            const _SectionLabel(text: '톤'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <_ChipSpec<DaylyTone>>[
                _ChipSpec(DaylyTone.calm, '담백'),
                _ChipSpec(DaylyTone.flutter, '설렘'),
                _ChipSpec(DaylyTone.longing, '애틋'),
                _ChipSpec(DaylyTone.playful, '장난'),
              ].map((spec) {
                return ChoiceChip(
                  label: Text(spec.label),
                  selected: _tone == spec.value,
                  onSelected: (_) => setState(() => _tone = spec.value),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            const _SectionLabel(text: '표현 방식'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DaylyCountdownMode.values.map((mode) {
                final label = switch (mode) {
                  DaylyCountdownMode.days => '23일',
                  DaylyCountdownMode.dMinus => 'D-23',
                  DaylyCountdownMode.weeksDays => '3주 2일',
                  DaylyCountdownMode.mornings => '42번의 아침',
                  DaylyCountdownMode.nights => '42번의 밤',
                  DaylyCountdownMode.hidden => '숨김',
                };
                return ChoiceChip(
                  label: Text(label),
                  selected: _mode == mode,
                  onSelected: (_) => setState(() => _mode = mode),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            const _SectionLabel(text: '이벤트(선택)'),
            const SizedBox(height: 8),
            TextField(
              controller: _eventController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '예) 결혼식 / 전역 / 시험 / 여행',
              ),
            ),
            const SizedBox(height: 14),
            const _SectionLabel(text: '미리보기'),
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
              child: const Text('이 문장 적용'),
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
