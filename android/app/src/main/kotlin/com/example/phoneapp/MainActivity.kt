package com.example.phoneapp

import android.telephony.SubscriptionInfo
import android.telephony.SubscriptionManager
import android.telephony.TelephonyManager
import android.telephony.PhoneStateListener
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "sim_channel"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        // Listen for call state changes
        val telephonyManager = getSystemService(TELEPHONY_SERVICE) as TelephonyManager
        telephonyManager.listen(object : PhoneStateListener() {
            override fun onCallStateChanged(state: Int, phoneNumber: String?) {
                super.onCallStateChanged(state, phoneNumber)
                if (state == TelephonyManager.CALL_STATE_IDLE) {
                    // Call ended, notify Flutter
                    methodChannel.invokeMethod("callEnded", phoneNumber ?: "")
                }
            }
        }, PhoneStateListener.LISTEN_CALL_STATE)

        // Handle Flutter method calls
        methodChannel.setMethodCallHandler { call, result ->
            if (call.method == "getSimInfo") {
                try {
                    val simList = getInsertedSimInfo()
                    result.success(simList)
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getInsertedSimInfo(): List<Map<String, String>> {
        val subscriptionManager = getSystemService(TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager
        val telephonyManager = getSystemService(TELEPHONY_SERVICE) as TelephonyManager

        val activeSubs: List<SubscriptionInfo> = subscriptionManager.activeSubscriptionInfoList ?: emptyList()
        val simList = mutableListOf<Map<String, String>>()

        for (sub in activeSubs) {
            val simInfo = mapOf(
                "slotIndex" to sub.simSlotIndex.toString(),
                "carrierName" to sub.carrierName.toString(),
                "phoneNumber" to (sub.number ?: "N/A"),
                "countryIso" to (sub.countryIso ?: "N/A"),
                "simState" to telephonyManager.getSimState(sub.simSlotIndex).toString()
            )
            simList.add(simInfo)
        }
        return simList
    }
}
