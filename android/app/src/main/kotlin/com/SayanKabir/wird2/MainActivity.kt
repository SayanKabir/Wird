package com.SayanKabir.wird2

import android.os.Build
import android.os.Bundle
import android.view.Display
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

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
