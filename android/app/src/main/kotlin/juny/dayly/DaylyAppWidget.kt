package juny.dayly

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject

/**
 * dayly 홈화면 위젯 Provider.
 *
 * home_widget 패키지가 저장한 SharedPreferences 값을 읽어 RemoteViews를 업데이트한다.
 * 각 위젯 인스턴스(appWidgetId)는 자신이 표시할 D-Day의 widgetId를
 * 별도 SharedPreferences 키("dayly_widget_{appWidgetId}_selected_id")에 저장한다.
 *
 * 딥링크: 위젯 클릭 시 dayly://detail/{widgetId} 인텐트를 발송하여
 *        MainActivity로 해당 D-Day 상세 화면을 열도록 한다.
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

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        // 위젯 삭제 시 저장된 인스턴스별 선택 ID 제거
        val prefs = instancePrefs(context)
        val editor = prefs.edit()
        appWidgetIds.forEach { id ->
            editor.remove(instanceKey(id))
        }
        editor.apply()
    }

    companion object {
        // home_widget 패키지 기본 SharedPreferences 이름
        private const val HW_PREFS = "FlutterSharedPreferences"
        private const val KEY_WIDGETS_JSON = "flutter.dayly_widgets_json"
        private const val KEY_SELECTED_ID = "flutter.dayly_selected_widget_id"

        // 인스턴스별 선택 ID 저장용 별도 prefs
        private const val INSTANCE_PREFS = "dayly_widget_instance"

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

            // 위젯 크기에 따라 레이아웃 선택
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

            // 클릭 시 앱 딥링크 오픈
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
            views.setOnClickPendingIntent(android.R.id.background, pendingIntent)

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
        fun fromJson(obj: JSONObject) = WidgetDisplayData(
            id = obj.optString("id", ""),
            sentence = obj.optString("sentence", ""),
            countdownText = obj.optString("countdownText", "–"),
            dateLabel = obj.optString("targetDateLabel", ""),
        )
    }
}
