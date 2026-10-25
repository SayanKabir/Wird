package com.SayanKabir.wird2

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import android.view.Display
import com.google.android.gms.common.api.ResolvableApiException
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.LocationSettingsRequest
import com.google.android.gms.location.Priority
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var pendingLocationResult: MethodChannel.Result? = null
    private var linksChannel: MethodChannel? = null

    /** Verse link the app was launched with, handed to Dart once. */
    private var initialLink: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        initialLink = linkFrom(intent)
        linksChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LINKS_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialLink" -> {
                        result.success(initialLink)
                        initialLink = null
                    }
                    else -> result.notImplemented()
                }
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOCATION_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestLocationService" -> requestLocationService(result)
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEVICE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "deviceProfile" -> result.success(deviceProfile())
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * What the device can comfortably do, so the app can default to its
     * lighter visuals on weak hardware: memory, the system's own low-RAM
     * flag, CPU cores, and the two system settings that ask apps to calm
     * down (Battery Saver and "Remove animations").
     */
    private fun deviceProfile(): Map<String, Any> {
        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val mem = ActivityManager.MemoryInfo().also { am.getMemoryInfo(it) }
        val power = getSystemService(Context.POWER_SERVICE) as PowerManager
        val animatorScale = Settings.Global.getFloat(
            contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f
        )
        return mapOf(
            "totalRamMb" to (mem.totalMem / (1024 * 1024)).toInt(),
            "isLowRamDevice" to am.isLowRamDevice,
            "cpuCores" to Runtime.getRuntime().availableProcessors(),
            "sdkInt" to Build.VERSION.SDK_INT,
            "powerSave" to power.isPowerSaveMode,
            "animationsOff" to (animatorScale == 0f),
        )
    }

    /**
     * Show Google Play Services' in-app "Turn on device location" dialog —
     * the same one Maps and most other apps use — instead of sending the user
     * off to system settings. Resolves to true once location is on.
     */
    private fun requestLocationService(result: MethodChannel.Result) {
        if (pendingLocationResult != null) {
            result.error("in_progress", "A location request is already showing", null)
            return
        }
        val request = LocationRequest.Builder(Priority.PRIORITY_BALANCED_POWER_ACCURACY, 10_000L).build()
        val settingsRequest = LocationSettingsRequest.Builder()
            .addLocationRequest(request)
            .setAlwaysShow(true)
            .build()

        LocationServices.getSettingsClient(this)
            .checkLocationSettings(settingsRequest)
            .addOnSuccessListener { result.success(true) }
            .addOnFailureListener { e ->
                if (e is ResolvableApiException) {
                    try {
                        pendingLocationResult = result
                        e.startResolutionForResult(this, LOCATION_SETTINGS_REQUEST)
                    } catch (_: Exception) {
                        pendingLocationResult = null
                        result.success(false)
                    }
                } else {
                    // No dialog available (e.g. no Play Services) — caller falls
                    // back to opening the system location settings page.
                    result.success(false)
                }
            }
    }

    /** A quran.com link tapped while Wird is already running. */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        linkFrom(intent)?.let { linksChannel?.invokeMethod("onLink", it) }
    }

    private fun linkFrom(intent: Intent?): String? =
        if (intent?.action == Intent.ACTION_VIEW) intent.dataString else null

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == LOCATION_SETTINGS_REQUEST) {
            pendingLocationResult?.success(resultCode == RESULT_OK)
            pendingLocationResult = null
        }
    }

    companion object {
        private const val LOCATION_CHANNEL = "com.SayanKabir.wird2/location"
        private const val DEVICE_CHANNEL = "com.SayanKabir.wird2/device"
        private const val LINKS_CHANNEL = "com.SayanKabir.wird2/links"
        private const val LOCATION_SETTINGS_REQUEST = 7301
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestHighestRefreshRate()
    }

    /**
     * Ask the system for the fastest display mode at the current resolution.
     *
     * Flutter renders at whatever cadence the Choreographer delivers, which is
     * the refresh rate the OS has assigned to this window. On devices with
     * variable-refresh panels some OEMs leave an app's window at 60Hz unless it
     * opts in explicitly, capping the frame budget at 16.6ms instead of the
     * 8.3ms a 120Hz panel allows.
     *
     * Only modes matching the current resolution are considered, so this never
     * changes the rendered resolution — it only asks for more frames per second.
     * If the device has no faster mode, this is a no-op.
     */
    private fun requestHighestRefreshRate() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return

        val display: Display? =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                display
            } else {
                @Suppress("DEPRECATION")
                windowManager.defaultDisplay
            }
        if (display == null) return

        val current = display.mode ?: return
        val fastest = display.supportedModes
            ?.filter {
                it.physicalWidth == current.physicalWidth &&
                    it.physicalHeight == current.physicalHeight
            }
            ?.maxByOrNull { it.refreshRate }
            ?: return

        if (fastest.refreshRate > current.refreshRate) {
            window.attributes = window.attributes.apply {
                preferredDisplayModeId = fastest.modeId
            }
        }
    }
}
