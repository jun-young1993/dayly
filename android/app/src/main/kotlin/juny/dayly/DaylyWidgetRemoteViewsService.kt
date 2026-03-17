package juny.dayly

import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.graphics.Color
import android.net.Uri
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray

/**
 * StackView 내 현재 아이템의 진행 비율.
 *
 * currentIndex | totalCount | result
 * -------------|------------|-------
 *            0 |          1 | 1.0f    (단일 아이템)
 *            0 |          5 | 0.2f    (5개 중 1번째)
 *            4 |          5 | 1.0f    (5개 중 마지막)
 *            * |          0 | 1.0f    (÷0 방어: 단일로 간주)
 *           -1 |          5 | 0.0f    (음수: 클램프 없음, 호출자 책임)
 */
internal fun fillFraction(currentIndex: Int, totalCount: Int): Float =
    if (totalCount > 0) (currentIndex + 1).toFloat() / totalCount else 1f

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

private fun resolveImagePath(context: Context, path: String?): String? {
    if (path.isNullOrEmpty()) return null
    return try {
        val file = if (java.io.File(path).isAbsolute) java.io.File(path)
                   else java.io.File(context.filesDir, path)
        if (file.exists()) file.absolutePath
        else { Log.w("DaylyWidget", "Image file not found: $path"); null }
    } catch (e: Exception) {
        Log.e("DaylyWidget", "resolveImagePath failed: $path", e)
        null
    }
}

private fun loadScaledBitmap(absPath: String): android.graphics.Bitmap? {
    return try {
        val opts = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(absPath, opts)
        var sample = 1
        while (opts.outWidth / sample > 400 || opts.outHeight / sample > 400) sample *= 2
        BitmapFactory.decodeFile(absPath, BitmapFactory.Options().apply { inSampleSize = sample })
    } catch (e: Exception) {
        Log.e("DaylyWidget", "loadScaledBitmap failed: $absPath", e)
        null
    }
}

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
            setTextViewText(R.id.widget_date_label, data.dateLabel)

            // 테마별 색상 적용
            val theme = themeColors(data.themePreset)
            setInt(R.id.widget_container, "setBackgroundResource", theme.bgDrawable)
            setTextColor(R.id.widget_countdown, theme.textColor)
            setTextColor(R.id.widget_sentence, theme.subColor)
            setTextColor(R.id.widget_watermark, theme.watermarkColor)
            setTextColor(R.id.widget_date_label, theme.subColor)

            // 지난 이벤트: 반투명 처리
            setFloat(R.id.widget_container, "setAlpha", if (data.isPast) 0.5f else 1.0f)

            if (size != WidgetSize.SMALL) {
                // 커스텀 진행 바 (ProgressBar 대신 FrameLayout+View 방식으로 테마 색상 지원)
                if (data.isPast) {
                    setViewVisibility(R.id.widget_progress_container, View.GONE)
                } else {
                    val fraction = fillFraction(data.currentIndex, data.totalCount)
                    setInt(R.id.widget_progress_track, "setBackgroundColor", theme.progressTrackColor)
                    setInt(R.id.widget_progress_fill, "setBackgroundColor", theme.progressFillColor)
                    // scaleX: draw 단계에서 canvas 변환 → 배경색도 스케일됨 (setViewPadding은 background에 무효)
                    setFloat(R.id.widget_progress_fill, "setPivotX", 0f)
                    setFloat(R.id.widget_progress_fill, "setScaleX", fraction)
                    setViewVisibility(R.id.widget_progress_container, View.VISIBLE)
                }
            }

            // 배경 이미지 처리 (Medium/Large only)
            if (size != WidgetSize.SMALL) {
                val absPath = resolveImagePath(context, data.backgroundImagePath)
                val bitmap = absPath?.let { loadScaledBitmap(it) }
                if (bitmap != null) {
                    setImageViewBitmap(R.id.widget_bg_image, bitmap)
                    setViewVisibility(R.id.widget_bg_image, View.VISIBLE)
                    setViewVisibility(R.id.widget_bg_overlay, View.VISIBLE)
                    setInt(R.id.widget_bg_overlay, "setBackgroundColor",
                        Color.argb(140, 0, 0, 0))
                } else {
                    setViewVisibility(R.id.widget_bg_image, View.GONE)
                    setViewVisibility(R.id.widget_bg_overlay, View.GONE)
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

    companion object {
        private const val HW_PREFS = "HomeWidgetPreferences"
        private const val KEY_WIDGETS_JSON = "dayly_widgets_json"
    }
}
