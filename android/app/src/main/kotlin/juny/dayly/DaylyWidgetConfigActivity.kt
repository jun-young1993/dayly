package juny.dayly

import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import android.widget.*
import androidx.appcompat.app.AppCompatActivity
import android.content.SharedPreferences
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
            // 데이터 없으면 앱 먼저 실행 안내 후 종료
            Toast.makeText(this, "dayly 앱에서 D-Day를 먼저 추가해주세요.", Toast.LENGTH_LONG).show()
            finish()
            return
        }

        setContentView(buildLayout(items))
    }

    private fun buildLayout(items: List<Pair<String, String>>): LinearLayout {
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(48, 80, 48, 48)
        }

        val title = TextView(this).apply {
            text = getString(R.string.widget_config_title)
            textSize = 18f
            setPadding(0, 0, 0, 32)
        }
        layout.addView(title)

        items.forEach { (id, label) ->
            val btn = Button(this).apply {
                text = label
                setOnClickListener { onItemSelected(id) }
            }
            layout.addView(btn)
        }

        return layout
    }

    private fun onItemSelected(selectedWidgetId: String) {
        // 인스턴스별 선택 ID 저장
        DaylyAppWidget.instancePrefs(this)
            .edit()
            .putString(DaylyAppWidget.instanceKey(appWidgetId), selectedWidgetId)
            .apply()

        // 위젯 즉시 갱신
        val manager = AppWidgetManager.getInstance(this)
        DaylyAppWidget.updateWidget(this, manager, appWidgetId)

        // 성공 결과 반환
        val resultIntent = Intent().apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        }
        setResult(RESULT_OK, resultIntent)
        finish()
    }

    private fun parseWidgetItems(jsonString: String?): List<Pair<String, String>> {
        if (jsonString.isNullOrEmpty()) return emptyList()
        return try {
            val array = JSONArray(jsonString)
            (0 until array.length()).map { i ->
                val obj = array.getJSONObject(i)
                val id = obj.optString("id", "")
                val sentence = obj.optString("sentence", "–")
                val countdown = obj.optString("countdownText", "")
                val date = obj.optString("targetDateLabel", "")
                val label = "$sentence  $countdown  $date"
                id to label
            }
        } catch (_: Exception) {
            emptyList()
        }
    }
}
