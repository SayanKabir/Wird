package com.SayanKabir.wird2

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import android.app.PendingIntent
import android.content.Intent
import android.graphics.Color
import android.view.View

class WirdListWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout_large).apply {
                
                // 1. Get Active Prayer (to highlight)
                val currentPrayerParams = widgetData.getString("prayer_period", "fajr") ?: "fajr"
                // Normalize to lowercase for comparison
                val activePrayer = currentPrayerParams.lowercase()

                // 2. Load and Set Times for Each Row

                // Define IDs for rows/text 
                val rowIds = mapOf(
                    "fajr" to R.id.row_fajr,
                    "sunrise" to R.id.row_sunrise,
                    "dhuhr" to R.id.row_dhuhr,
                    "asr" to R.id.row_asr,
                    "maghrib" to R.id.row_maghrib,
                    "isha" to R.id.row_isha
                )
                
                val nameIds = mapOf(
                    "fajr" to R.id.name_fajr,
                    "sunrise" to R.id.name_sunrise,
                    "dhuhr" to R.id.name_dhuhr,
                    "asr" to R.id.name_asr,
                    "maghrib" to R.id.name_maghrib,
                    "isha" to R.id.name_isha
                )

                val timeIds = mapOf(
                    "fajr" to R.id.time_fajr,
                    "sunrise" to R.id.time_sunrise,
                    "dhuhr" to R.id.time_dhuhr,
                    "asr" to R.id.time_asr,
                    "maghrib" to R.id.time_maghrib,
                    "isha" to R.id.time_isha
                )

                rowIds.keys.forEach { key ->
                    // Get Time from Prefs
                    val timeText = widgetData.getString("time_$key", "--:--")
                    
                    // Set Time Text
                    setTextViewText(timeIds[key]!!, timeText)

                    // Highlight Active Row
                    if (key == activePrayer) {
                        // Highlight: Thicker font or brighter color
                        setInt(nameIds[key]!!, "setTextColor", Color.WHITE)
                        setInt(timeIds[key]!!, "setTextColor", Color.WHITE)
                        
                        // Maybe bold?
                        // setInt(timeIds[key]!!, "setTypeface", 1) // 1=Bold? RemoteViews limits
                    } else {
                        // Dim others slightly
                        val dimmedColor = Color.parseColor("#CCFFFFFF")
                        setInt(nameIds[key]!!, "setTextColor", dimmedColor)
                        setInt(timeIds[key]!!, "setTextColor", dimmedColor)
                    }
                }

                // 3. Open App on Click
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
