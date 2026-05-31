package com.futura.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews

class FuturaWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val taskCount = prefs.getInt("task_count", 0)
        val task0 = prefs.getString("task_0", "") ?: ""
        val task1 = prefs.getString("task_1", "") ?: ""
        val task2 = prefs.getString("task_2", "") ?: ""

        val countLabel = when (taskCount) {
            0 -> "Tout est fait ✓"
            1 -> "1 tâche"
            else -> "$taskCount tâches"
        }

        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        else
            PendingIntent.FLAG_UPDATE_CURRENT
        val pendingIntent = PendingIntent.getActivity(context, 0, intent, flags)

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.futura_widget_layout)
            views.setTextViewText(R.id.widget_count, countLabel)
            views.setTextViewText(R.id.widget_task1, if (task0.isNotEmpty()) "· $task0" else "")
            views.setTextViewText(R.id.widget_task2, if (task1.isNotEmpty()) "· $task1" else "")
            views.setTextViewText(R.id.widget_task3, if (task2.isNotEmpty()) "· $task2" else "")
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
