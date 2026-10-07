package com.chatverse.chatverse_mobile

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.graphics.Color
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val notificationChannelId = "resender_messages"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.resender/notifications")
            .setMethodCallHandler { call, result ->
                if (call.method != "showIncomingMessage") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val title = call.argument<String>("title") ?: "New ReSender message"
                val body = call.argument<String>("body") ?: "You have a new message."
                val id = call.argument<Int>("id") ?: (System.currentTimeMillis() % Int.MAX_VALUE).toInt()
                showIncomingMessage(title, body, id)
                result.success(null)
            }
    }

    private fun showIncomingMessage(title: String, body: String, id: Int) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    notificationChannelId,
                    "Messages",
                    NotificationManager.IMPORTANCE_HIGH,
                ).apply {
                    description = "Notifications for incoming ReSender messages"
                    enableLights(true)
                    lightColor = Color.rgb(255, 122, 0)
                    enableVibration(true)
                },
            )
        }

        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val contentIntent = launchIntent?.let {
            PendingIntent.getActivity(
                this,
                0,
                it,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, notificationChannelId)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setColor(Color.rgb(255, 122, 0))
            .setAutoCancel(true)

        if (contentIntent != null) builder.setContentIntent(contentIntent)
        manager.notify(id, builder.build())
    }
}
