package com.example.my_first_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.telephony.TelephonyManager
import android.widget.RemoteViews
import com.example.my_first_app.R

class CallForwardWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == "com.example.my_first_app.TOGGLE_FORWARD") {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val isActive = prefs.getBoolean("flutter.is_forwarding_active", false)

            if (isActive) {
                disableForwardingSilently(context)
            } else {
                // Open app if they want to turn it on (since we don't know the exact preset number from outside)
                val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                }
                if (launchIntent != null) {
                    context.startActivity(launchIntent)
                }
            }
        } else if (intent.action == "com.example.my_first_app.WIDGET_UPDATE") {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(
                android.content.ComponentName(context, CallForwardWidgetProvider::class.java)
            )
            onUpdate(context, appWidgetManager, appWidgetIds)
        }
    }

    private fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val isActive = prefs.getBoolean("flutter.is_forwarding_active", false)
        val activePreset = prefs.getString("flutter.active_preset_name", "")

        val views = RemoteViews(context.packageName, R.layout.widget_call_forward)

        if (isActive) {
            views.setTextViewText(R.id.widget_status, "Active: $activePreset")
            views.setTextColor(R.id.widget_status, android.graphics.Color.parseColor("#388E3C")) // Green
        } else {
            views.setTextViewText(R.id.widget_status, "Disabled")
            views.setTextColor(R.id.widget_status, android.graphics.Color.parseColor("#D32F2F")) // Red
        }

        val intent = Intent(context, CallForwardWidgetProvider::class.java).apply {
            action = "com.example.my_first_app.TOGGLE_FORWARD"
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun disableForwardingSilently(context: Context) {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        prefs.edit().putBoolean("flutter.is_forwarding_active", false).apply()

        // Force UI update
        val updateIntent = Intent(context, CallForwardWidgetProvider::class.java).apply {
            action = "com.example.my_first_app.WIDGET_UPDATE"
        }
        context.sendBroadcast(updateIntent)

        val ussd = "##002#"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                val tm = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
                tm.sendUssdRequest(ussd, object : TelephonyManager.UssdResponseCallback() {
                    // Ignore response payload 
                }, Handler(Looper.getMainLooper()))
            } catch (e: Exception) {
                // Fallback dialer usually breaks widget flow but we try
            }
        }
    }
}
