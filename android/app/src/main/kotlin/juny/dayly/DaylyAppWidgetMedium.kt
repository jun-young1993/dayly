package juny.dayly

import android.appwidget.AppWidgetManager
import android.content.Context
import android.os.Bundle

/**
 * Medium(4×2) 홈화면 위젯 Provider.
 * DaylyAppWidget을 상속하며, 항상 medium 레이아웃을 사용한다.
 *
 * AlarmManager 생명주기(onEnabled/onDisabled)는 부모를 통해 WidgetUpdateManager에 위임된다.
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
}
