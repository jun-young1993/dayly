package juny.dayly

import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import org.json.JSONArray

/**
 * 위젯 구성 Activity.
 *
 * 홈화면에서 dayly 위젯을 추가할 때 자동으로 실행된다.
 * 사용자가 표시할 D-Day를 선택하면 해당 widgetId를
 * 인스턴스별 SharedPreferences에 저장하고 위젯을 갱신한다.
 *
 * 등록: AndroidManifest.xml의 <activity> + appwidget-provider xml의 android:configure
 */
class DaylyWidgetConfigActivity : AppCompatActivity() {

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 결과를 RESULT_CANCELED로 초기화 (사용자가 뒤로 나가면 위젯 추가 취소)
        setResult(RESULT_CANCELED)

        appWidgetId = intent.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        // 저장된 D-Day 목록 로드 (home_widget 패키지는 HomeWidgetPreferences에 저장)
        val hwPrefs = getSharedPreferences("HomeWidgetPreferences", MODE_PRIVATE)
        val jsonString = hwPrefs.getString("dayly_widgets_json", null)
        val items = parseWidgetItems(jsonString)

        if (items.isEmpty()) {
            Toast.makeText(this, "dayly 앱에서 D-Day를 먼저 추가해주세요.", Toast.LENGTH_LONG).show()
            finish()
            return
        }

        setContentView(R.layout.activity_widget_config)
        populateItems(items)
    }

    private fun populateItems(items: List<ConfigItem>) {
        val container = findViewById<LinearLayout>(R.id.config_items_container)
        val inflater = LayoutInflater.from(this)

        items.forEach { item ->
            val card = inflater.inflate(R.layout.item_widget_config, container, false)

            card.findViewById<TextView>(R.id.config_item_sentence).text = item.sentence
            card.findViewById<TextView>(R.id.config_item_meta).text =
                listOf(item.countdown, item.dateLabel).filter { it.isNotEmpty() }.joinToString("  ")
            card.findViewById<android.view.View>(R.id.config_item_theme_bar)
                .setBackgroundColor(themeColors(item.themePreset).progressFillColor)

            card.setOnClickListener { onItemSelected(item.id) }
            container.addView(card)
        }
    }

    private fun onItemSelected(selectedWidgetId: String) {
        DaylyAppWidget.instancePrefs(this)
            .edit()
            .putString(DaylyAppWidget.instanceKey(appWidgetId), selectedWidgetId)
            .apply()

        val manager = AppWidgetManager.getInstance(this)
        DaylyAppWidget.updateWidget(this, manager, appWidgetId)

        val resultIntent = Intent().apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        }
        setResult(RESULT_OK, resultIntent)
        finish()
    }

    private data class ConfigItem(
        val id: String,
        val sentence: String,
        val countdown: String,
        val dateLabel: String,
        val themePreset: String,
    )

    private fun parseWidgetItems(jsonString: String?): List<ConfigItem> {
        if (jsonString.isNullOrEmpty()) return emptyList()
        return try {
            val array = JSONArray(jsonString)
            (0 until array.length()).map { i ->
                val obj = array.getJSONObject(i)
                ConfigItem(
                    id = obj.optString("id", ""),
                    sentence = obj.optString("sentence", "–"),
                    countdown = obj.optString("countdownText", ""),
                    dateLabel = obj.optString("targetDateLabel", ""),
                    themePreset = obj.optString("themePreset", "night"),
                )
            }
        } catch (_: Exception) {
            emptyList()
        }
    }
}
