package juny.dayly

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.view.View
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
        const val EXTRA_WIDGET_SIZE = "widget_size"
    }
}

private data class WidgetThemeColors(
    val bgDrawable: Int,
    val textColor: Int,
    val subColor: Int,
    val dotColor: Int,
    val watermarkColor: Int,
)

private class DaylyRemoteViewsFactory(
    private val context: Context,
    intent: Intent,
) : RemoteViewsService.RemoteViewsFactory {

    private var items = listOf<WidgetDisplayData>()
    private val size: WidgetSize = run {
        val sizeName = intent.getStringExtra(DaylyWidgetRemoteViewsService.EXTRA_WIDGET_SIZE)
        if (sizeName != null) {
            try { WidgetSize.valueOf(sizeName) } catch (_: Exception) { WidgetSize.SMALL }
        } else {
            // 이전 버전 호환: EXTRA_IS_MEDIUM 폴백
            if (intent.getBooleanExtra(DaylyWidgetRemoteViewsService.EXTRA_IS_MEDIUM, false))
                WidgetSize.MEDIUM else WidgetSize.SMALL
        }
    }

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

        val layoutId = when (size) {
            WidgetSize.LARGE  -> R.layout.dayly_widget_stack_item_large
            WidgetSize.MEDIUM -> R.layout.dayly_widget_stack_item_medium
            WidgetSize.SMALL  -> R.layout.dayly_widget_stack_item_small
        }

        return RemoteViews(context.packageName, layoutId).apply {
            setTextViewText(R.id.widget_countdown, data.countdownText)
            setTextViewText(R.id.widget_sentence, data.sentence)
            // if (size != WidgetSize.SMALL) {
            setTextViewText(R.id.widget_date_label, data.dateLabel)
            // }

            // 테마별 색상 적용
            val theme = themeColors(data.themePreset)
            setInt(R.id.widget_container, "setBackgroundResource", theme.bgDrawable)
            setTextColor(R.id.widget_countdown, theme.textColor)
            setTextColor(R.id.widget_sentence, theme.subColor)
            setTextColor(R.id.widget_watermark, theme.watermarkColor)
            if (size != WidgetSize.SMALL) {
                setTextColor(R.id.widget_date_label, theme.subColor)
                if (data.isPast) {
                    setViewVisibility(R.id.widget_progress, View.GONE)
                } else {
                    val progress = if (data.totalCount > 0) (data.currentIndex + 1) * 100 / data.totalCount else 100
                    setProgressBar(R.id.widget_progress, 100, progress, false)
                    setViewVisibility(R.id.widget_progress, View.VISIBLE)
                }
            }

            // 페이지 인디케이터 (복수 위젯일 때만 표시)
            if (data.totalCount > 1) {
                val indicator = if (size == WidgetSize.SMALL) "${data.currentIndex + 1}/${data.totalCount}"
                                else "< ${data.currentIndex + 1}/${data.totalCount} >"
                setTextViewText(R.id.widget_page_indicator, indicator)
                setTextColor(R.id.widget_page_indicator, theme.dotColor)
                setViewVisibility(R.id.widget_page_indicator, View.VISIBLE)
            } else {
                setViewVisibility(R.id.widget_page_indicator, View.GONE)
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
        val layoutId = when (size) {
            WidgetSize.LARGE  -> R.layout.dayly_widget_stack_item_large
            WidgetSize.MEDIUM -> R.layout.dayly_widget_stack_item_medium
            WidgetSize.SMALL  -> R.layout.dayly_widget_stack_item_small
        }
        return RemoteViews(context.packageName, layoutId)
    }

    private fun parseAll(jsonString: String?): List<WidgetDisplayData> {
        if (jsonString.isNullOrEmpty()) return emptyList()
        return try {
            val array = JSONArray(jsonString)
            val total = array.length()
            (0 until total).map { i ->
                WidgetDisplayData.fromJson(array.getJSONObject(i), i, total)
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun themeColors(preset: String): WidgetThemeColors = when (preset) {
        "paper" -> WidgetThemeColors(
            bgDrawable = R.drawable.dayly_widget_bg_paper,
            textColor = Color.parseColor("#0B1220"),
            subColor = Color.parseColor("#6B7280"),
            dotColor = Color.parseColor("#9090A8"),
            watermarkColor = Color.parseColor("#C0C8D0"),
        )
        "fog" -> WidgetThemeColors(
            bgDrawable = R.drawable.dayly_widget_bg_fog,
            textColor = Color.parseColor("#0B1220"),
            subColor = Color.parseColor("#6B7280"),
            dotColor = Color.parseColor("#8090A8"),
            watermarkColor = Color.parseColor("#B8C8D8"),
        )
        "lavender" -> WidgetThemeColors(
            bgDrawable = R.drawable.dayly_widget_bg_lavender,
            textColor = Color.parseColor("#0B1220"),
            subColor = Color.parseColor("#6B7280"),
            dotColor = Color.parseColor("#9080B0"),
            watermarkColor = Color.parseColor("#C0B8D0"),
        )
        "blush" -> WidgetThemeColors(
            bgDrawable = R.drawable.dayly_widget_bg_blush,
            textColor = Color.parseColor("#0B1220"),
            subColor = Color.parseColor("#6B7280"),
            dotColor = Color.parseColor("#A88090"),
            watermarkColor = Color.parseColor("#D0B8C0"),
        )
        else -> WidgetThemeColors( // night (기본)
            bgDrawable = R.drawable.dayly_widget_bg,
            textColor = Color.parseColor("#F4F6FA"),
            subColor = Color.parseColor("#7090B0"),
            dotColor = Color.parseColor("#4060A0"),
            watermarkColor = Color.parseColor("#2A3A5A"),
        )
    }

    companion object {
        private const val HW_PREFS = "HomeWidgetPreferences"
        private const val KEY_WIDGETS_JSON = "dayly_widgets_json"
    }
}
