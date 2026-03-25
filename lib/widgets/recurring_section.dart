import 'package:dayly/utils/dayly_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_ui_kit_l10n/flutter_ui_kit_l10n.dart';
import 'package:google_fonts/google_fonts.dart';

/// 반복 타입(없음 / 매년 / 매월) 선택 섹션.
///
/// [add_widget_bottom_sheet.dart]와 [share_preview_screen_v2.dart] 모두에서 재사용.
class RecurringSection extends StatelessWidget {
  const RecurringSection({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final DaylyRecurringType? selected;
  final ValueChanged<DaylyRecurringType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = UiKitLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.custom((locale) => switch (locale.languageCode) {
                'ko' => '반복',
                'ja' => '繰り返し',
                _ => 'Repeat',
              }),
          style: GoogleFonts.montserrat(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: cs.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        SizedBox(height: 8.h),
        SegmentedButton<DaylyRecurringType?>(
          style: ButtonStyle(
            textStyle: WidgetStateProperty.all(
              GoogleFonts.montserrat(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          segments: <ButtonSegment<DaylyRecurringType?>>[
            ButtonSegment<DaylyRecurringType?>(
              value: null,
              label: Text(l10n.custom((locale) => switch (locale.languageCode) {
                    'ko' => '없음',
                    'ja' => 'なし',
                    _ => 'None',
                  })),
            ),
            ButtonSegment<DaylyRecurringType?>(
              value: DaylyRecurringType.annual,
              label: Text(l10n.custom((locale) => switch (locale.languageCode) {
                    'ko' => '매년',
                    'ja' => '毎年',
                    _ => 'Yearly',
                  })),
            ),
            ButtonSegment<DaylyRecurringType?>(
              value: DaylyRecurringType.monthly,
              label: Text(l10n.custom((locale) => switch (locale.languageCode) {
                    'ko' => '매월',
                    'ja' => '毎月',
                    _ => 'Monthly',
                  })),
            ),
          ],
          selected: <DaylyRecurringType?>{selected},
          onSelectionChanged: (v) => onChanged(v.first),
        ),
        if (selected != null)
          Padding(
            padding: EdgeInsets.only(top: 6.h),
            child: Text(
              selected == DaylyRecurringType.annual
                  ? l10n.custom((locale) => switch (locale.languageCode) {
                        'ko' => '날짜가 지나면 자동으로 다음 해로 갱신됩니다.',
                        'ja' => '日付が過ぎると自動的に翌年に更新されます。',
                        _ => 'Auto-advances to the same date next year.',
                      })
                  : l10n.custom((locale) => switch (locale.languageCode) {
                        'ko' => '날짜가 지나면 자동으로 다음 달로 갱신됩니다.',
                        'ja' => '日付が過ぎると自動的に翌月に更新されます。',
                        _ => 'Auto-advances to the same date next month.',
                      }),
              style: GoogleFonts.montserrat(
                fontSize: 11.sp,
                color: cs.onSurfaceVariant.withValues(alpha: 0.70),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }
}
