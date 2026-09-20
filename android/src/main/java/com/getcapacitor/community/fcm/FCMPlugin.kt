package com.getcapacitor.community.fcm

import android.util.Log
import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import com.google.firebase.installations.FirebaseInstallations
import com.google.firebase.messaging.FirebaseMessaging

/**
 * Please read the Capacitor Android Plugin Development Guide
 * here: https://capacitor.ionicframework.com/docs/plugins/android
 *
 * Created by Stewan Silva on 1/23/19.
 */
@CapacitorPlugin(name = "FCM")
public class FCMPlugin : Plugin() {
    @PluginMethod
    public fun subscribeTo(call: PluginCall) {
        // Firebase threw on a missing topic in the Java implementation as well.
        val topicName = call.getString("topic")!!

        FirebaseMessaging.getInstance()
            .subscribeToTopic(topicName)
            .addOnSuccessListener {
                val ret = JSObject()
                ret.put("message", "Subscribed to topic $topicName")
                call.resolve(ret)
            }
            .addOnFailureListener { e -> call.reject("Cant subscribe to topic$topicName", ex = e) }
    }

    @PluginMethod
    public fun unsubscribeFrom(call: PluginCall) {
        // Firebase threw on a missing topic in the Java implementation as well.
        val topicName = call.getString("topic")!!

        FirebaseMessaging.getInstance()
            .unsubscribeFromTopic(topicName)
            .addOnSuccessListener {
                val ret = JSObject()
                ret.put("message", "Unsubscribed from topic $topicName")
                call.resolve(ret)
            }
            .addOnFailureListener { e -> call.reject("Cant unsubscribe from topic$topicName", ex = e) }
    }

    @PluginMethod
    public fun deleteInstance(call: PluginCall) {
        FirebaseInstallations.getInstance()
            .delete()
            .addOnSuccessListener { call.resolve() }
            .addOnFailureListener { e ->
                e.printStackTrace()
                call.reject("Cant delete Firebase Instance ID", ex = e)
            }
    }

    @PluginMethod
    public fun getToken(call: PluginCall) {
        FirebaseMessaging.getInstance()
            .token
            .addOnCompleteListener(activity) { tokenResult ->
                if (!tokenResult.isSuccessful) {
                    val exception = tokenResult.exception
                    Log.w(TAG, "Fetching FCM registration token failed", exception)
                    call.errorCallback(exception?.localizedMessage)
                    return@addOnCompleteListener
                }
                val data = JSObject()
                data.put("token", tokenResult.result)
                call.resolve(data)
            }

        FirebaseMessaging.getInstance().token.addOnFailureListener { e -> call.reject("Failed to get FCM registration token", ex = e) }
    }

    @PluginMethod
    public fun refreshToken(call: PluginCall) {
        FirebaseMessaging.getInstance()
            .deleteToken()
            .addOnCompleteListener {
                FirebaseMessaging.getInstance()
                    .token
                    .addOnCompleteListener(activity) { tokenResult ->
                        val data = JSObject()
                        data.put("token", tokenResult.result)
                        call.resolve(data)
                    }
                    .addOnFailureListener { e -> call.reject("Failed to get FCM registration token", ex = e) }
            }
            .addOnFailureListener { e -> call.reject("Failed to delete FCM registration token", ex = e) }
    }

    @PluginMethod
    public fun setAutoInit(call: PluginCall) {
        val enabled = call.getBoolean("enabled", false) ?: false
        FirebaseMessaging.getInstance().isAutoInitEnabled = enabled
        call.resolve()
    }

    @PluginMethod
    public fun isAutoInitEnabled(call: PluginCall) {
        val enabled = FirebaseMessaging.getInstance().isAutoInitEnabled
        val data = JSObject()
        data.put("enabled", enabled)
        call.resolve(data)
    }

    public companion object {
        public const val TAG: String = "FirebaseMessaging"
    }
}
