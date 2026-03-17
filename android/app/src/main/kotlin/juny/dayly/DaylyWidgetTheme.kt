package juny.dayly

import android.graphics.Color

/**
 * Android 위젯 테마 색상 + Drawable 중앙 관리.
 *
 * 사용처:
 *   DaylyWidgetRemoteViewsService  — StackView 아이템 색상 적용
 *   DaylyWidgetConfigActivity      — ConfigActivity 카드 색상 바
 *
 * 테마 추가 시 이 파일만 수정하면 된다.
 */
internal data class WidgetThemeColors(
    val bgDrawable: Int,
    val textColor: Int,
    val subColor: Int,
    val dotColor: Int,
    val watermarkColor: Int,
    val progressFillColor: Int,
    val progressTrackColor: Int,
)

internal fun themeColors(preset: String): WidgetThemeColors = when (preset) {
    "paper" -> WidgetThemeColors(
        bgDrawable = R.drawable.dayly_widget_bg_paper,
        textColor = Color.parseColor("#0B1220"),
        subColor = Color.parseColor("#6B7280"),
        dotColor = Color.parseColor("#9090A8"),
        watermarkColor = Color.parseColor("#C0C8D0"),
        progressFillColor = Color.parseColor("#9B8B78"),
        progressTrackColor = Color.parseColor("#D8CEBC"),
    )
    "fog" -> WidgetThemeColors(
        bgDrawable = R.drawable.dayly_widget_bg_fog,
        textColor = Color.parseColor("#0B1220"),
        subColor = Color.parseColor("#6B7280"),
        dotColor = Color.parseColor("#8090A8"),
        watermarkColor = Color.parseColor("#B8C8D8"),
        progressFillColor = Color.parseColor("#607898"),
        progressTrackColor = Color.parseColor("#C0D0DF"),
    )
    "lavender" -> WidgetThemeColors(
        bgDrawable = R.drawable.dayly_widget_bg_lavender,
        textColor = Color.parseColor("#0B1220"),
        subColor = Color.parseColor("#6B7280"),
        dotColor = Color.parseColor("#9080B0"),
        watermarkColor = Color.parseColor("#C0B8D0"),
        progressFillColor = Color.parseColor("#7868A8"),
        progressTrackColor = Color.parseColor("#C8B8E0"),
    )
    "blush" -> WidgetThemeColors(
        bgDrawable = R.drawable.dayly_widget_bg_blush,
        textColor = Color.parseColor("#0B1220"),
        subColor = Color.parseColor("#6B7280"),
        dotColor = Color.parseColor("#A88090"),
        watermarkColor = Color.parseColor("#D0B8C0"),
        progressFillColor = Color.parseColor("#A87088"),
        progressTrackColor = Color.parseColor("#E0C8D0"),
    )
    else -> WidgetThemeColors( // night (기본)
        bgDrawable = R.drawable.dayly_widget_bg,
        textColor = Color.parseColor("#F4F6FA"),
        subColor = Color.parseColor("#7090B0"),
        dotColor = Color.parseColor("#4060A0"),
        watermarkColor = Color.parseColor("#2A3A5A"),
        progressFillColor = Color.parseColor("#4060A0"),
        progressTrackColor = Color.parseColor("#1A2A4A"),
    )
}
