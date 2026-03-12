package juny.dayly

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle

/**
 * Medium(4×2) 홈화면 위젯 Provider.
 * DaylyAppWidget을 상속하며, 항상 medium 레이아웃을 사용한다.
 */
class DaylyAppWidgetMedium : DaylyAppWidget() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { id ->
            updateWidget(context, appWidgetManager, id, forceSize = WidgetSize.MEDIUM)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        updateWidget(context, appWidgetManager, appWidgetId, forceSize = WidgetSize.MEDIUM)
    }

    override fun onReceive(context: Context, intent: Intent) {
        // 표준 위젯 이벤트 처리 (APPWIDGET_UPDATE 등) + small 위젯 자정 업데이트
        super.onReceive(context, intent)
        // medium 위젯 자정 업데이트
        if (intent.action == ACTION_MIDNIGHT_UPDATE) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, DaylyAppWidgetMedium::class.java)
            )
            if (ids.isNotEmpty()) {
                onUpdate(context, manager, ids)
            }
        }
    }
}
