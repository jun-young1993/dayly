package juny.dayly

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import java.util.Calendar

/**
 * Android 홈화면 위젯의 AlarmManager 생명주기를 중앙 관리한다.
 *
 * ┌──────────────────────────────────────────────────┐
 * │  DaylyAppWidget (Small)  ──┐                     │
 * │  DaylyAppWidgetMedium    ──┼──▶ WidgetUpdateManager │
 * │  DaylyAppWidgetLarge     ──┘                     │
 * └──────────────────────────────────────────────────┘
 *
 * 설계 원칙:
 * - scheduleIfNeeded(): FLAG_NO_CREATE로 중복 예약 방지
 * - cancelIfNone():     3개 Provider 모두 위젯 0개일 때만 취소
 * - updateAll():        Small + Medium + Large 모두 갱신
 * - onMidnightReceived(): updateAll() → scheduleIfNeeded() 순서로 실행
 */
internal object WidgetUpdateManager {

    private const val TAG = "DaylyWidget"

    /**
     * 자정 알람이 없을 때만 예약한다 (중복 방지).
     * 어떤 Provider에서든 첫 위젯이 추가될 때(onEnabled) 호출하면 된다.
     */
    fun scheduleIfNeeded(ctx: Context) {
        val existing = PendingIntent.getBroadcast(
            ctx, 0, midnightIntent(ctx),
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
        )
        if (existing != null) {
            Log.d(TAG, "scheduleIfNeeded: alarm already scheduled, skip")
            return
        }
        scheduleNext(ctx)
    }

    /**
     * 3개 Provider(Small/Medium/Large) 전체에 위젯이 하나도 없을 때만 알람을 취소한다.
     * Small 위젯이 제거돼도 Medium/Large가 남아있으면 알람을 유지한다.
     */
    fun cancelIfNone(ctx: Context) {
        val manager = AppWidgetManager.getInstance(ctx)
        val providers = listOf(
            DaylyAppWidget::class.java,
            DaylyAppWidgetMedium::class.java,
            DaylyAppWidgetLarge::class.java,
        )
        val hasAny = providers.any { cls ->
            manager.getAppWidgetIds(ComponentName(ctx, cls)).isNotEmpty()
        }
        if (!hasAny) {
            Log.d(TAG, "cancelIfNone: no widgets remain, cancelling midnight alarm")
            val alarmManager = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            alarmManager.cancel(
                PendingIntent.getBroadcast(
                    ctx, 0, midnightIntent(ctx),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                ),
            )
        } else {
            Log.d(TAG, "cancelIfNone: widgets still exist, keeping alarm")
        }
    }

    /**
     * Small / Medium / Large 세 Provider의 모든 위젯 인스턴스를 한 번에 갱신한다.
     * 자정 업데이트·타임존 변경 등 전체 갱신이 필요한 경우에 호출한다.
     */
    fun updateAll(ctx: Context) {
        val manager = AppWidgetManager.getInstance(ctx)
        Log.d(TAG, "updateAll: refreshing all providers")

        manager.getAppWidgetIds(ComponentName(ctx, DaylyAppWidget::class.java)).forEach { id ->
            DaylyAppWidget.updateWidget(ctx, manager, id)               // 크기 자동 감지
        }
        manager.getAppWidgetIds(ComponentName(ctx, DaylyAppWidgetMedium::class.java)).forEach { id ->
            DaylyAppWidget.updateWidget(ctx, manager, id, forceSize = WidgetSize.MEDIUM)
        }
        manager.getAppWidgetIds(ComponentName(ctx, DaylyAppWidgetLarge::class.java)).forEach { id ->
            DaylyAppWidget.updateWidget(ctx, manager, id, forceSize = WidgetSize.LARGE)
        }
    }

    /** 자정 알람 수신 시 진입점 — 전체 갱신 후 다음 날 자정으로 재예약 */
    fun onMidnightReceived(ctx: Context) {
        Log.d(TAG, "onMidnightReceived: midnight alarm fired")
        updateAll(ctx)
        scheduleNext(ctx)
    }

    // ── 내부 헬퍼 ──────────────────────────────────────────────────

    private fun midnightIntent(ctx: Context): Intent =
        Intent(ctx, DaylyAppWidget::class.java).apply {
            action = DaylyAppWidget.ACTION_MIDNIGHT_UPDATE
        }

    private fun scheduleNext(ctx: Context) {
        val midnight = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, 1)
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 1)
            set(Calendar.MILLISECOND, 0)
        }
        val pi = PendingIntent.getBroadcast(
            ctx, 0, midnightIntent(ctx),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val alarmManager = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarmManager.canScheduleExactAlarms()) {
            alarmManager.setWindow(
                AlarmManager.RTC_WAKEUP,
                midnight.timeInMillis,
                5 * 60 * 1000L,
                pi,
            )
            Log.d(TAG, "scheduleNext: setWindow (no exact alarm permission) next=${midnight.time}")
        } else {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, midnight.timeInMillis, pi)
            Log.d(TAG, "scheduleNext: setExact next=${midnight.time}")
        }
    }
}
