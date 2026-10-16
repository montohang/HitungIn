package com.capt.hitungin

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle

/**
 * Dibuka launcher saat widget dipasang / "Atur ulang" (P2b). Widget langsung
 * dipasang dengan gaya bawaan, lalu HitungIn dibuka di layar Atur widget
 * (lewat PIN bila terkunci). Activity ini berjalan di task launcher, jadi
 * hanya finish() — bukan Entry (yang menghapus task).
 */
class WidgetConfigActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val id = intent?.extras?.getInt(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
            ?: AppWidgetManager.INVALID_APPWIDGET_ID
        setResult(RESULT_OK, Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, id))
        if (id != AppWidgetManager.INVALID_APPWIDGET_ID) {
            HomeWidgets.refreshAll(this)
            startActivity(
                Intent(this, RouteActivity::class.java).apply {
                    action = "com.capt.hitungin.WIDGET.$id"
                    putExtra(MainActivity.EXTRA_ROUTE, "/widget?id=$id")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                },
            )
        }
        finish()
    }
}
