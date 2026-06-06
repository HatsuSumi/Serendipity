package com.serendipity.serendipity_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NOTIFICATION_CACHE_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "recoverScheduledNotificationCache" -> {
                    val notificationId = call.argument<Int>("id")
                    if (notificationId == null) {
                        result.error("invalid_args", "Notification id is required", null)
                        return@setMethodCallHandler
                    }

                    recoverScheduledNotificationCache(notificationId)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun recoverScheduledNotificationCache(notificationId: Int) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as? AlarmManager
        val intent = Intent().setClassName(
            applicationContext,
            SCHEDULED_NOTIFICATION_RECEIVER,
        )
        val pendingIntent = PendingIntent.getBroadcast(
            applicationContext,
            notificationId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        alarmManager?.cancel(pendingIntent)
        pendingIntent.cancel()

        applicationContext
            .getSharedPreferences(SCHEDULED_NOTIFICATIONS_PREFS, Context.MODE_PRIVATE)
            .edit()
            .remove(SCHEDULED_NOTIFICATIONS_KEY)
            .apply()
    }

    companion object {
        private const val NOTIFICATION_CACHE_CHANNEL =
            "com.serendipity.notification_cache"
        private const val SCHEDULED_NOTIFICATIONS_PREFS =
            "scheduled_notifications"
        private const val SCHEDULED_NOTIFICATIONS_KEY =
            "scheduled_notifications"
        private const val SCHEDULED_NOTIFICATION_RECEIVER =
            "com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"
    }
}
