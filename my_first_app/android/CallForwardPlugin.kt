package com.callforward

import android.content.Context
import android.os.Build
import android.telecom.TelecomManager
import android.telephony.TelephonyManager
import android.telephony.SubscriptionManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

class CallForwardPlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "com.callforward/ussd")
        channel.setMethodCallHandler(this)

        // Also register SIM channel
        val simChannel = MethodChannel(binding.binaryMessenger, "com.callforward/sim")
        simChannel.setMethodCallHandler(SimMethodHandler(context))
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "dialUssd" -> {
                val ussd    = call.argument<String>("ussd") ?: return result.error("NO_USSD", "USSD null", null)
                val simSlot = call.argument<Int>("simSlot") ?: 0
                dialUssd(ussd, simSlot, result)
            }
            else -> result.notImplemented()
        }
    }

    private fun dialUssd(ussd: String, simSlot: Int, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            // Pre-Oreo: open dialer with intent
            val intent = android.content.Intent(android.content.Intent.ACTION_CALL)
            intent.data = android.net.Uri.parse("tel:${android.net.Uri.encode(ussd)}")
            intent.flags = android.content.Intent.FLAG_ACTIVITY_NEW_TASK
            context.startActivity(intent)
            result.success(true)
            return
        }

        val tm = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager

        // Select subscription for the correct SIM slot
        val subId = getSubscriptionId(simSlot)
        val tmForSub = if (subId != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            tm.createForSubscriptionId(subId)
        } else {
            tm
        }

        try {
            tmForSub.sendUssdRequest(
                ussd,
                object : TelephonyManager.UssdResponseCallback() {
                    // SS codes (call forwarding *21*, ##21# etc.) are handled by the radio
                    // before the USSD layer, so this callback often never fires.
                    // We do NOT call result.success() here to avoid a duplicate-reply crash.
                    override fun onReceiveUssdResponse(tm: TelephonyManager, req: String, resp: CharSequence) {}
                    override fun onReceiveUssdResponseFailed(tm: TelephonyManager, req: String, failureCode: Int) {}
                },
                android.os.Handler(android.os.Looper.getMainLooper())
            )
            // Return success immediately so Flutter UI is not blocked.
            // The radio processes the forwarding request asynchronously.
            result.success(true)
        } catch (e: Exception) {
            result.error("USSD_FAILED", e.message, null)
        }
    }

    private fun getSubscriptionId(slotIndex: Int): Int? {
        return try {
            val sm = context.getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager
            val infos = sm.activeSubscriptionInfoList ?: return null
            infos.firstOrNull { it.simSlotIndex == slotIndex }?.subscriptionId
        } catch (e: Exception) { null }
    }
}

// ── SIM detection handler ───────────────────────────────────────────────────
class SimMethodHandler(private val context: Context) : MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "getSimSlots") {
            result.success(getSimSlots())
        } else {
            result.notImplemented()
        }
    }

    private fun getSimSlots(): List<Map<String, Any?>> {
        return try {
            val sm = context.getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager
            val infos = sm.activeSubscriptionInfoList ?: emptyList()
            infos.map { info ->
                mapOf(
                    "slotIndex"   to info.simSlotIndex,
                    "carrierName" to info.carrierName?.toString(),
                    "mccMnc"      to (info.mccString.orEmpty() + info.mncString.orEmpty()),
                    "phoneNumber" to info.number,
                    "isActive"    to true,
                )
            }
        } catch (e: Exception) {
            // Fallback single slot
            listOf(mapOf("slotIndex" to 0, "carrierName" to "Unknown", "mccMnc" to null,
                         "phoneNumber" to null, "isActive" to true))
        }
    }
}