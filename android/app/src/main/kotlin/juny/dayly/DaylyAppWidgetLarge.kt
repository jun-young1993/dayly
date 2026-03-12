package juny.dayly

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle

/**
 * Large(4×4) 홈화면 위젯 Provider.
 * DaylyAppWidget을 상속하며, 항상 large 레이아웃을 사용한다.
 */
class DaylyAppWidgetLarge : DaylyAppWidget() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { id ->
            updateWidget(context, appWidgetManager, id, forceSize = WidgetSize.LARGE)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        updateWidget(context, appWidgetManager, appWidgetId, forceSize = WidgetSize.LARGE)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_MIDNIGHT_UPDATE) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, DaylyAppWidgetLarge::class.java)
            )
            if (ids.isNotEmpty()) {
                onUpdate(context, manager, ids)
            }
        }
    }
}
