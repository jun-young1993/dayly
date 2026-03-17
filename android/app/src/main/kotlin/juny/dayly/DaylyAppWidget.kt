package juny.dayly

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Bundle
import android.util.Log
import android.widget.RemoteViews
import org.json.JSONObject
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit

enum class WidgetSize { SMALL, MEDIUM, LARGE }

/**
 * dayly 홈화면 위젯 Provider (Small, 2×2).
 *
 * StackView 기반 컬렉션 위젯으로 여러 D-Day 이벤트를 스와이프(fling)하여 탐색할 수 있다.
 * DaylyWidgetRemoteViewsService가 SharedPreferences에서 전체 이벤트 목록을 읽어 제공한다.
 *
 * AlarmManager 생명주기는 [WidgetUpdateManager]에 위임한다.
 * 자정 업데이트: onEnabled() → WidgetUpdateManager.scheduleIfNeeded()
 * 타임존 변경:   ACTION_TIMEZONE_CHANGED → WidgetUpdateManager.updateAll()
 */
open class DaylyAppWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { id ->
            updateWidget(context, appWidgetManager, id)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        updateWidget(context, appWidgetManager, appWidgetId)
    }

    override fun onEnabled(context: Context) {
        WidgetUpdateManager.scheduleIfNeeded(context)
    }

    override fun onDisabled(context: Context) {
        WidgetUpdateManager.cancelIfNone(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            ACTION_MIDNIGHT_UPDATE -> WidgetUpdateManager.onMidnightReceived(context)
            Intent.ACTION_TIMEZONE_CHANGED -> {
                Log.d("DaylyWidget", "timezone changed, refreshing all widgets")
                WidgetUpdateManager.updateAll(context)
            }
        }
    }

    companion object {
        internal const val ACTION_MIDNIGHT_UPDATE = "juny.dayly.MIDNIGHT_UPDATE"
        private const val INSTANCE_PREFS = "dayly_widget_instance"

        // DaylyWidgetConfigActivity 호환용 (레거시)
        fun instancePrefs(context: Context): SharedPreferences =
            context.getSharedPreferences(INSTANCE_PREFS, Context.MODE_PRIVATE)

        fun instanceKey(appWidgetId: Int) = "selected_id_$appWidgetId"

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            forceSize: WidgetSize? = null,
        ) {
            val size = forceSize ?: run {
                val opts = appWidgetManager.getAppWidgetOptions(appWidgetId)
                val maxWidth = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, 0)
                if (maxWidth >= 200) WidgetSize.MEDIUM else WidgetSize.SMALL
            }
            val layoutId = when (size) {
                WidgetSize.LARGE  -> R.layout.dayly_widget_large
                WidgetSize.MEDIUM -> R.layout.dayly_widget_medium
                WidgetSize.SMALL  -> R.layout.dayly_widget_small
            }

            val views = RemoteViews(context.packageName, layoutId)

            // StackView에 RemoteViewsService 연결
            val serviceIntent = Intent(context, DaylyWidgetRemoteViewsService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                putExtra(DaylyWidgetRemoteViewsService.EXTRA_WIDGET_SIZE, size.name)
                // 위젯 인스턴스별 고유 URI — 각 인스턴스가 독립 Factory를 갖도록
                data = Uri.parse("dayly://widget/$appWidgetId/${size.name}")
            }
            views.setRemoteAdapter(R.id.widget_stack, serviceIntent)
            views.setEmptyView(R.id.widget_stack, R.id.widget_empty)

            // EmptyView 탭 → 앱 실행 (D-Day 없을 때 온보딩)
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launchIntent != null) {
                val emptyPendingIntent = PendingIntent.getActivity(
                    context, 0, launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
                views.setOnClickPendingIntent(R.id.widget_empty, emptyPendingIntent)
            }

            // 컬렉션 아이템 클릭 PendingIntent 템플릿
            // FLAG_MUTABLE 필수: fill-in intent가 병합되어야 함
            val clickIntent = Intent(Intent.ACTION_VIEW).apply {
                setPackage(context.packageName)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context, appWidgetId, clickIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE,
            )
            views.setPendingIntentTemplate(R.id.widget_stack, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.widget_stack)
        }

        /**
         * targetDate(yyyy-MM-dd)와 countdownMode, 언어 코드로 실시간 D-Day 텍스트를 계산한다.
         *
         * @param lang ISO 639-1 언어 코드 (ko / ja / en, 기본값 en)
         */
        fun buildCountdownText(
            targetDateIso: String,
            countdownMode: String,
            lang: String = "en",
        ): String {
            if (targetDateIso.isEmpty()) return "–"
            return try {
                val target = LocalDate.parse(targetDateIso, DateTimeFormatter.ISO_LOCAL_DATE)
                val today = LocalDate.now()
                val dayDiff = ChronoUnit.DAYS.between(today, target).toInt()
                val days = Math.abs(dayDiff)
                when (countdownMode) {
                    "days" -> when (lang) {
                        "ko" -> if (dayDiff >= 0) "${days}일 남음" else "${days}일 지남"
                        "ja" -> if (dayDiff >= 0) "あと${days}日" else "${days}日前"
                        else -> if (dayDiff >= 0) "$days days left" else "$days days ago"
                    }
                    "dMinus" -> if (dayDiff == 0) "D-Day" else if (dayDiff > 0) "D-$days" else "D+$days"
                    "weeksDays" -> {
                        val weeks = days / 7
                        val rem = days % 7
                        when (lang) {
                            "ko" -> when {
                                weeks <= 0 -> "${days}일"
                                rem == 0   -> "${weeks}주"
                                else       -> "${weeks}주 ${rem}일"
                            }
                            "ja" -> when {
                                weeks <= 0 -> "${days}日"
                                rem == 0   -> "${weeks}週間"
                                else       -> "${weeks}週間${rem}日"
                            }
                            else -> when {
                                weeks <= 0 -> "$days days"
                                rem == 0   -> "$weeks weeks"
                                else       -> "$weeks weeks $rem days"
                            }
                        }
                    }
                    "mornings" -> when (lang) {
                        "ko" -> "${days}번의 아침"
                        "ja" -> "あと${days}朝"
                        else -> "$days mornings"
                    }
                    "nights" -> when (lang) {
                        "ko" -> "${days}번의 밤"
                        "ja" -> "あと${days}夜"
                        else -> "$days nights"
                    }
                    "hidden" -> ""
                    else -> if (dayDiff == 0) "D-Day" else if (dayDiff > 0) "D-$days" else "D+$days"
                }
            } catch (e: Exception) {
                Log.e("DaylyWidget", "buildCountdownText failed for $targetDateIso", e)
                "–"
            }
        }
    }
}

data class WidgetDisplayData(
    val id: String,
    val sentence: String,
    val countdownText: String,
    val dateLabel: String,
    val themePreset: String = "night",
    val currentIndex: Int = 0,
    val totalCount: Int = 1,
    val isPast: Boolean = false,
    val backgroundImagePath: String? = null,
) {
    companion object {
        fun empty() = WidgetDisplayData("", "dayly", "–", "", "night", 0, 1)

        fun fromJson(obj: JSONObject, index: Int = 0, total: Int = 1): WidgetDisplayData {
            val targetDate = obj.optString("targetDate", "")
            val countdownMode = obj.optString("countdownMode", "dMinus")
            val lang = obj.optString("languageCode", "en")
            val countdownText = if (targetDate.isNotEmpty()) {
                DaylyAppWidget.buildCountdownText(targetDate, countdownMode, lang)
            } else {
                obj.optString("countdownText", "–")
            }
            val isPast = if (targetDate.isNotEmpty()) {
                try {
                    LocalDate.now().isAfter(LocalDate.parse(targetDate, DateTimeFormatter.ISO_LOCAL_DATE))
                } catch (_: Exception) { false }
            } else false
            return WidgetDisplayData(
                id = obj.optString("id", ""),
                sentence = obj.optString("sentence", ""),
                countdownText = countdownText,
                dateLabel = obj.optString("targetDateLabel", ""),
                themePreset = obj.optString("themePreset", "night"),
                currentIndex = index,
                totalCount = total,
                isPast = isPast,
                backgroundImagePath = obj.optString("backgroundImagePath", "").ifEmpty { null },
            )
        }
    }
}
