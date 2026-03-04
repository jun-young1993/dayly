import 'dart:async';
import 'dart:ui';

import 'package:dayly/models/dayly_widget_model.dart';
import 'package:dayly/screens/share_preview_screen_v2.dart';
import 'package:dayly/utils/dayly_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// 이벤트 상세 화면 — 글래스모피즘 다크/라이트 테마
///
/// pop 반환 타입: `_DetailResult`
///   - `(deleted: true,  model: null)`  → WidgetGridScreen에서 삭제
///   - `(deleted: false, model: model)` → WidgetGridScreen에서 업데이트
///   - `null`                           → 변경 없음
typedef _DetailResult = ({bool deleted, DaylyWidgetModel? model});

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({
    super.key,
    required this.model,
    required this.gradient,
    required this.iconData,
  });

  final DaylyWidgetModel model;
  final List<Color> gradient;
  final IconData iconData;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late DaylyWidgetModel _model;
  late Timer _timer;
  Duration _remaining = Duration.zero;

  static const _monthNames = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];

  @override
  void initState() {
    super.initState();
    _model = widget.model;
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final now = DateTime.now();
    final dayDiff = calculateDayDifference(now: now, target: _model.targetDate);
    if (dayDiff <= 0) {
      if (mounted) setState(() => _remaining = Duration.zero);
      return;
    }
    final nowLocal = now.toLocal();
    final targetMidnight = DateTime(
      _model.targetDate.year,
      _model.targetDate.month,
      _model.targetDate.day,
    );
    final remaining = targetMidnight.difference(nowLocal);
    if (mounted) {
      setState(() =>
          _remaining = remaining.isNegative ? Duration.zero : remaining);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // ── 계산 헬퍼 ───────────────────────────────────────────────

  int get _dayDiff =>
      calculateDayDifference(now: DateTime.now(), target: _model.targetDate);

  String get _dDayText {
    final d = _dayDiff;
    if (d == 0) return 'D-Day';
    if (d > 0) return 'D-$d';
    return 'D+${d.abs()}';
  }

  String _formatDate(DateTime date) =>
      '${_monthNames[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';

  String get _timerText {
    if (_dayDiff <= 0) return '00 : 00 : 00';
    final h = _remaining.inHours.toString().padLeft(2, '0');
    final m = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$h : $m : $s';
  }

  double get _milestoneProgress {
    final ms = _model.milestones;
    if (ms.isEmpty) return 0.0;
    return ms.where((m) => m.isDone).length / ms.length;
  }

  // ── 액션 ─────────────────────────────────────────────────────

  void _toggleMilestone(int index) {
    HapticFeedback.selectionClick();
    final ms = List<DaylyMilestone>.of(_model.milestones);
    ms[index] = ms[index].copyWith(isDone: !ms[index].isDone);
    setState(() => _model = _model.copyWith(milestones: ms));
  }

  Future<void> _openEdit() async {
    HapticFeedback.mediumImpact();
    final updated = await Navigator.of(context).push<DaylyWidgetModel>(
      MaterialPageRoute(
        builder: (_) => SharePreviewScreenV2(initialModel: _model),
      ),
    );
    if (updated == null) return;
    setState(() => _model = updated);
  }

  Future<void> _editNote() async {
    HapticFeedback.mediumImpact();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _NoteEditDialog(initialText: _model.note),
    );
    if (result == null) return;
    setState(() => _model = _model.copyWith(note: result));
  }

  void _confirmDelete() {
    HapticFeedback.mediumImpact();
    showDialog<void>(
      context: context,
      builder: (ctx) => _DeleteDialog(
        onConfirm: () {
          Navigator.of(ctx).pop();
          Navigator.of(context)
              .pop<_DetailResult>((deleted: true, model: null));
        },
      ),
    );
  }

  void _popWithResult() {
    Navigator.of(context)
        .pop<_DetailResult>((deleted: false, model: _model));
  }

  // ── 빌드 ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _popWithResult();
      },
      child: Scaffold(
        backgroundColor: cs.surface,
        body: Stack(
          children: <Widget>[
            // 배경 글로우 orb
            Positioned(
              top: -80.h,
              right: -60.w,
              child: _GlowOrb(color: widget.gradient[0], size: 260.w),
            ),
            Positioned(
              bottom: -60.h,
              left: -80.w,
              child: _GlowOrb(color: widget.gradient[1], size: 200.w),
            ),
            SafeArea(
              child: Column(
                children: <Widget>[
                  // 상단 바
                  _TopBar(
                    onBack: _popWithResult,
                    onEdit: _openEdit,
                    onDelete: _confirmDelete,
                  ),
                  // 스크롤 바디
                  Expanded(
                    child: SingleChildScrollView(
                      padding:
                          EdgeInsets.fromLTRB(20.w, 0, 20.w, 32.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          SizedBox(height: 20.h),
                          // 히어로 카드 (D-Day + 타이머)
                          _HeroCard(
                            model: _model,
                            gradient: widget.gradient,
                            iconData: widget.iconData,
                            dDayText: _dDayText,
                            timerText: _timerText,
                            formattedDate: _formatDate(_model.targetDate),
                            dayDiff: _dayDiff,
                          ),
                          SizedBox(height: 16.h),
                          // 마일스톤
                          if (_model.milestones.isNotEmpty) ...<Widget>[
                            _MilestonesCard(
                              milestones: _model.milestones,
                              progress: _milestoneProgress,
                              gradient: widget.gradient,
                              onToggle: _toggleMilestone,
                            ),
                            SizedBox(height: 16.h),
                          ],
                          // 노트
                          _NotesCard(
                            note: _model.note,
                            onTap: _editNote,
                          ),
                          SizedBox(height: 24.h),
                          // EDIT EVENT 버튼
                          _EditEventButton(onTap: _openEdit),
                        ],
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
// 상단 바
// ──────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onBack,
    required this.onEdit,
    required this.onDelete,
  });

  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
      child: Row(
        children: <Widget>[
          _GlassIconBtn(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
          const Spacer(),
          Text(
            'EVENT DETAIL',
            style: GoogleFonts.montserrat(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.54),
              letterSpacing: 2.0,
            ),
          ),
          const Spacer(),
          _GlassIconBtn(
            icon: Icons.delete_outline_rounded,
            onTap: onDelete,
            color: cs.error,
          ),
        ],
      ),
    );
  }
}

class _GlassIconBtn extends StatelessWidget {
  const _GlassIconBtn({
    required this.icon,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.60),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.14)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: Icon(
              icon,
              color: color ?? cs.onSurface.withValues(alpha: 0.70),
              size: 18.sp,
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 히어로 카드 — D-Day 숫자 + 실시간 타이머
// ──────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.model,
    required this.gradient,
    required this.iconData,
    required this.dDayText,
    required this.timerText,
    required this.formattedDate,
    required this.dayDiff,
  });

  final DaylyWidgetModel model;
  final List<Color> gradient;
  final IconData iconData;
  final String dDayText;
  final String timerText;
  final String formattedDate;
  final int dayDiff;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          // 아이콘 박스
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(iconData, color: Colors.white, size: 28.sp),
          ),
          SizedBox(height: 16.h),
          // D-Day 텍스트 (크게)
          Text(
            dDayText,
            style: GoogleFonts.robotoMono(
              fontSize: 52.sp,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
              height: 1.0,
            ),
          ),
          SizedBox(height: 8.h),
          // 이벤트 제목
          Text(
            model.primarySentence,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.9),
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 6.h),
          // 날짜
          Text(
            formattedDate,
            style: GoogleFonts.montserrat(
              fontSize: 11.sp,
              fontWeight: FontWeight.w400,
              color: cs.onSurface.withValues(alpha: 0.38),
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 20.h),
          // 실시간 카운트다운 타이머
          _TimerDisplay(
            timerText: timerText,
            gradient: gradient,
            dayDiff: dayDiff,
          ),
        ],
      ),
    );
  }
}

class _TimerDisplay extends StatelessWidget {
  const _TimerDisplay({
    required this.timerText,
    required this.gradient,
    required this.dayDiff,
  });

  final String timerText;
  final List<Color> gradient;
  final int dayDiff;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[
            gradient[0].withValues(alpha: 0.2),
            gradient[1].withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: gradient[0].withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: Column(
        children: <Widget>[
          Text(
            dayDiff > 0 ? 'COUNTDOWN' : dayDiff == 0 ? 'TODAY' : 'PASSED',
            style: GoogleFonts.montserrat(
              fontSize: 9.sp,
              fontWeight: FontWeight.w600,
              color: gradient[0].withValues(alpha: 0.8),
              letterSpacing: 2.0,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            timerText,
            style: GoogleFonts.robotoMono(
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withValues(alpha: 0.85),
              letterSpacing: 2.0,
            ),
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _TimerLabel(label: 'HRS'),
              SizedBox(width: 28.w),
              _TimerLabel(label: 'MIN'),
              SizedBox(width: 28.w),
              _TimerLabel(label: 'SEC'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimerLabel extends StatelessWidget {
  const _TimerLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      label,
      style: GoogleFonts.montserrat(
        fontSize: 8.sp,
        fontWeight: FontWeight.w400,
        color: cs.onSurface.withValues(alpha: 0.24),
        letterSpacing: 1.0,
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 마일스톤 카드
// ──────────────────────────────────────────────────────────────

class _MilestonesCard extends StatelessWidget {
  const _MilestonesCard({
    required this.milestones,
    required this.progress,
    required this.gradient,
    required this.onToggle,
  });

  final List<DaylyMilestone> milestones;
  final double progress;
  final List<Color> gradient;
  final void Function(int) onToggle;

  static const _monthShort = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];

  String _fmtDue(DateTime? date) {
    if (date == null) return '';
    return '${_monthShort[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 헤더
          Row(
            children: <Widget>[
              Icon(Icons.flag_outlined,
                  color: gradient[0], size: 16.sp),
              SizedBox(width: 8.w),
              Text(
                'MILESTONES',
                style: GoogleFonts.montserrat(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface.withValues(alpha: 0.70),
                  letterSpacing: 1.8,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: GoogleFonts.robotoMono(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: gradient[0],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          // 진행 바
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4.h,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : cs.outlineVariant.withValues(alpha: 0.40),
              valueColor: AlwaysStoppedAnimation<Color>(gradient[0]),
            ),
          ),
          SizedBox(height: 14.h),
          // 항목 목록
          ...milestones.asMap().entries.map((e) {
            final i = e.key;
            final ms = e.value;
            return _MilestoneItem(
              milestone: ms,
              dueText: _fmtDue(ms.dueDate),
              checkColor: gradient[0],
              onTap: () => onToggle(i),
            );
          }),
        ],
      ),
    );
  }
}

class _MilestoneItem extends StatelessWidget {
  const _MilestoneItem({
    required this.milestone,
    required this.dueText,
    required this.checkColor,
    required this.onTap,
  });

  final DaylyMilestone milestone;
  final String dueText;
  final Color checkColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 7.h),
        child: Row(
          children: <Widget>[
            // 체크박스
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22.w,
              height: 22.w,
              decoration: BoxDecoration(
                color: milestone.isDone
                    ? checkColor.withValues(alpha: 0.9)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(
                  color: milestone.isDone
                      ? checkColor
                      : cs.outlineVariant,
                  width: 1.5,
                ),
              ),
              child: milestone.isDone
                  ? Icon(Icons.check_rounded,
                      color: Colors.white, size: 14.sp)
                  : null,
            ),
            SizedBox(width: 12.w),
            // 제목
            Expanded(
              child: Text(
                milestone.title,
                style: GoogleFonts.montserrat(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: milestone.isDone
                      ? cs.onSurface.withValues(alpha: 0.38)
                      : cs.onSurface.withValues(alpha: 0.85),
                  decoration: milestone.isDone
                      ? TextDecoration.lineThrough
                      : null,
                  decorationColor: cs.onSurface.withValues(alpha: 0.38),
                ),
              ),
            ),
            // 마감일
            if (dueText.isNotEmpty)
              Text(
                dueText,
                style: GoogleFonts.robotoMono(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w400,
                  color: cs.onSurface.withValues(alpha: 0.30),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 노트 카드
// ──────────────────────────────────────────────────────────────

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.note, required this.onTap});
  final String note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: _GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.edit_note_outlined,
                    color: cs.onSurfaceVariant, size: 16.sp),
                SizedBox(width: 8.w),
                Text(
                  'NOTES',
                  style: GoogleFonts.montserrat(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface.withValues(alpha: 0.70),
                    letterSpacing: 1.8,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              note.isEmpty ? 'Tap to add a note.' : note,
              style: GoogleFonts.montserrat(
                fontSize: 13.sp,
                fontWeight: FontWeight.w400,
                color: note.isEmpty
                    ? cs.onSurface.withValues(alpha: 0.24)
                    : cs.onSurface.withValues(alpha: 0.70),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// EDIT EVENT 버튼
// ──────────────────────────────────────────────────────────────

class _EditEventButton extends StatelessWidget {
  const _EditEventButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 52.h,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.white.withValues(alpha: 0.60),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.20)
                    : Colors.black.withValues(alpha: 0.08),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.edit_outlined,
                    color: cs.onSurface.withValues(alpha: 0.70), size: 18.sp),
                SizedBox(width: 8.w),
                Text(
                  'EDIT EVENT',
                  style: GoogleFonts.montserrat(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface.withValues(alpha: 0.70),
                    letterSpacing: 2.0,
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
// 노트 편집 다이얼로그
// ──────────────────────────────────────────────────────────────

class _NoteEditDialog extends StatefulWidget {
  const _NoteEditDialog({required this.initialText});
  final String initialText;

  @override
  State<_NoteEditDialog> createState() => _NoteEditDialogState();
}

class _NoteEditDialogState extends State<_NoteEditDialog> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.edit_note_outlined,
                    color: cs.onSurfaceVariant, size: 28.sp),
                SizedBox(height: 14.h),
                Text(
                  'Edit Note',
                  style: GoogleFonts.montserrat(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: controller,
                  maxLines: 5,
                  minLines: 3,
                  autofocus: true,
                  style: GoogleFonts.montserrat(
                    fontSize: 13.sp,
                    color: cs.onSurface.withValues(alpha: 0.85),
                    height: 1.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Write your note here...',
                    hintStyle: GoogleFonts.montserrat(
                      fontSize: 13.sp,
                      color: cs.onSurface.withValues(alpha: 0.24),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : cs.surface,
                    contentPadding: EdgeInsets.all(14.w),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: cs.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: cs.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: cs.primary),
                    ),
                  ),
                  cursorColor: cs.primary,
                ),
                SizedBox(height: 20.h),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          height: 44.h,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : cs.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: cs.outlineVariant),
                          ),
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.montserrat(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface.withValues(alpha: 0.60),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            Navigator.of(context).pop(controller.text),
                        child: Container(
                          height: 44.h,
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: cs.primary.withValues(alpha: 0.40),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Save',
                              style: GoogleFonts.montserrat(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: cs.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
// 삭제 확인 다이얼로그
// ──────────────────────────────────────────────────────────────

class _DeleteDialog extends StatelessWidget {
  const _DeleteDialog({required this.onConfirm});
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.delete_forever_outlined,
                    color: cs.error, size: 36.sp),
                SizedBox(height: 14.h),
                Text(
                  '이벤트를 삭제할까요?',
                  style: GoogleFonts.montserrat(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '삭제한 이벤트는 복구할 수 없습니다.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 12.sp,
                    color: cs.onSurface.withValues(alpha: 0.38),
                  ),
                ),
                SizedBox(height: 24.h),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          height: 44.h,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : cs.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: cs.outlineVariant),
                          ),
                          child: Center(
                            child: Text(
                              '취소',
                              style: GoogleFonts.montserrat(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface.withValues(alpha: 0.60),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: GestureDetector(
                        onTap: onConfirm,
                        child: Container(
                          height: 44.h,
                          decoration: BoxDecoration(
                            color: cs.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: cs.error.withValues(alpha: 0.50),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '삭제',
                              style: GoogleFonts.montserrat(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: cs.error,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
// 공통 글래스 카드
// ──────────────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? <Color>[
                  Colors.white.withValues(alpha: 0.16),
                  Colors.white.withValues(alpha: 0.04),
                ]
              : <Color>[
                  Colors.white.withValues(alpha: 0.80),
                  Colors.white.withValues(alpha: 0.20),
                ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(1.0.w),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white.withValues(alpha: 0.60),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 글로우 Orb
// ──────────────────────────────────────────────────────────────

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[
            color.withValues(alpha: isDark ? 0.12 : 0.08),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
