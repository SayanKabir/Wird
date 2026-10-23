package com.SayanKabir.wird2

import android.content.Intent
import android.os.Build
import android.os.Bundle
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

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOCATION_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestLocationService" -> requestLocationService(result)
                    else -> result.notImplemented()
                }
            }
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
