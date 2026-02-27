import 'dart:async';
import 'dart:ui';

import 'package:dayly/models/dayly_widget_model.dart';
import 'package:dayly/screens/add_widget_bottom_sheet.dart';
import 'package:dayly/screens/event_detail_screen.dart';
import 'package:dayly/storage/dayly_widget_storage.dart';
import 'package:dayly/utils/dayly_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// 글래스모피즘 다크 대시보드 — "YOUR MOMENTS" 리스트/그리드 뷰.
///
/// 특징:
/// - 천천히 흐르는 애니메이션 배경 그라데이션
/// - 모바일: 1열 리스트 / 태블릿(≥600dp): 2열 그리드 자동 전환
/// - 카드 탭 시 HapticFeedback.lightImpact()
/// - 모든 수치 flutter_screenutil (.sp / .w / .h / .r) 적용
class WidgetGridScreen extends StatefulWidget {
  const WidgetGridScreen({super.key});

  @override
  State<WidgetGridScreen> createState() => _WidgetGridScreenState();
}

class _WidgetGridScreenState extends State<WidgetGridScreen> {
  var _isLoading = true;
  List<DaylyWidgetModel> _widgets = const <DaylyWidgetModel>[];

  static const _iconData = <IconData>[
    Icons.cake_outlined,
    Icons.flight_outlined,
    Icons.edit_note_outlined,
    Icons.favorite_outline,
    Icons.star_outline,
    Icons.celebration_outlined,
    Icons.school_outlined,
    Icons.music_note_outlined,
  ];

  static const _gradients = <List<Color>>[
    <Color>[Color(0xFF6C63FF), Color(0xFF9B8FFF)],
    <Color>[Color(0xFF4ECDC4), Color(0xFF44A08D)],
    <Color>[Color(0xFFFF6B6B), Color(0xFFFF8E53)],
    <Color>[Color(0xFFFFD93D), Color(0xFFFFC107)],
    <Color>[Color(0xFF74B9FF), Color(0xFF0984E3)],
    <Color>[Color(0xFF55EFC4), Color(0xFF00B894)],
    <Color>[Color(0xFFFF9FF3), Color(0xFFF368E0)],
    <Color>[Color(0xFFFECB74), Color(0xFFFFA502)],
  ];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    debugPrint('[dayly] _load() start');
    final loaded = await loadDaylyWidgets();
    debugPrint('[dayly] _load() loaded ${loaded.length} widgets');
    if (!mounted) return;
    setState(() {
      _widgets = loaded.isEmpty
          ? <DaylyWidgetModel>[DaylyWidgetModel.defaults()]
          : List<DaylyWidgetModel>.of(loaded);
      _isLoading = false;
    });
    debugPrint('[dayly] _load() done, _isLoading=$_isLoading');
  }

  Future<void> _persist() async => saveDaylyWidgets(_widgets);

  Future<void> _openDetail(int index) async {
    HapticFeedback.lightImpact();
    final result =
        await Navigator.of(context).push<({bool deleted, DaylyWidgetModel? model})>(
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(
          model: _widgets[index],
          gradient: _gradients[index % _gradients.length],
          iconData: _iconData[index % _iconData.length],
        ),
      ),
    );
    if (result == null) return;
    if (result.deleted) {
      setState(() => _widgets.removeAt(index));
    } else if (result.model != null) {
      setState(() => _widgets[index] = result.model!);
    }
    unawaited(_persist());
  }

  Future<void> _openAddWidgetSheet() async {
    HapticFeedback.mediumImpact();
    final created = await showAddWidgetBottomSheet(context: context);
    if (created == null) return;
    setState(() => _widgets.add(created));
    unawaited(_persist());
  }

  bool get _isTablet => MediaQuery.of(context).size.width >= 600;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: _AnimatedGradientBackground(
        child: Stack(
          children: <Widget>[
            // 장식 빛 — 우상단
            Positioned(
              top: -100.h,
              right: -80.w,
              child: _GlowCircle(
                size: 280.w,
                color: const Color(0xFF6C63FF),
                opacity: 0.10,
              ),
            ),
            // 장식 빛 — 좌하단
            Positioned(
              bottom: -60.h,
              left: -40.w,
              child: _GlowCircle(
                size: 200.w,
                color: const Color(0xFF4ECDC4),
                opacity: 0.07,
              ),
            ),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildHeader(),
                  Expanded(
                    child: _isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: Colors.white70,
                              strokeWidth: 2.0.w,
                            ),
                          )
                        : _widgets.isEmpty
                            ? _buildEmptyState()
                            : _isTablet
                                ? _buildTabletGrid()
                                : _buildMobileList(),
                  ),
                ],
              ),
            ),
            // 반투명 글래스 FAB
            Positioned(
              bottom: 28.h,
              right: 24.w,
              child: _GlassFab(onTap: _openAddWidgetSheet),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'YOUR MOMENTS',
            style: GoogleFonts.montserrat(
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 3.5,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            '${_widgets.length} event${_widgets.length == 1 ? '' : 's'}',
            style: GoogleFonts.montserrat(
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: Colors.white38,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  // 모바일: 1열 리스트
  Widget _buildMobileList() {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 100.h),
      itemCount: _widgets.length,
      itemBuilder: (context, index) => _GlassmorphicCard(
        model: _widgets[index],
        gradient: _gradients[index % _gradients.length],
        iconData: _iconData[index % _iconData.length],
        onTap: () => _openDetail(index),
      ),
    );
  }

  // 태블릿: 2열 그리드
  Widget _buildTabletGrid() {
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 100.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 3.2,
      ),
      itemCount: _widgets.length,
      itemBuilder: (context, index) => _GlassmorphicCard(
        model: _widgets[index],
        gradient: _gradients[index % _gradients.length],
        iconData: _iconData[index % _iconData.length],
        onTap: () => _openDetail(index),
        isTablet: true,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.add_circle_outline, color: Colors.white12, size: 48.sp),
          SizedBox(height: 12.h),
          Text(
            '+ 버튼으로 첫 D-Day를 추가하세요',
            style: GoogleFonts.montserrat(
              color: Colors.white24,
              fontSize: 13.sp,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 천천히 흐르는 애니메이션 배경 그라데이션 (8초 주기 왕복)
// ──────────────────────────────────────────────────────────────

class _AnimatedGradientBackground extends StatefulWidget {
  const _AnimatedGradientBackground({required this.child});

  final Widget child;

  @override
  State<_AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState
    extends State<_AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, animChild) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color.lerp(
                const Color(0xFF0D1F3C),
                const Color(0xFF12103A),
                _ctrl.value,
              )!,
              Color.lerp(
                const Color(0xFF0A0E1A),
                const Color(0xFF0A1422),
                _ctrl.value,
              )!,
            ],
          ),
        ),
        child: animChild,
      ),
      child: widget.child,
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 글래스모피즘 카드 (Edge Light 0.5px 테두리 효과 포함)
// ──────────────────────────────────────────────────────────────

class _GlassmorphicCard extends StatelessWidget {
  const _GlassmorphicCard({
    required this.model,
    required this.gradient,
    required this.iconData,
    required this.onTap,
    this.isTablet = false,
  });

  final DaylyWidgetModel model;
  final List<Color> gradient;
  final IconData iconData;
  final VoidCallback onTap;
  final bool isTablet;

  String _formatDDay(int dayDiff) {
    if (dayDiff == 0) return 'D-Day';
    if (dayDiff > 0) return 'D-$dayDiff';
    return 'D+${dayDiff.abs()}';
  }

  String _formatDate(DateTime date) =>
      '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final dayDiff = calculateDayDifference(
      now: DateTime.now(),
      target: model.targetDate,
    );
    final dDayText = _formatDDay(dayDiff);
    final isPast = dayDiff < 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: isTablet ? EdgeInsets.zero : EdgeInsets.only(bottom: 12.h),
        // Edge light: 그라데이션 테두리 (0.5px 초박형)
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Colors.white.withValues(alpha: 0.18),
              Colors.white.withValues(alpha: 0.04),
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(0.8.w),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 14.h,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  children: <Widget>[
                    // 아이콘 박스 (파스텔 그라데이션)
                    Container(
                      width: 52.w,
                      height: 52.w,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradient,
                        ),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Icon(iconData, color: Colors.white, size: 24.sp),
                    ),
                    SizedBox(width: 14.w),
                    // 제목 + 날짜 (좌측 정렬)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            model.primarySentence,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.92),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            _formatDate(model.targetDate),
                            style: GoogleFonts.montserrat(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.white38,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // D-Day 배지 (우측 정렬)
                    Text(
                      dDayText,
                      style: GoogleFonts.robotoMono(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: isPast
                            ? Colors.white30
                            : Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 반투명 글래스 FAB
// ──────────────────────────────────────────────────────────────

class _GlassFab extends StatelessWidget {
  const _GlassFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.0,
              ),
            ),
            child: Icon(Icons.add, color: Colors.white, size: 26.sp),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// 장식 글로우 서클
// ──────────────────────────────────────────────────────────────

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[
            color.withValues(alpha: opacity),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
