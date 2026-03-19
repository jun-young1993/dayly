import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:dayly/models/dayly_widget_model.dart';
import 'package:dayly/screens/share_preview_screen_v2.dart';
import 'package:dayly/utils/dayly_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_ui_kit_l10n/flutter_ui_kit_l10n.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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
    this.onWidgetChanged,
  });

  final DaylyWidgetModel model;
  final List<Color> gradient;
  final IconData iconData;
  final void Function(DaylyWidgetModel)? onWidgetChanged;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen>
    with WidgetsBindingObserver {
  late DaylyWidgetModel _model;
  late Timer _timer;
  Duration _remaining = Duration.zero;
  String? _backgroundImagePath;   // 상대 경로 (backgrounds/bg_xxx.jpg)
  String? _resolvedImagePath;     // 런타임 절대 경로

  static const _monthNames = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _model = widget.model;
    _backgroundImagePath = widget.model.backgroundImagePath;
    _resolveImagePath();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  Future<void> _resolveImagePath() async {
    if (_backgroundImagePath == null) {
      setState(() => _resolvedImagePath = null);
      return;
    }
    // 기존 절대 경로로 저장된 경우 호환 처리
    if (p.isAbsolute(_backgroundImagePath!)) {
      if (await File(_backgroundImagePath!).exists()) {
        setState(() => _resolvedImagePath = _backgroundImagePath);
        return;
      }
      // 절대 경로인데 파일이 없으면 무효
      setState(() {
        _resolvedImagePath = null;
        _backgroundImagePath = null;
      });
      return;
    }
    final appDir = await getApplicationDocumentsDirectory();
    final absPath = '${appDir.path}/$_backgroundImagePath';
    if (await File(absPath).exists()) {
      setState(() => _resolvedImagePath = absPath);
    } else {
      setState(() {
        _resolvedImagePath = null;
        _backgroundImagePath = null;
      });
    }
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
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _notifyChanged();
    }
  }

  void _notifyChanged() {
    widget.onWidgetChanged?.call(
      _model.copyWith(backgroundImagePath: _backgroundImagePath),
    );
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
    _notifyChanged();
  }

  void _deleteMilestone(int index) {
    HapticFeedback.mediumImpact();
    final ms = List<DaylyMilestone>.of(_model.milestones);
    ms.removeAt(index);
    setState(() => _model = _model.copyWith(milestones: ms));
    _notifyChanged();
  }

  Future<void> _addMilestone() async {
    HapticFeedback.mediumImpact();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _MilestoneAddDialog(),
    );
    if (result == null || result.trim().isEmpty) return;
    final ms = List<DaylyMilestone>.of(_model.milestones);
    ms.add(DaylyMilestone(title: result.trim()));
    setState(() => _model = _model.copyWith(milestones: ms));
    _notifyChanged();
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
    _notifyChanged();
  }

  Future<void> _openShare() async {
    HapticFeedback.mediumImpact();
    final updated = await Navigator.of(context).push<DaylyWidgetModel>(
      MaterialPageRoute(
        builder: (_) => SharePreviewScreenV2(initialModel: _model),
      ),
    );
    if (updated != null) {
      setState(() => _model = updated);
      _notifyChanged();
    }
  }

  Future<void> _editNote() async {
    HapticFeedback.mediumImpact();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _NoteEditDialog(initialText: _model.note),
    );
    if (result == null) return;
    setState(() => _model = _model.copyWith(note: result));
    _notifyChanged();
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
    final modelToReturn = _model.copyWith(
      backgroundImagePath: _backgroundImagePath,
    );
    Navigator.of(context)
        .pop<_DetailResult>((deleted: false, model: modelToReturn));
  }

  Future<void> _pickBackgroundImage() async {
    if (_resolvedImagePath != null) {
      // 이미 사진이 있으면 변경/제거 선택
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _PhotoActionSheet(
          onChangeTap: () async {
            Navigator.of(ctx).pop();
            await _selectImageFromGallery();
          },
          onRemoveTap: () {
            Navigator.of(ctx).pop();
            setState(() {
              _backgroundImagePath = null;
              _resolvedImagePath = null;
            });
            _notifyChanged();
          },
        ),
      );
    } else {
      await _selectImageFromGallery();
    }
  }

  Future<void> _selectImageFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (picked == null) return;

    // 임시 파일을 앱 문서 디렉토리로 복사 (앱 재시작 후에도 유지)
    final appDir = await getApplicationDocumentsDirectory();
    final bgDir = Directory('${appDir.path}/backgrounds');
    if (!bgDir.existsSync()) bgDir.createSync(recursive: true);
    final ext = p.extension(picked.path);
    final fileName = 'bg_${DateTime.now().millisecondsSinceEpoch}$ext';
    final relativePath = 'backgrounds/$fileName';
    await File(picked.path).copy('${appDir.path}/$relativePath');

    setState(() {
      _backgroundImagePath = relativePath;
      _resolvedImagePath = '${appDir.path}/$relativePath';
    });
    _notifyChanged();
  }

  // ── 빌드 ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasPhoto = _resolvedImagePath != null;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _popWithResult();
      },
      child: Scaffold(
        backgroundColor: cs.surface,
        body: Stack(
          children: <Widget>[
            // 사용자 배경 사진
            if (hasPhoto) ...<Widget>[
              Positioned.fill(
                child: Image.file(
                  File(_resolvedImagePath!),
                  fit: BoxFit.cover,
                ),
              ),
              // 가독성 오버레이: 위쪽 진하게 → 중간 → 아래쪽 더 진하게
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Color(0x88000000), // 상단 53%
                        Color(0x33000000), // 중단 20%
                        Color(0x99000000), // 하단 60%
                      ],
                      stops: <double>[0.0, 0.40, 1.0],
                    ),
                  ),
                ),
              ),
            ],
            // 배경 글로우 orb (사진 없을 때만 표시)
            if (!hasPhoto) ...<Widget>[
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
            ],
            SafeArea(
              child: Column(
                children: <Widget>[
                  // 상단 바
                  _TopBar(
                    onBack: _popWithResult,
                    onEdit: _openEdit,
                    onDelete: _confirmDelete,
                    onPhoto: _pickBackgroundImage,
                    hasBackgroundImage: hasPhoto,
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
                          // 히어로 카드 (D-Day + 진행률 + 타이머)
                          _HeroCard(
                            model: _model,
                            gradient: widget.gradient,
                            iconData: widget.iconData,
                            dDayText: _dDayText,
                            timerText: _timerText,
                            formattedDate: _formatDate(_model.targetDate),
                            dayDiff: _dayDiff,
                            hasPhoto: hasPhoto,
                          ),
                          SizedBox(height: 16.h),
                          // 마일스톤
                          _MilestonesCard(
                            milestones: _model.milestones,
                            progress: _milestoneProgress,
                            gradient: widget.gradient,
                            onToggle: _toggleMilestone,
                            onDelete: _deleteMilestone,
                            onAdd: _addMilestone,
                            hasPhoto: hasPhoto,
                          ),
                          SizedBox(height: 16.h),
                          // 노트
                          _NotesCard(
                            note: _model.note,
                            onTap: _editNote,
                            hasPhoto: hasPhoto,
                          ),
                          SizedBox(height: 24.h),
                          // EDIT EVENT + SHARE 버튼
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _EditEventButton(onTap: _openEdit),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: _ShareButton(
                                  onTap: _openShare,
                                  gradient: widget.gradient,
                                ),
                              ),
                            ],
                          ),
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
    required this.onPhoto,
    required this.hasBackgroundImage,
  });

  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPhoto;
  final bool hasBackgroundImage;

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
            icon: hasBackgroundImage
                ? Icons.wallpaper_rounded
                : Icons.add_photo_alternate_outlined,
            onTap: onPhoto,
            color: hasBackgroundImage ? cs.primary : null,
          ),
          SizedBox(width: 8.w),
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
    this.hasPhoto = false,
  });

  final DaylyWidgetModel model;
  final List<Color> gradient;
  final IconData iconData;
  final String dDayText;
  final String timerText;
  final String formattedDate;
  final int dayDiff;
  final bool hasPhoto;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _GlassCard(
      hasPhoto: hasPhoto,
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
          SizedBox(height: 16.h),
          // 진행률 바 — 미래 이벤트(D-Day 이전)에서만 표시
          if (dayDiff > 0) ...<Widget>[
            _ProgressSection(
              progress: model.progress,
              gradient: gradient,
              isDark: isDark,
              cs: cs,
            ),
            SizedBox(height: 12.h),
          ],
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

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({
    required this.progress,
    required this.gradient,
    required this.isDark,
    required this.cs,
  });

  final double progress;
  final List<Color> gradient;
  final bool isDark;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'PROGRESS',
                style: GoogleFonts.montserrat(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w600,
                  color: gradient[0].withValues(alpha: 0.8),
                  letterSpacing: 2.0,
                ),
              ),
              Text(
                '$pct%',
                style: GoogleFonts.robotoMono(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: gradient[0],
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5.h,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : cs.outlineVariant.withValues(alpha: 0.40),
              valueColor: AlwaysStoppedAnimation<Color>(gradient[0]),
            ),
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
    required this.onDelete,
    required this.onAdd,
    this.hasPhoto = false,
  });

  final List<DaylyMilestone> milestones;
  final double progress;
  final List<Color> gradient;
  final void Function(int) onToggle;
  final void Function(int) onDelete;
  final VoidCallback onAdd;
  final bool hasPhoto;

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
      hasPhoto: hasPhoto,
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
              if (milestones.isNotEmpty)
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
          if (milestones.isNotEmpty) ...<Widget>[
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
                onDelete: () => onDelete(i),
              );
            }),
          ],
          SizedBox(height: 10.h),
          // 추가 버튼
          GestureDetector(
            onTap: onAdd,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 22.w,
                    height: 22.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(
                        color: gradient[0].withValues(alpha: 0.4),
                        width: 1.5,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                    child: Icon(Icons.add_rounded,
                        color: gradient[0].withValues(alpha: 0.6), size: 14.sp),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Add milestone',
                    style: GoogleFonts.montserrat(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface.withValues(alpha: 0.38),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
    required this.onDelete,
  });

  final DaylyMilestone milestone;
  final String dueText;
  final Color checkColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 7.h),
      child: Row(
        children: <Widget>[
          // 체크박스
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
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
          ),
          SizedBox(width: 12.w),
          // 제목
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
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
          SizedBox(width: 8.w),
          // 삭제 버튼
          GestureDetector(
            onTap: onDelete,
            behavior: HitTestBehavior.opaque,
            child: Icon(
              Icons.close_rounded,
              size: 14.sp,
              color: cs.onSurface.withValues(alpha: 0.24),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 노트 카드
// ──────────────────────────────────────────────────────────────

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.note, required this.onTap, this.hasPhoto = false});
  final String note;
  final VoidCallback onTap;
  final bool hasPhoto;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: _GlassCard(
        hasPhoto: hasPhoto,
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
// Share 버튼
// ──────────────────────────────────────────────────────────────

class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.onTap, required this.gradient});
  final VoidCallback onTap;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 52.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: <Color>[
                  gradient[0].withValues(alpha: isDark ? 0.25 : 0.15),
                  gradient[1].withValues(alpha: isDark ? 0.15 : 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: gradient[0].withValues(alpha: 0.35),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.share_outlined,
                    color: gradient[0], size: 18.sp),
                SizedBox(width: 8.w),
                Text(
                  'SHARE',
                  style: GoogleFonts.montserrat(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: gradient[0],
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
// 마일스톤 추가 다이얼로그
// ──────────────────────────────────────────────────────────────

class _MilestoneAddDialog extends StatefulWidget {
  @override
  State<_MilestoneAddDialog> createState() => _MilestoneAddDialogState();
}

class _MilestoneAddDialogState extends State<_MilestoneAddDialog> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
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
                Icon(Icons.flag_outlined,
                    color: cs.onSurfaceVariant, size: 28.sp),
                SizedBox(height: 14.h),
                Text(
                  'Add Milestone',
                  style: GoogleFonts.montserrat(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: controller,
                  maxLines: 1,
                  autofocus: true,
                  style: GoogleFonts.montserrat(
                    fontSize: 13.sp,
                    color: cs.onSurface.withValues(alpha: 0.85),
                    height: 1.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. Book flights',
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
                  onSubmitted: (text) {
                    if (text.trim().isNotEmpty) {
                      Navigator.of(context).pop(text);
                    }
                  },
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
                              'Add',
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
    final l10n = UiKitLocalizations.of(context);
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
                  l10n.custom((locale) => switch(locale.languageCode) {
                    'ko' => '이벤트를 삭제할까요?',
                    'ja' => 'このイベントを削除しますか？',
                    _ => 'Do you want to delete this event?'
                  }),
                  style: GoogleFonts.montserrat(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                    l10n.custom((locale) => switch(locale.languageCode) {
                      'ko' => '삭제한 이벤트는 복구할 수 없습니다.',
                      'ja' => '削除したイベントは復元できません。',
                      _ => 'Deleted events cannot be restored.'
                    }),
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
                              l10n.cancel,
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
                              l10n.delete,
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
  const _GlassCard({required this.child, this.hasPhoto = false});
  final Widget child;
  final bool hasPhoto;

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
                  Colors.white.withValues(alpha: hasPhoto ? 0.05: 0.16),
                  Colors.white.withValues(alpha: hasPhoto ? 0.02 : 0.04),
                ]
              : <Color>[
                  Colors.white.withValues(alpha: hasPhoto ? 0.50 : 0.80),
                  Colors.white.withValues(alpha: hasPhoto ? 0.10 : 0.20),
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
                    ? Colors.white.withValues(alpha: hasPhoto ? 0.03 : 0.06)
                    : Colors.white.withValues(alpha: hasPhoto ? 0.35 : 0.60),
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
// 사진 배경 액션 시트
// ──────────────────────────────────────────────────────────────

class _PhotoActionSheet extends StatelessWidget {
  const _PhotoActionSheet({
    required this.onChangeTap,
    required this.onRemoveTap,
  });

  final VoidCallback onChangeTap;
  final VoidCallback onRemoveTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final l10n = UiKitLocalizations.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.75)
                : Colors.white.withValues(alpha: 0.90),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 36.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 20.h),
              _SheetOption(
                icon: Icons.photo_library_outlined,
                label: l10n.custom((locale) => switch(locale.languageCode) {
                  'ko' => '배경 변경',
                  'ja' => '背景を変更',
                  _ => 'Change Background'
                }),
                color: cs.onSurface,
                onTap: onChangeTap,
              ),
              SizedBox(height: 10.h),
              _SheetOption(
                icon: Icons.hide_image_outlined,
                label: l10n.custom((locale) => switch(locale.languageCode) {
                  'ko' => '배경 제거',
                  'ja' => '背景を削除',
                  _ => 'Remove Background'
                }),
                color: cs.error,
                onTap: onRemoveTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: color, size: 20.sp),
            SizedBox(width: 12.w),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
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
