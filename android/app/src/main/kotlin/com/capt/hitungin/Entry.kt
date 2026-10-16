package com.capt.hitungin

import android.app.Activity
import android.app.ActivityManager
import android.content.Intent

/**
 * Satu pintu masuk untuk ikon peluncur, widget, tile & pintasan (P1-2).
 * MainActivity memakai taskAffinity="" (template Flutter), jadi intent dari luar
 * dengan NEW_TASK akan membuat task — dan mesin Flutter — kedua. Di sini task
 * HitungIn yang sudah ada dibawa ke depan dan route dikirim ke instans itu.
 */
object Entry {
    /** Aksi intent ketukan notifikasi dari flutter_local_notifications. */
    private const val SELECT_NOTIFICATION = "SELECT_NOTIFICATION"

    /**
     * [route] = layar tujuan (widget/tile/pintasan). Ketukan notifikasi
     * (aksi SELECT_NOTIFICATION) diteruskan utuh ke MainActivity supaya plugin
     * notifikasi membaca payload-nya; tanpa ini ketukan hanya membuka aplikasi.
     */
    fun open(activity: Activity, route: String?) {
        val notification = activity.intent?.takeIf { it.action == SELECT_NOTIFICATION }
        val main = MainActivity::class.java.name
        val existing = activity.getSystemService(ActivityManager::class.java)?.appTasks?.firstOrNull { task ->
            val info = try { task.taskInfo } catch (e: Exception) { null } ?: return@firstOrNull false
            info.taskId != activity.taskId &&
                (info.topActivity?.className == main || info.baseActivity?.className == main)
        }
        if (existing != null) {
            if (route != null) MainActivity.deliver(route)
            if (notification != null) MainActivity.deliverIntent(Intent(notification))
            existing.moveToFront()
        } else {
            activity.startActivity(
                (if (notification != null) Intent(notification) else Intent()).apply {
                    setClass(activity, MainActivity::class.java)
                    // Selalu task sendiri untuk MainActivity: task pintu masuk dihapus di bawah,
                    // dan task RouteActivity dikecualikan dari Recent apps.
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    if (route != null) putExtra(MainActivity.EXTRA_ROUTE, route)
                },
            )
        }
        // Task pintu masuk ini kosong setelah ditutup; hapus supaya Recent apps
        // tidak menampilkan HitungIn dua kali.
        activity.finishAndRemoveTask()
        @Suppress("DEPRECATION")
        activity.overridePendingTransition(0, 0)
    }
}
