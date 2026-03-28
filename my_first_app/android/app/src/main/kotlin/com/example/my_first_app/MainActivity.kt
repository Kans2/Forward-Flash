package com.example.my_first_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.telephony.SubscriptionManager
import android.telephony.TelephonyManager
import android.util.Log

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── SIM channel ──────────────────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.callforward/sim")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSimSlots" -> result.success(getSimSlots())
                    else          -> result.notImplemented()
                }
            }

        // ── USSD channel ─────────────────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.callforward/ussd")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "dialUssd" -> {
                        val ussd    = call.argument<String>("ussd")
                            ?: return@setMethodCallHandler result.error("NO_USSD", "ussd is null", null)
                        val simSlot = call.argument<Int>("simSlot") ?: 0
                        dialUssd(ussd, simSlot, result)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // ── Dial USSD ─────────────────────────────────────────────────────────────
    private fun dialUssd(ussd: String, simSlot: Int, result: MethodChannel.Result) {
        Log.d("CallForward", "dialUssd called: ussd=$ussd simSlot=$simSlot")
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                val subId = getSubscriptionId(simSlot)
                var tm = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
                if (subId != null) {
                    tm = tm.createForSubscriptionId(subId)
                }

                Log.d("CallForward", "Sending USSD Request silently: $ussd")
                tm.sendUssdRequest(ussd, object : TelephonyManager.UssdResponseCallback() {
                    override fun onReceiveUssdResponse(telephonyManager: TelephonyManager?, request: String?, returnMessage: CharSequence?) {
                        Log.d("CallForward", "USSD Success: $returnMessage")
                        val resultMap = mapOf("success" to true, "message" to (returnMessage?.toString() ?: "Forwarding enabled"))
                        result.success(resultMap)
                    }

                    override fun onReceiveUssdResponseFailed(telephonyManager: TelephonyManager?, request: String?, failureCode: Int) {
                        Log.e("CallForward", "USSD Failed with code: $failureCode")
                        // If silent execution fails natively, we try throwing it straight to the fallback intent.
                        fallbackToDialer(ussd, simSlot, result)
                    }
                }, Handler(Looper.getMainLooper()))
            } catch (e: SecurityException) {
                Log.e("CallForward", "SecurityException during silent USSD: ${e.message}")
                fallbackToDialer(ussd, simSlot, result)
            } catch (e: Exception) {
                Log.e("CallForward", "Exception during silent USSD: ${e.message}")
                fallbackToDialer(ussd, simSlot, result)
            }
        } else {
            fallbackToDialer(ussd, simSlot, result)
        }
    }

    private fun fallbackToDialer(ussd: String, simSlot: Int, result: MethodChannel.Result) {
        try {
            val intent = Intent(Intent.ACTION_CALL).apply {
                val encoded = ussd.replace("#", "%23")
                data = Uri.parse("tel:$encoded")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
                putExtra("com.android.phone.extra.slot", simSlot)
                putExtra("simSlot", simSlot)
            }
            Log.d("CallForward", "Starting dialer intent: ${intent.data}")
            startActivity(intent)
            result.success(mapOf("success" to true, "message" to "Device initiated dialing sequence."))
        } catch (e: Exception) {
            Log.e("CallForward", "dialUssd error: ${e.message}")
            result.error("DIAL_ERROR", e.message, null)
        }
    }

    // ── SIM slot enumeration ──────────────────────────────────────────────────
    private fun getSimSlots(): List<Map<String, Any?>> {
        return try {
            val sm    = getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager
            val infos = sm.activeSubscriptionInfoList ?: return fallbackSlot()
            infos.map { info ->
                mapOf(
                    "slotIndex"   to info.simSlotIndex,
                    "carrierName" to info.carrierName?.toString(),
                    "mccMnc"      to ((info.mccString ?: "") + (info.mncString ?: "")),
                    "phoneNumber" to info.number,
                    "isActive"    to true,
                )
            }
        } catch (e: Exception) {
            fallbackSlot()
        }
    }

    private fun getSubscriptionId(slotIndex: Int): Int? {
        return try {
            val sm    = getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager
            val infos = sm.activeSubscriptionInfoList ?: return null
            infos.firstOrNull { it.simSlotIndex == slotIndex }?.subscriptionId
        } catch (e: Exception) { null }
    }

    private fun fallbackSlot() = listOf(
        mapOf("slotIndex" to 0, "carrierName" to "Unknown",
              "mccMnc" to null, "phoneNumber" to null, "isActive" to true)
    )
}
