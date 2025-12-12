package com.example.flutter_map_training

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat

class LocationTrackingNotificationManager(private val context: Context) {
    private val notificationManager =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    private val channelId = "location_tracking_live_update"
    private val channelName = "Location Tracking Live Update"

    private val notificationId = 1

    private fun initialize() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                channelName,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Map Tracking Live Update"
                setSound(null, null)
                enableVibration(false)
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    fun startLiveActivity(data: Map<String, Any>?) {
        initialize()
        updateNotification(data)
    }

    fun updateLiveActivity(data: Map<String, Any>?) {
        updateNotification(data)
    }

    fun endLiveActivity() {
        notificationManager.cancel(notificationId)
    }

    private fun updateNotification(data: Map<String, Any>?) {
        if (data == null) return

        val distance = data["remainingDistanceStr"] as? String ?: ""
        val progress = (data["progress"] as? Int) ?: 0
        val minutes = (data["minutesToArrive"] as? Int) ?: 0

        val remoteViews: RemoteViews = if (progress >= 100) {
            // --- TRƯỜNG HỢP: ĐÃ ĐẾN NƠI ---
            RemoteViews(context.packageName, R.layout.notification_arrived_layout).apply {
                setTextViewText(R.id.tv_arrived_title, "Đã đến đích!")
                setTextViewText(R.id.tv_arrived_desc, "Chúc một ngày tốt lành!")
            }
        } else {
            // --- TRƯỜNG HỢP: ĐANG DI CHUYỂN ---
            RemoteViews(context.packageName, R.layout.custom_notification_layout).apply {
                setTextViewText(R.id.tvProgress, "$progress %")
                setTextViewText(R.id.tv_distance, distance)
                setTextViewText(
                    R.id.tv_minutes,
                    if (minutes <= 0) "Ít hơn 1 phút" else "$minutes phút"
                )
                setProgressBar(R.id.progress_bar, 100, progress, false)
            }
        }

        val intent = Intent(context, MainActivity::class.java)
        intent.flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        // Build Notification
        val notificationBuilder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setCustomContentView(remoteViews)
            .setCustomBigContentView(remoteViews)
            .setContentIntent(pendingIntent)
            .setOnlyAlertOnce(true)
            .setRequestPromotedOngoing(true)

        if (progress >= 100) {
            // Khi đến nơi, bạn có thể cho phép vuốt để xóa (bỏ setOngoing true)
            // Hoặc giữ nguyên true nếu muốn user phải vào app bấm nút "Kết thúc"
            notificationBuilder.setOngoing(true)
        } else {
            // Khi đang đi, bắt buộc không cho vuốt xóa
            notificationBuilder.setOngoing(true)
        }

        notificationManager.notify(notificationId, notificationBuilder.build())
    }
}