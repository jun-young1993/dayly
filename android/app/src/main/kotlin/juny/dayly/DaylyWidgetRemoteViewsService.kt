package juny.dayly

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray

/**
 * StackView 기반 컬렉션 위젯용 RemoteViewsService.
 *
 * SharedPreferences에서 전체 D-Day 목록을 읽어 StackView 아이템으로 제공한다.
 * 사용자는 fling(스와이프)으로 이벤트 사이를 탐색할 수 있다.
 */
class DaylyWidgetRemoteViewsService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return DaylyRemoteViewsFactory(applicationContext, intent)
    }

    companion object {
        const val EXTRA_IS_MEDIUM = "is_medium"
    }
}

private class DaylyRemoteViewsFactory(
    private val context: Context,
    intent: Intent,
) : RemoteViewsService.RemoteViewsFactory {

    private var items = listOf<WidgetDisplayData>()
    private val isMedium = intent.getBooleanExtra(DaylyWidgetRemoteViewsService.EXTRA_IS_MEDIUM, false)

    override fun onCreate() {}

    override fun onDataSetChanged() {
        val prefs = context.getSharedPreferences(HW_PREFS, Context.MODE_PRIVATE)
        val jsonString = prefs.getString(KEY_WIDGETS_JSON, null)
        items = parseAll(jsonString)
    }

    override fun onDestroy() {
        items = emptyList()
    }

    override fun getCount(): Int = items.size

    override fun getViewAt(position: Int): RemoteViews {
        val data = items.getOrNull(position) ?: return loadingView()

        val layoutId = if (isMedium) R.layout.dayly_widget_stack_item_medium
                       else R.layout.dayly_widget_stack_item_small

        return RemoteViews(context.packageName, layoutId).apply {
            setTextViewText(R.id.widget_countdown, data.countdownText)
            setTextViewText(R.id.widget_sentence, data.sentence)
            if (isMedium) {
                setTextViewText(R.id.widget_date_label, data.dateLabel)
            }

            // 클릭 시 해당 이벤트 상세 화면으로 이동하는 fill-in intent
            val deepLink = if (data.id.isNotEmpty()) "dayly://detail/${data.id}" else "dayly://home"
            val fillInIntent = Intent().apply {
                this.data = Uri.parse(deepLink)
            }
            setOnClickFillInIntent(R.id.widget_container, fillInIntent)
        }
    }

    override fun getLoadingView(): RemoteViews? = null
    override fun getViewTypeCount(): Int = 1
    override fun getItemId(position: Int): Long = position.toLong()
    override fun hasStableIds(): Boolean = false

    private fun loadingView(): RemoteViews {
        val layoutId = if (isMedium) R.layout.dayly_widget_stack_item_medium
                       else R.layout.dayly_widget_stack_item_small
        return RemoteViews(context.packageName, layoutId)
    }

    private fun parseAll(jsonString: String?): List<WidgetDisplayData> {
        if (jsonString.isNullOrEmpty()) return emptyList()
        return try {
            val array = JSONArray(jsonString)
            (0 until array.length()).map { i ->
                WidgetDisplayData.fromJson(array.getJSONObject(i))
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    companion object {
        private const val HW_PREFS = "HomeWidgetPreferences"
        private const val KEY_WIDGETS_JSON = "dayly_widgets_json"
    }
}
