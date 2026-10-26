package com.SayanKabir.wird2

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import org.json.JSONArray

/**
 * Swaps the home screen icon between the five per-prayer launcher aliases
 * declared in the manifest (see AppIconService in Dart).
 *
 * Dart hands over the icon to show now plus, in "Follow prayer times" mode,
 * the next few days of switch times. Those are kept here so a single alarm
 * can walk through them while the app is closed.
 *
 * Swapping the enabled alias while the app is on screen can close it on some
 * launchers, so any change asked for then waits for [onAppStopped].
 */
object AppIconManager {
    private const val PREFS = "wird_app_icon"
    private const val KEY_SCHEDULE = "schedule"
    private const val KEY_WANTED = "wanted"
    private const val REQUEST_CODE = 7302

    private val aliases = mapOf(
        "fajr" to "IconFajr",
        "dhuhr" to "IconDhuhr",
        "asr" to "IconAsr",
        "maghrib" to "IconMaghrib",
        "isha" to "IconIsha",
    )

    /** True between MainActivity's onStart and onStop. */
    @Volatile
    var appVisible = false

    /**
     * [schedule] is a list of [epochMillis, iconName] pairs in time order;
     * empty when the user picked a fixed icon.
     */
    fun update(context: Context, name: String, schedule: List<List<Any>>) {
        val json = JSONArray()
        for (entry in schedule) {
            json.put(JSONArray().put((entry[0] as Number).toLong()).put(entry[1] as String))
        }
        prefs(context).edit()
            .putString(KEY_WANTED, name)
            .putString(KEY_SCHEDULE, json.toString())
            .apply()
        armNextAlarm(context)
        if (!appVisible) apply(context, name)
    }

    fun onAppStopped(context: Context) {
        prefs(context).getString(KEY_WANTED, null)?.let { apply(context, it) }
    }

    /** Alarm fired, or the phone rebooted: show the icon due now. */
    fun onAlarm(context: Context) {
        val due = dueNow(context)
        if (due != null) prefs(context).edit().putString(KEY_WANTED, due).apply()
        armNextAlarm(context)
        if (!appVisible) prefs(context).getString(KEY_WANTED, null)?.let { apply(context, it) }
    }

    private fun apply(context: Context, name: String) {
        val wanted = aliases[name] ?: return
        val pm = context.packageManager
        // Enable the new alias before disabling the old one, so there's never
        // a moment with no launcher entry at all.
        val ordered = aliases.values.sortedBy { if (it == wanted) 0 else 1 }
        for (alias in ordered) {
            val component = ComponentName(context.packageName, "com.SayanKabir.wird2.$alias")
            val enable = alias == wanted
            if (isEnabled(pm, component, alias) == enable) continue
            val state = if (enable) {
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED
            } else {
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED
            }
            pm.setComponentEnabledSetting(component, state, PackageManager.DONT_KILL_APP)
        }
    }

    /** "Default" means whatever the manifest says: only Maghrib starts on. */
    private fun isEnabled(pm: PackageManager, component: ComponentName, alias: String) =
        when (pm.getComponentEnabledSetting(component)) {
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED -> true
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED -> false
            else -> alias == "IconMaghrib"
        }

    private fun schedule(context: Context): List<Pair<Long, String>> {
        val raw = prefs(context).getString(KEY_SCHEDULE, null) ?: return emptyList()
        val json = JSONArray(raw)
        return (0 until json.length()).map {
            val entry = json.getJSONArray(it)
            entry.getLong(0) to entry.getString(1)
        }
    }

    private fun dueNow(context: Context): String? {
        val now = System.currentTimeMillis()
        return schedule(context).lastOrNull { it.first <= now }?.second
    }

    private fun armNextAlarm(context: Context) {
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = PendingIntent.getBroadcast(
            context,
            REQUEST_CODE,
            Intent(context, AppIconReceiver::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val now = System.currentTimeMillis()
        val next = schedule(context).firstOrNull { it.first > now }
        if (next == null) {
            alarms.cancel(intent)
            return
        }
        // On time when the exact-alarm permission (held for prayer alerts) is
        // granted; otherwise inexact, which Android may push back ~30 minutes.
        val exact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarms.canScheduleExactAlarms()
        if (exact) {
            alarms.setExactAndAllowWhileIdle(AlarmManager.RTC, next.first, intent)
        } else {
            alarms.setAndAllowWhileIdle(AlarmManager.RTC, next.first, intent)
        }
    }

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}

class AppIconReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        AppIconManager.onAlarm(context)
    }
}
