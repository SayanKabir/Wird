package com.SayanKabir.wird2

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

import android.app.PendingIntent
import android.content.Intent

class WirdWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout_small).apply {
                
                // 1. Get Data
                val headerText = widgetData.getString("widget_header", "UP NEXT")
                val prayerName = widgetData.getString("widget_main_name", "FAJR")
                val prayerTime = widgetData.getString("widget_main_time", "05:30")
                val secondaryText = widgetData.getString("widget_secondary", "")

                // 2. Update UI Text
                setTextViewText(R.id.widget_label, headerText)
                setTextViewText(R.id.next_prayer_name, prayerName) // Using same ID for main name
                setTextViewText(R.id.next_prayer_time, prayerTime)
                
                // New Fields
                // "UP NEXT" label might be static in XML, let's see if we need to make it dynamic.
                // In XML it is static "UP NEXT". I should give it an ID to change it to "NOW".
                // I need to update XML to add ID to the label first?
                // Let's check XML.
                
                setTextViewText(R.id.widget_secondary_text, secondaryText)
                
                // Logic to hide secondary if empty
                if (secondaryText.isNullOrEmpty()) {
                    setViewVisibility(R.id.widget_secondary_text, android.view.View.GONE)
                } else {
                    setViewVisibility(R.id.widget_secondary_text, android.view.View.VISIBLE)
                }
                
                // 3. Set Background (Static Glass)
                // User requested "glass bg", overriding dynamic gradients for now to ensure consistency.
                setInt(R.id.widget_root, "setBackgroundResource", R.drawable.widget_glass_bg)
                
                // 4. Open App on Top Click
                val intent = Intent(context, MainActivity::class.java)
                val pendingIntent = PendingIntent.getActivity(
                    context, 
                    0, 
                    intent, 
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }
            
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
