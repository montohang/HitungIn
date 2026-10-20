package com.capt.hitungin

import android.app.WallpaperManager
import android.content.Context
import android.graphics.Color
import android.os.Build
import androidx.core.graphics.ColorUtils
import org.json.JSONArray
import org.json.JSONObject

/**
 * Aksen "Wallpaper" (P2b): warna paling berwarna dari wallpaper layar utama,
 * dibuat terbaca dengan teks putih — sama dengan lib/core/theme/accent_color.dart.
 * Dipakai aplikasi (kanal tema) dan widget (supaya warnanya ikut wallpaper
 * tanpa menunggu HitungIn dibuka).
 */
object WallpaperAccent {
    /** Warna mentah dari wallpaper; null bila tidak tersedia. */
    fun raw(context: Context): Int? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O_MR1) return null
        val colors = try {
            WallpaperManager.getInstance(context).getWallpaperColors(WallpaperManager.FLAG_SYSTEM)
        } catch (e: Exception) {
            null
        } ?: return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) context.getColor(android.R.color.system_accent1_600) else null
        val candidates = listOfNotNull(colors.primaryColor, colors.secondaryColor, colors.tertiaryColor).map { it.toArgb() }
        return candidates.maxByOrNull { c ->
            val hsv = FloatArray(3)
            Color.colorToHSV(c, hsv)
            hsv[1] * minOf(hsv[2], 1f - kotlin.math.abs(hsv[2] - 0.6f))
        } ?: candidates.firstOrNull()
    }

    private fun contrastOnWhite(c: Int): Double = 1.05 / (ColorUtils.calculateLuminance(c) + 0.05)

    /** Gelapkan sampai teks putih ≥ 4,5:1 (ensureWhiteContrast di Dart). */
    fun readable(c: Int): Int {
        val hsl = FloatArray(3)
        ColorUtils.colorToHSL(c, hsl)
        var out = c
        var i = 0
        while (i < 40 && contrastOnWhite(out) < 4.5) {
            hsl[2] = maxOf(0f, hsl[2] - 0.02f)
            out = ColorUtils.HSLToColor(hsl)
            i++
        }
        return out
    }

    /** Varian mode gelap (darkVariant di Dart). */
    fun darkVariant(light: Int): Int {
        val lifted = ColorUtils.blendARGB(light, Color.WHITE, 0.14f)
        return if (contrastOnWhite(lifted) >= 3) lifted else light
    }

    /** Aksen akhir untuk widget, atau null bila wallpaper tidak terbaca. */
    fun forWidget(context: Context, darkTheme: Boolean): Int? {
        val light = readable(raw(context) ?: return null)
        return if (darkTheme) darkVariant(light) else light
    }

    /** Ganti warna yang bergantung aksen di [look] (lihat WidgetLook.toJson). */
    fun repaint(look: JSONObject, accent: Int): JSONObject {
        val old = look.optLong("accent", 0).toInt()
        if (old == accent) return look
        val out = JSONObject(look.toString())
        when (look.optString("bg")) {
            "aksen" -> out.put("colors", JSONArray(listOf(accent.toLong() and 0xFFFFFFFFL)))
            "gradien" -> out.put("colors", JSONArray(gradient(look.optInt("gradient"), accent).map { it.toLong() and 0xFFFFFFFFL }))
        }
        for (key in listOf("button", "buttonIcon", "bar")) {
            if (look.optLong(key).toInt() == old) out.put(key, accent.toLong() and 0xFFFFFFFFL)
        }
        out.put("accent", accent.toLong() and 0xFFFFFFFFL)
        return out
    }

    /** Sama dengan widgetGradient() di Dart. */
    private fun gradient(i: Int, a: Int): List<Int> = when (i) {
        1 -> listOf(ColorUtils.blendARGB(a, Color.BLACK, 0.3f), ColorUtils.blendARGB(a, 0xFF2FA3C4.toInt(), 0.6f))
        2 -> listOf(ColorUtils.blendARGB(a, Color.WHITE, 0.75f), ColorUtils.blendARGB(a, Color.WHITE, 0.45f))
        else -> listOf(a, ColorUtils.blendARGB(a, 0xFFF2C14E.toInt(), 0.55f))
    }
}
