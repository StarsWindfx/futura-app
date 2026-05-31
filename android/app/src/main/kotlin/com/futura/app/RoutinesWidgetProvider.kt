package com.futura.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews

class RoutinesWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val count = prefs.getInt("rtn_count", 0)
        val t0 = prefs.getString("rtn_0_title", "") ?: ""
        val t1 = prefs.getString("rtn_1_title", "") ?: ""
        val t2 = prefs.getString("rtn_2_title", "") ?: ""
        val h0 = prefs.getString("rtn_0_time", "") ?: ""
        val h1 = prefs.getString("rtn_1_time", "") ?: ""
        val h2 = prefs.getString("rtn_2_time", "") ?: ""

        val countLabel = when (count) { 0 -> "Aucune routine"; 1 -> "1 routine active"; else -> "$count routines actives" }

        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        else PendingIntent.FLAG_UPDATE_CURRENT
        val pendingIntent = PendingIntent.getActivity(context, 3, intent, flags)

        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.routines_widget_layout)
            views.setTextViewText(R.id.widget_count, countLabel)
            views.setTextViewText(R.id.widget_item1, if (t0.isNotEmpty()) "$h0  $t0" else "")
            views.setTextViewText(R.id.widget_item2, if (t1.isNotEmpty()) "$h1  $t1" else "")
            views.setTextViewText(R.id.widget_item3, if (t2.isNotEmpty()) "$h2  $t2" else "")
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
