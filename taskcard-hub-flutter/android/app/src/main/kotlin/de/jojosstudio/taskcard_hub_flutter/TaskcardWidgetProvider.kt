package de.jojosstudio.taskcard_hub_flutter

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

class TaskcardWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        ids.forEach { updateWidget(context, manager, it) }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_REFRESH) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, TaskcardWidgetProvider::class.java))
            ids.forEach { updateWidget(context, manager, it) }
        }
    }

    private fun updateWidget(context: Context, manager: AppWidgetManager, widgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.widget_taskcards)
        val openIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openPendingIntent = PendingIntent.getActivity(
            context,
            widgetId,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val refreshPendingIntent = PendingIntent.getBroadcast(
            context,
            widgetId,
            Intent(context, TaskcardWidgetProvider::class.java).setAction(ACTION_REFRESH),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        views.setOnClickPendingIntent(R.id.widget_root, openPendingIntent)
        views.setOnClickPendingIntent(R.id.widget_refresh, refreshPendingIntent)
        views.setTextViewText(R.id.widget_status, "Taskcards werden geladen ...")
        manager.updateAppWidget(widgetId, views)

        Thread {
            try {
                val connection = URL("https://hub.jojosstudio.de/api/taskcards").openConnection() as HttpURLConnection
                connection.connectTimeout = 8000
                connection.readTimeout = 8000
                val body = connection.inputStream.bufferedReader().use { it.readText() }
                val cards = JSONObject(body).optJSONArray("cards")
                val total = cards?.length() ?: 0
                var unconfirmed = 0
                var latest = "Keine Taskcards vorhanden"
                if (cards != null && cards.length() > 0) {
                    latest = cards.getJSONObject(0).optString("title", latest)
                    for (index in 0 until cards.length()) {
                        if (!cards.getJSONObject(index).optBoolean("confirmed", false)) unconfirmed++
                    }
                }
                views.setTextViewText(R.id.widget_latest, latest)
                views.setTextViewText(R.id.widget_status, "$total Taskcards · $unconfirmed nicht bestätigt")
                manager.updateAppWidget(widgetId, views)
                connection.disconnect()
            } catch (_: Exception) {
                views.setTextViewText(R.id.widget_status, "Offline · Tippen zum Öffnen")
                manager.updateAppWidget(widgetId, views)
            }
        }.start()
    }

    companion object {
        private const val ACTION_REFRESH = "de.jojosstudio.taskcard_hub_flutter.ACTION_REFRESH_WIDGET"
    }
}
