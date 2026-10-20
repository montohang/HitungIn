package com.capt.hitungin

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Build
import android.os.Bundle

/**
 * Dibuka launcher untuk "Pengaturan"/"Atur ulang" widget (P2b). Widget dipasang
 * tanpa konfigurasi (configuration_optional, Android 12+), jadi activity ini
 * hanya muncul untuk widget yang sudah ada: hasil OK langsung dikirim, lalu
 * HitungIn dibuka di layar Atur widget.
 *
 * Di Android < 12 launcher selalu membukanya saat widget DIPASANG. Membuka
 * aplikasi di saat itu membuat launcher (mis. Samsung) membatalkan pemasangan,
 * jadi di sana cukup kirim OK dan selesai; gaya diatur dari Lainnya › Widget.
 */
class WidgetConfigActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val id = intent?.extras?.getInt(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
            ?: AppWidgetManager.INVALID_APPWIDGET_ID
        setResult(RESULT_OK, Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, id))
        if (id != AppWidgetManager.INVALID_APPWIDGET_ID) {
            HomeWidgets.refreshAll(this)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                startActivity(
                    Intent(this, RouteActivity::class.java).apply {
                        action = "com.capt.hitungin.WIDGET.$id"
                        putExtra(MainActivity.EXTRA_ROUTE, "/widget?id=$id")
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    },
                )
            }
        }
        finish()
    }
}
