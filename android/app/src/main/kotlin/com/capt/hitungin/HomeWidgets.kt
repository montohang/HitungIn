package com.capt.hitungin

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Widget layar utama (P1-2). Widget TIDAK membaca database terenkripsi:
 * aplikasi mengirim ringkasan kecil (lib/features/home/widget_sync.dart) yang
 * disimpan di sini. Ringkasan dari hari lain tidak ditampilkan.
 */
object HomeWidgets {
    private const val PREFS = "hitungin_widget"
    private const val KEY = "json"

    fun save(context: Context, json: String) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(KEY, json).apply()
        refreshAll(context)
    }

    fun refreshAll(context: Context) {
        val mgr = AppWidgetManager.getInstance(context)
        for ((cls, render) in listOf<Pair<Class<*>, (Context) -> RemoteViews>>(
            JatahWidget::class.java to ::jatahViews,
            CatatWidget::class.java to ::catatViews,
        )) {
            val ids = mgr.getAppWidgetIds(ComponentName(context, cls))
            if (ids.isNotEmpty()) mgr.updateAppWidget(ids, render(context))
        }
    }

    /** Buka aplikasi di [route] (lewat layar PIN bila terkunci). */
    fun launch(context: Context, route: String, requestCode: Int): PendingIntent {
        val intent = Intent(context, RouteActivity::class.java).apply {
            action = "com.capt.hitungin.OPEN.$requestCode"
            putExtra(MainActivity.EXTRA_ROUTE, route)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        return PendingIntent.getActivity(
            context, requestCode, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    private fun snapshot(context: Context): JSONObject? {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, null) ?: return null
        val json = try { JSONObject(raw) } catch (e: Exception) { return null }
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        return if (json.optString("date") == today) json else null
    }

    fun catatViews(context: Context): RemoteViews =
        RemoteViews(context.packageName, R.layout.widget_catat).apply {
            setTextViewText(R.id.motivation, motivationOfToday(context))
            setOnClickPendingIntent(R.id.widget_root, launch(context, "/catat", 10))
        }

    /** Kalimat penyemangat, berganti setiap hari (sama sepanjang hari itu). */
    private fun motivationOfToday(context: Context): String {
        val lines = context.resources.getStringArray(R.array.widget_motivation)
        val day = java.util.Calendar.getInstance().get(java.util.Calendar.DAY_OF_YEAR)
        return lines[day % lines.size]
    }

    fun jatahViews(context: Context): RemoteViews {
        val v = RemoteViews(context.packageName, R.layout.widget_jatah)
        val s = snapshot(context)
        v.setOnClickPendingIntent(R.id.btn_catat, launch(context, "/catat", 20))
        if (s == null) {
            v.setTextViewText(R.id.jatah, "—")
            v.setTextViewText(R.id.line, context.getString(R.string.widget_stale))
            v.setProgressBar(R.id.progress, 100, 0, false)
            v.setViewVisibility(R.id.favs, View.GONE)
            v.setOnClickPendingIntent(R.id.widget_root, launch(context, "/home", 21))
            return v
        }
        v.setTextViewText(R.id.jatah, s.optString("jatah", "—"))
        v.setTextViewText(R.id.line, s.optString("line", ""))
        v.setProgressBar(R.id.progress, 100, s.optInt("progress", 0), false)
        v.setTextColor(
            R.id.line,
            context.getColor(if (s.optBoolean("warn")) R.color.widget_warn else R.color.widget_muted),
        )
        v.setOnClickPendingIntent(R.id.widget_root, launch(context, "/home", 21))
        val favs = s.optJSONArray("favs")
        val ids = intArrayOf(R.id.fav0, R.id.fav1, R.id.fav2)
        val count = favs?.length() ?: 0
        v.setViewVisibility(R.id.favs, if (count == 0) View.GONE else View.VISIBLE)
        for (i in ids.indices) {
            val f = if (i < count) favs!!.optJSONObject(i) else null
            if (f == null) {
                v.setViewVisibility(ids[i], View.INVISIBLE)
                continue
            }
            v.setViewVisibility(ids[i], View.VISIBLE)
            v.setTextViewText(ids[i], f.optString("label") + "  " + f.optString("amount"))
            v.setOnClickPendingIntent(ids[i], launch(context, f.optString("route", "/catat"), 30 + i))
        }
        return v
    }
}

/** Widget sedang 4×2: Jatah hari ini + Catat + 3 favorit. */
class JatahWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        manager.updateAppWidget(ids, HomeWidgets.jatahViews(context))
    }
}

/** Widget kecil 2×1: tombol Catat. */
class CatatWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        manager.updateAppWidget(ids, HomeWidgets.catatViews(context))
    }
}
