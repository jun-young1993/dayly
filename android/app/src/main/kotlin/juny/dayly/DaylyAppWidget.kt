package juny.dayly

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit
import java.util.Calendar

/**
 * dayly 홈화면 위젯 Provider.
 *
 * StackView 기반 컬렉션 위젯으로 여러 D-Day 이벤트를 스와이프(fling)하여 탐색할 수 있다.
 * DaylyWidgetRemoteViewsService가 SharedPreferences에서 전체 이벤트 목록을 읽어 제공한다.
 *
 * 자정 업데이트: onEnabled() 시 AlarmManager로 매일 자정 직후 업데이트를 예약한다.
 */
class DaylyAppWidget : AppWidgetProvider() {

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
        scheduleMidnightUpdate(context)
    }

    override fun onDisabled(context: Context) {
        cancelMidnightUpdate(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_MIDNIGHT_UPDATE) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, DaylyAppWidget::class.java)
            )
            if (ids.isNotEmpty()) {
                onUpdate(context, manager, ids)
            }
            scheduleMidnightUpdate(context)
        }
    }

    companion object {
        private const val ACTION_MIDNIGHT_UPDATE = "juny.dayly.MIDNIGHT_UPDATE"
        private const val INSTANCE_PREFS = "dayly_widget_instance"

        // DaylyWidgetConfigActivity 호환용
        fun instancePrefs(context: Context): SharedPreferences =
            context.getSharedPreferences(INSTANCE_PREFS, Context.MODE_PRIVATE)

        fun instanceKey(appWidgetId: Int) = "selected_id_$appWidgetId"

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
        ) {
            val opts = appWidgetManager.getAppWidgetOptions(appWidgetId)
            val maxWidth = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, 0)
            val isMedium = maxWidth >= 200
            val layoutId = if (isMedium) R.layout.dayly_widget_medium
                           else R.layout.dayly_widget_small

            val views = RemoteViews(context.packageName, layoutId)

            // StackView에 RemoteViewsService 연결
            val serviceIntent = Intent(context, DaylyWidgetRemoteViewsService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                putExtra(DaylyWidgetRemoteViewsService.EXTRA_IS_MEDIUM, isMedium)
                // 위젯 인스턴스별 고유 URI — 각 인스턴스가 독립 Factory를 갖도록
                data = Uri.parse("dayly://widget/$appWidgetId/$isMedium")
            }
            views.setRemoteAdapter(R.id.widget_stack, serviceIntent)
            views.setEmptyView(R.id.widget_stack, R.id.widget_empty)

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

        /** targetDate(yyyy-MM-dd)와 countdownMode로 실시간 D-Day 텍스트 계산 */
        fun buildCountdownText(targetDateIso: String, countdownMode: String): String {
            if (targetDateIso.isEmpty()) return "–"
            return try {
                val target = LocalDate.parse(targetDateIso, DateTimeFormatter.ISO_LOCAL_DATE)
                val today = LocalDate.now()
                val dayDiff = ChronoUnit.DAYS.between(today, target).toInt()
                val days = Math.abs(dayDiff)
                when (countdownMode) {
                    "days" -> if (dayDiff >= 0) "$days days left" else "$days days ago"
                    "dMinus" -> if (dayDiff == 0) "D-Day" else if (dayDiff > 0) "D-$days" else "D+$days"
                    "weeksDays" -> {
                        val weeks = days / 7
                        val rem = days % 7
                        when {
                            weeks <= 0 -> "$days days"
                            rem == 0 -> "$weeks weeks"
                            else -> "$weeks weeks $rem days"
                        }
                    }
                    "mornings" -> "$days mornings"
                    "nights" -> "$days nights"
                    "hidden" -> ""
                    else -> if (dayDiff == 0) "D-Day" else if (dayDiff > 0) "D-$days" else "D+$days"
                }
            } catch (_: Exception) {
                "–"
            }
        }

        /** 다음 날 자정 00:00:01에 모든 위젯 업데이트 예약 */
        private fun scheduleMidnightUpdate(context: Context) {
            val midnight = Calendar.getInstance().apply {
                add(Calendar.DAY_OF_YEAR, 1)
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 1)
                set(Calendar.MILLISECOND, 0)
            }
            val pendingIntent = midnightPendingIntent(context)
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            // Android 12+(API 31+): SCHEDULE_EXACT_ALARM 권한이 없으면 setWindow() fallback
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarmManager.canScheduleExactAlarms()) {
                // 자정 ±5분 허용 범위로 근사 예약
                alarmManager.setWindow(
                    AlarmManager.RTC_WAKEUP,
                    midnight.timeInMillis,
                    5 * 60 * 1000L,
                    pendingIntent,
                )
            } else {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    midnight.timeInMillis,
                    pendingIntent,
                )
            }
        }

        private fun cancelMidnightUpdate(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            alarmManager.cancel(midnightPendingIntent(context))
        }

        private fun midnightPendingIntent(context: Context): PendingIntent {
            val intent = Intent(context, DaylyAppWidget::class.java).apply {
                action = ACTION_MIDNIGHT_UPDATE
            }
            return PendingIntent.getBroadcast(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
    }
}

data class WidgetDisplayData(
    val id: String,
    val sentence: String,
    val countdownText: String,
    val dateLabel: String,
) {
    companion object {
        fun empty() = WidgetDisplayData("", "dayly", "–", "")

        fun fromJson(obj: JSONObject): WidgetDisplayData {
            val targetDate = obj.optString("targetDate", "")
            val countdownMode = obj.optString("countdownMode", "dMinus")
            val countdownText = if (targetDate.isNotEmpty()) {
                DaylyAppWidget.buildCountdownText(targetDate, countdownMode)
            } else {
                obj.optString("countdownText", "–")
            }
            return WidgetDisplayData(
                id = obj.optString("id", ""),
                sentence = obj.optString("sentence", ""),
                countdownText = countdownText,
                dateLabel = obj.optString("targetDateLabel", ""),
            )
        }
    }
}
