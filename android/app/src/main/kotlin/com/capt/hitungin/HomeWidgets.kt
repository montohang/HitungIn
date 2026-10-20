package com.capt.hitungin

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.res.ColorStateList
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.BitmapShader
import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Shader
import android.os.Build
import android.os.Bundle
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject
import java.io.File
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
        for (id in mgr.getAppWidgetIds(ComponentName(context, JatahWidget::class.java))) {
            mgr.updateAppWidget(id, jatahViews(context, id))
        }
        for (id in mgr.getAppWidgetIds(ComponentName(context, CatatWidget::class.java))) {
            mgr.updateAppWidget(id, catatViews(context, id))
        }
    }

    /** Widget terpasang: id & jenis (untuk layar Atur widget). */
    fun list(context: Context): List<Map<String, Any>> {
        val mgr = AppWidgetManager.getInstance(context)
        return mgr.getAppWidgetIds(ComponentName(context, JatahWidget::class.java)).map { mapOf("id" to it, "kind" to "jatah") } +
            mgr.getAppWidgetIds(ComponentName(context, CatatWidget::class.java)).map { mapOf("id" to it, "kind" to "catat") }
    }

    /** Minta launcher memasang widget baru (Android 8+, bila launcher mendukung). */
    fun requestPin(context: Context, kind: String): Boolean {
        val mgr = AppWidgetManager.getInstance(context)
        if (!mgr.isRequestPinAppWidgetSupported) return false
        val cls = if (kind == "catat") CatatWidget::class.java else JatahWidget::class.java
        return mgr.requestPinAppWidget(ComponentName(context, cls), null, null)
    }

    // ---- Gaya per widget (P2b): lihat lib/features/widgets/data/widget_style.dart ----

    private fun lookOf(context: Context, id: Int): JSONObject? {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, null) ?: return null
        val json = try { JSONObject(raw) } catch (e: Exception) { return null }
        val look = json.optJSONObject("looks")?.optJSONObject(id.toString()) ?: json.optJSONObject("look") ?: return null
        if (!json.optBoolean("accentFromWallpaper")) return look
        // Aksen "Wallpaper": ambil warna wallpaper sekarang, bukan saat aplikasi terakhir dibuka.
        val accent = WallpaperAccent.forWidget(context, json.optBoolean("darkTheme", true)) ?: return look
        return WallpaperAccent.repaint(look, accent)
    }

    private fun dp(context: Context, v: Float): Float =
        TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, v, context.resources.displayMetrics)

    /**
     * Ukuran bitmap latar (px) dari opsi launcher (potret = lebar min × tinggi maks)
     * dan skala px-per-dp-nya (diperkecil bila bitmap terlalu besar).
     */
    private fun sizePx(context: Context, id: Int, fallbackW: Float, fallbackH: Float): Triple<Int, Int, Float> {
        val o: Bundle = AppWidgetManager.getInstance(context).getAppWidgetOptions(id)
        val w = o.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH).takeIf { it > 0 }?.toFloat() ?: fallbackW
        val h = o.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT).takeIf { it > 0 }?.toFloat() ?: fallbackH
        var pw = dp(context, w)
        var ph = dp(context, h)
        // Batas memori RemoteViews: ±1,5 MB per bitmap.
        val scale = minOf(1f, kotlin.math.sqrt(1_500_000f / 4f / (pw * ph)))
        pw *= scale
        ph *= scale
        return Triple(pw.toInt().coerceAtLeast(1), ph.toInt().coerceAtLeast(1), context.resources.displayMetrics.density * scale)
    }

    /** Latar: warna/gradien atau foto (dipotong menurut focusY) + lapisan, sudut, alfa. */
    private fun background(context: Context, look: JSONObject, w: Int, h: Int, density: Float): Bitmap {
        val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val radius = look.optInt("radius", 24) * density
        val rect = RectF(0f, 0f, w.toFloat(), h.toFloat())
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        paint.alpha = look.optInt("alpha", 255)
        val photo = look.optString("photo", "").takeIf { it.isNotEmpty() }?.let { decodePhoto(it, w, h) }
        if (photo != null) {
            val shader = BitmapShader(photo, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP)
            val s = maxOf(w.toFloat() / photo.width, h.toFloat() / photo.height)
            val dy = (h - photo.height * s) * look.optDouble("focusY", 0.5).toFloat()
            val dx = (w - photo.width * s) / 2f
            shader.setLocalMatrix(Matrix().apply { setScale(s, s); postTranslate(dx, dy) })
            paint.shader = shader
            canvas.drawRoundRect(rect, radius, radius, paint)
            val scrim = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = look.optLong("scrim", 0).toInt() }
            scrim.alpha = scrim.alpha * look.optInt("alpha", 255) / 255
            canvas.drawRoundRect(rect, radius, radius, scrim)
        } else {
            val colors = look.optJSONArray("colors")
            val c0 = colors?.optLong(0)?.toInt() ?: context.getColor(R.color.widget_bg)
            if (colors != null && colors.length() > 1) {
                paint.shader = LinearGradient(0f, 0f, w.toFloat(), h.toFloat(), c0, colors.optLong(1).toInt(), Shader.TileMode.CLAMP)
            } else {
                paint.color = c0
            }
            paint.alpha = look.optInt("alpha", 255) * ((c0 ushr 24) and 0xFF) / 255
            canvas.drawRoundRect(rect, radius, radius, paint)
        }
        return bmp
    }

    private fun decodePhoto(path: String, w: Int, h: Int): Bitmap? {
        val f = File(path)
        if (!f.exists()) return null
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(path, bounds)
        var sample = 1
        while (bounds.outWidth / (sample * 2) >= w && bounds.outHeight / (sample * 2) >= h) sample *= 2
        return BitmapFactory.decodeFile(path, BitmapFactory.Options().apply { inSampleSize = sample })
    }

    private fun color(look: JSONObject?, key: String, fallback: Int): Int =
        if (look != null && look.has(key)) look.optLong(key).toInt() else fallback

    /** Latar, tombol, & warna teks bersama kedua widget. */
    private fun applyLook(context: Context, v: RemoteViews, id: Int, look: JSONObject?, wDp: Float, hDp: Float) {
        if (look == null) return
        val (w, h, density) = sizePx(context, id, wDp, hDp)
        v.setImageViewBitmap(R.id.bg, background(context, look, w, h, density))
        v.setInt(R.id.btn_bg, "setColorFilter", color(look, "button", context.getColor(R.color.widget_accent)))
        v.setInt(R.id.btn_icon, "setColorFilter", color(look, "buttonIcon", 0xFFFFFFFF.toInt()))
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

    fun catatViews(context: Context, id: Int): RemoteViews =
        RemoteViews(context.packageName, R.layout.widget_catat).apply {
            val look = lookOf(context, id)
            applyLook(context, this, id, look, 180f, 70f)
            if (look != null) {
                setTextColor(R.id.title, color(look, "ink", context.getColor(R.color.widget_ink)))
                setTextColor(R.id.motivation, color(look, "muted", context.getColor(R.color.widget_muted)))
            }
            setTextViewText(R.id.motivation, motivationOfToday(context))
            setOnClickPendingIntent(R.id.widget_root, launch(context, "/catat", 10))
        }

    /** Kalimat penyemangat, berganti setiap hari (sama sepanjang hari itu). */
    private fun motivationOfToday(context: Context): String {
        val lines = context.resources.getStringArray(R.array.widget_motivation)
        val day = java.util.Calendar.getInstance().get(java.util.Calendar.DAY_OF_YEAR)
        return lines[day % lines.size]
    }

    fun jatahViews(context: Context, id: Int): RemoteViews {
        val v = RemoteViews(context.packageName, R.layout.widget_jatah)
        val s = snapshot(context)
        val look = lookOf(context, id)
        applyLook(context, v, id, look, 320f, 150f)
        val ink = color(look, "ink", context.getColor(R.color.widget_ink))
        val muted = color(look, "muted", context.getColor(R.color.widget_muted))
        if (look != null) {
            v.setTextColor(R.id.jatah, ink)
            v.setTextColor(R.id.label, muted)
            v.setTextColor(R.id.line, muted)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                v.setColorStateList(R.id.progress, "setProgressTintList", ColorStateList.valueOf(color(look, "bar", 0)))
                v.setColorStateList(R.id.progress, "setProgressBackgroundTintList", ColorStateList.valueOf(color(look, "track", 0)))
            }
        }
        val masked = look?.optBoolean("hide") == true && s != null
        val mask = s?.optJSONObject("masked")
        v.setOnClickPendingIntent(R.id.btn_catat, launch(context, "/catat", 20))
        if (s == null) {
            v.setTextViewText(R.id.jatah, "—")
            v.setTextViewText(R.id.line, context.getString(R.string.widget_stale))
            v.setProgressBar(R.id.progress, 100, 0, false)
            v.setViewVisibility(R.id.favs, View.GONE)
            v.setOnClickPendingIntent(R.id.widget_root, launch(context, "/home", 21))
            return v
        }
        v.setTextViewText(R.id.jatah, if (masked) mask?.optString("jatah") ?: "Rp ••••" else s.optString("jatah", "—"))
        v.setTextViewText(R.id.line, if (masked) mask?.optString("line") ?: "" else s.optString("line", ""))
        v.setProgressBar(R.id.progress, 100, if (masked) 0 else s.optInt("progress", 0), false)
        v.setTextColor(
            R.id.line,
            if (s.optBoolean("warn") && !masked) color(look, "warn", context.getColor(R.color.widget_warn)) else muted,
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
            val amount = if (masked) mask?.optString("fav") ?: "••" else f.optString("amount")
            v.setTextViewText(ids[i], f.optString("label") + "  " + amount)
            if (look != null) {
                v.setTextColor(ids[i], ink)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    v.setColorStateList(ids[i], "setBackgroundTintList", ColorStateList.valueOf(color(look, "chip", 0)))
                }
            }
            v.setOnClickPendingIntent(ids[i], launch(context, f.optString("route", "/catat"), 30 + i))
        }
        return v
    }
}

/** Widget sedang 4×2: Jatah hari ini + Catat + 3 favorit. */
class JatahWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) manager.updateAppWidget(id, HomeWidgets.jatahViews(context, id))
    }

    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: Bundle) {
        manager.updateAppWidget(id, HomeWidgets.jatahViews(context, id))
    }
}

/** Widget kecil 2×1: tombol Catat. */
class CatatWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) manager.updateAppWidget(id, HomeWidgets.catatViews(context, id))
    }

    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: Bundle) {
        manager.updateAppWidget(id, HomeWidgets.catatViews(context, id))
    }
}
