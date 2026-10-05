package com.capt.hitungin

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FragmentActivity wajib untuk dialog sidik jari (local_auth).
class MainActivity : FlutterFragmentActivity() {

    /** Kunci varian (sama dengan AppIconVariant.key di Dart) → komponen peluncur. */
    private val iconComponents = linkedMapOf(
        "standar" to "com.capt.hitungin.LauncherActivity",
        "gelap" to "com.capt.hitungin.IconGelap",
        "emas" to "com.capt.hitungin.IconEmas",
        "terang" to "com.capt.hitungin.IconTerang",
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.capt.hitungin/app_icon").setMethodCallHandler { call, result ->
            when (call.method) {
                "get" -> result.success(currentIcon())
                "set" -> {
                    val key = call.argument<String>("key")
                    if (key == null || key !in iconComponents) {
                        result.error("bad_key", "Varian ikon tidak dikenal: $key", null)
                    } else {
                        setIcon(key)
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isEnabled(className: String): Boolean {
        val state = packageManager.getComponentEnabledSetting(ComponentName(this, className))
        // DEFAULT = ikuti android:enabled di manifest: hanya peluncur standar yang aktif.
        return when (state) {
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED -> true
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED -> false
            else -> className.endsWith(".LauncherActivity")
        }
    }

    private fun currentIcon(): String =
        iconComponents.entries.firstOrNull { isEnabled(it.value) }?.key ?: "standar"

    private fun setIcon(key: String) {
        // Aktifkan yang baru dulu supaya tidak ada saat tanpa ikon sama sekali.
        val pm = packageManager
        pm.setComponentEnabledSetting(
            ComponentName(this, iconComponents.getValue(key)),
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            PackageManager.DONT_KILL_APP,
        )
        for ((k, cls) in iconComponents) {
            if (k == key) continue
            pm.setComponentEnabledSetting(
                ComponentName(this, cls),
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                PackageManager.DONT_KILL_APP,
            )
        }
    }
}
