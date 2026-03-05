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
 * home_widget 패키지가 저장한 SharedPreferences 값을 읽어 RemoteViews를 업데이트한다.
 * targetDate + countdownMode를 사용해 업데이트 시점마다 D-Day를 실시간 재계산한다.
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

    override fun onEnabled(context: Context) {
        scheduleMidnightUpdate(context)
    }

    override fun onDisabled(context: Context) {
        cancelMidnightUpdate(context)
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        val prefs = instancePrefs(context)
        val editor = prefs.edit()
        appWidgetIds.forEach { id ->
            editor.remove(instanceKey(id))
        }
        editor.apply()
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
        private const val HW_PREFS = "HomeWidgetPreferences"
        private const val KEY_WIDGETS_JSON = "dayly_widgets_json"
        private const val KEY_SELECTED_ID = "dayly_selected_widget_id"
        private const val INSTANCE_PREFS = "dayly_widget_instance"
        private const val ACTION_MIDNIGHT_UPDATE = "juny.dayly.MIDNIGHT_UPDATE"

        fun instancePrefs(context: Context): SharedPreferences =
            context.getSharedPreferences(INSTANCE_PREFS, Context.MODE_PRIVATE)

        fun instanceKey(appWidgetId: Int) = "selected_id_$appWidgetId"

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
        ) {
            val hwPrefs = context.getSharedPreferences(HW_PREFS, Context.MODE_PRIVATE)
            val instPrefs = instancePrefs(context)

            val widgetsJson = hwPrefs.getString(KEY_WIDGETS_JSON, null)
            val fallbackId = hwPrefs.getString(KEY_SELECTED_ID, null)
            val selectedId = instPrefs.getString(instanceKey(appWidgetId), fallbackId)

            val data = resolveData(widgetsJson, selectedId)

            val opts = appWidgetManager.getAppWidgetOptions(appWidgetId)
            val maxWidth = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, 0)
            val layoutId = if (maxWidth >= 200) R.layout.dayly_widget_medium
                           else R.layout.dayly_widget_small

            val views = RemoteViews(context.packageName, layoutId)
            views.setTextViewText(R.id.widget_countdown, data.countdownText)
            views.setTextViewText(R.id.widget_sentence, data.sentence)
            if (layoutId == R.layout.dayly_widget_medium) {
                views.setTextViewText(R.id.widget_date_label, data.dateLabel)
            }

            val deepLink = if (data.id.isNotEmpty()) "dayly://detail/${data.id}" else "dayly://home"
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(deepLink)).apply {
                setPackage(context.packageName)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun resolveData(jsonString: String?, selectedId: String?): WidgetDisplayData {
            if (jsonString.isNullOrEmpty()) return WidgetDisplayData.empty()
            return try {
                val array = JSONArray(jsonString)
                var first: JSONObject? = null
                for (i in 0 until array.length()) {
                    val obj = array.getJSONObject(i)
                    if (first == null) first = obj
                    if (!selectedId.isNullOrEmpty() && obj.optString("id") == selectedId) {
                        return WidgetDisplayData.fromJson(obj)
                    }
                }
                first?.let { WidgetDisplayData.fromJson(it) } ?: WidgetDisplayData.empty()
            } catch (_: Exception) {
                WidgetDisplayData.empty()
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
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                midnight.timeInMillis,
                pendingIntent,
            )
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
