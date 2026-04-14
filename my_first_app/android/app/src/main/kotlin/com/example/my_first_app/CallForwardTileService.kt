package com.example.my_first_app

import android.content.Intent
import android.graphics.drawable.Icon
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import androidx.annotation.RequiresApi

import android.content.Context
import android.telephony.TelephonyManager
import android.os.Handler
import android.os.Looper
import android.util.Log
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
        val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        val isActive = prefs.getBoolean("flutter.is_forwarding_active", false)

        if (isActive) {
            disableForwardingSilently()
        } else {
            val intent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
                putExtra("from_tile", true)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            if (intent != null) startActivityAndCollapse(intent)
        }
        updateTile()
    }

    private fun updateTile() {
        val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        val isActive = prefs.getBoolean("flutter.is_forwarding_active", false)
        val activePreset = prefs.getString("flutter.active_preset_name", null)

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

    private fun disableForwardingSilently() {
        val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        prefs.edit().putBoolean("flutter.is_forwarding_active", false).apply()

        // Dial ##002# to disable all forwarding natively. Wait for it to clear.
        val ussd = "##002#"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                val tm = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
                tm.sendUssdRequest(ussd, object : TelephonyManager.UssdResponseCallback() {
                    override fun onReceiveUssdResponse(t: TelephonyManager?, r: String?, m: CharSequence?) {
                        Log.d("Tile", "Success: $m")
                    }
                    override fun onReceiveUssdResponseFailed(t: TelephonyManager?, r: String?, code: Int) {
                        fallbackDisable(ussd)
                    }
                }, Handler(Looper.getMainLooper()))
            } catch (e: Exception) {
                fallbackDisable(ussd)
            }
        } else {
            fallbackDisable(ussd)
        }
    }

    private fun fallbackDisable(ussd: String) {
        val intent = Intent(Intent.ACTION_CALL).apply {
            data = android.net.Uri.parse("tel:${ussd.replace("#", "%23")}")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivityAndCollapse(intent)
    }
}