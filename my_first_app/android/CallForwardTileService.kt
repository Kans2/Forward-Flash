package com.callforward

import android.content.Intent
import android.graphics.drawable.Icon
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import androidx.annotation.RequiresApi

/**
 * Quick Settings Tile — appears in the Android notification shade.
 * Tapping it opens the CallForward app to the home screen (which auto-toggles
 * the last-used preset). A long-press opens the app for full control.
 *
 * To register: add to AndroidManifest.xml
 *   <service android:name=".CallForwardTileService"
 *            android:icon="@drawable/ic_call_forward"
 *            android:label="Call Forward"
 *            android:permission="android.permission.BIND_QUICK_SETTINGS_TILE">
 *       <intent-filter>
 *           <action android:name="android.service.quicksettings.action.QS_TILE"/>
 *       </intent-filter>
 *   </service>
 */
@RequiresApi(Build.VERSION_CODES.N)
class CallForwardTileService : TileService() {

    override fun onStartListening() {
        super.onStartListening()
        updateTile()
    }

    override fun onClick() {
        super.onClick()
        // Read current state from shared prefs and toggle
        val prefs = getSharedPreferences("callforward_prefs", MODE_PRIVATE)
        val isActive = prefs.getBoolean("is_forwarding_active", false)

        if (isActive) {
            // Disable forwarding directly
            disableForwarding()
        } else {
            // Open app to select/activate preset
            val intent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
                putExtra("from_tile", true)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            if (intent != null) startActivityAndCollapse(intent)
        }
        updateTile()
    }

    private fun updateTile() {
        val prefs = getSharedPreferences("callforward_prefs", MODE_PRIVATE)
        val isActive = prefs.getBoolean("is_forwarding_active", false)
        val activePreset = prefs.getString("active_preset_name", null)

        qsTile?.apply {
            state = if (isActive) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
            label = "Call Forward"
            subtitle = when {
                isActive && activePreset != null -> activePreset
                isActive -> "Active"
                else     -> "Tap to enable"
            }
            updateTile()
        }
    }

    private fun disableForwarding() {
        // Dial ##002# to disable all forwarding
        val intent = Intent(Intent.ACTION_CALL).apply {
            data = android.net.Uri.parse("tel:${android.net.Uri.encode("##002#")}")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)

        val prefs = getSharedPreferences("callforward_prefs", MODE_PRIVATE)
        prefs.edit().putBoolean("is_forwarding_active", false).apply()
    }
}