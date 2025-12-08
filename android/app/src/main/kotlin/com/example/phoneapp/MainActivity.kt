package com.example.phoneapp

import android.telephony.SubscriptionInfo
import android.telephony.SubscriptionManager
import android.telephony.TelephonyManager
import android.telephony.PhoneStateListener
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {

    private val CHANNEL = "sim_channel"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSimInfo" -> {
                        try {
                            val simList = getInsertedSimInfo()
                            result.success(simList)
                        } catch (e: Exception) {
                            result.error("ERROR", e.message, null)
                        }
                    }
                    "startCallListener" -> {
                        val number = call.argument<String>("number") ?: ""
                        startCallListener(number)
                        result.success("Listening for call state")
                    }
                    else -> {
                        result.notImplemented()
                    }
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

    private fun startCallListener(number: String) {
        val telephonyManager = getSystemService(TELEPHONY_SERVICE) as TelephonyManager

        telephonyManager.listen(object : PhoneStateListener() {
            var isCallStarted = false

            override fun onCallStateChanged(state: Int, incomingNumber: String?) {
                super.onCallStateChanged(state, incomingNumber)

                when (state) {
                    TelephonyManager.CALL_STATE_OFFHOOK -> {
                        isCallStarted = true
                    }
                    TelephonyManager.CALL_STATE_IDLE -> {
                        if (isCallStarted) {
                            // Notify Flutter
                            MethodChannel(
                                this@MainActivity.flutterEngine!!.dartExecutor.binaryMessenger,
                                CHANNEL
                            ).invokeMethod("callEnded", number)
                            isCallStarted = false
                        }
                    }
                }
            }
        }, PhoneStateListener.LISTEN_CALL_STATE)
    }
}
