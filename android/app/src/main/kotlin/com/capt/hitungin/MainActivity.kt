package com.capt.hitungin

import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FragmentActivity wajib untuk dialog sidik jari (local_auth).
class MainActivity : FlutterFragmentActivity() {

    companion object {
        /** Route yang dibuka dari widget/tile/pintasan (lib/core/platform/launch_routes.dart). */
        const val EXTRA_ROUTE = "hitungin_route"

        private const val REQ_SHARE = 4101

        private var current: java.lang.ref.WeakReference<MainActivity>? = null
        private var queuedRoute: String? = null

        /** Ketukan notifikasi yang menunggu MainActivity dibuat (proses baru dimulai). */
        private var queuedIntent: Intent? = null

        /**
         * Teruskan intent (ketukan notifikasi) ke instans yang sedang berjalan. Bila
         * task masih tercatat tapi activity-nya sudah mati, intent disimpan dan
         * dipakai sebagai intent awal saat MainActivity dibuat ulang.
         */
        fun deliverIntent(intent: Intent) {
            val activity = current?.get()
            if (activity != null) activity.receive(intent) else queuedIntent = intent
        }

        /** Kirim route ke instans yang sedang berjalan (dari [Entry]). */
        fun deliver(route: String) {
            val activity = current?.get()
            if (activity != null) activity.deliverRoute(route) else queuedRoute = route
        }
    }

    private fun deliverRoute(route: String) {
        val channel = launchChannel
        if (channel != null) channel.invokeMethod("route", route) else pendingRoute = route
    }

    private var pendingRoute: String? = null
    private var launchChannel: MethodChannel? = null

    /** Selesai saat pengguna kembali dari menu Bagikan (lib/core/platform/share_text.dart). */
    private var shareResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        pendingRoute = intent?.getStringExtra(EXTRA_ROUTE) ?: queuedRoute
        queuedRoute = null
        // Plugin notifikasi membaca intent awal activity untuk payload ketukan.
        queuedIntent?.let { setIntent(it) }
        queuedIntent = null
        current = java.lang.ref.WeakReference(this)
        super.onCreate(savedInstanceState)
        AppShortcuts.publish(this, enabledLauncher())
    }

    /** Seperti intent baru dari sistem: plugin (notifikasi) ikut menerimanya. */
    fun receive(intent: Intent) = onNewIntent(intent)

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val route = intent.getStringExtra(EXTRA_ROUTE) ?: return
        deliverRoute(route)
    }

    @Deprecated("Dipakai untuk menu Bagikan; cukup sederhana tanpa Activity Result API.")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQ_SHARE) {
            shareResult?.success(null)
            shareResult = null
        }
    }

    override fun onDestroy() {
        if (current?.get() === this) current = null
        super.onDestroy()
    }

    /** Kunci varian (sama dengan AppIconVariant.key di Dart) → komponen peluncur. */
    private val iconComponents = linkedMapOf(
        "standar" to "com.capt.hitungin.LauncherActivity",
        "gelap" to "com.capt.hitungin.IconGelap",
        "emas" to "com.capt.hitungin.IconEmas",
        "terang" to "com.capt.hitungin.IconTerang",
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        launchChannel = MethodChannel(messenger, "com.capt.hitungin/launch").apply {
            setMethodCallHandler { call, result ->
                if (call.method == "initialRoute") {
                    result.success(pendingRoute)
                    pendingRoute = null
                } else {
                    result.notImplemented()
                }
            }
        }
        MethodChannel(messenger, "com.capt.hitungin/widget").setMethodCallHandler { call, result ->
            when (call.method) {
                "update" -> {
                    HomeWidgets.save(this, call.argument<String>("json") ?: "")
                    result.success(null)
                }
                "list" -> result.success(HomeWidgets.list(this))
                "pin" -> result.success(HomeWidgets.requestPin(this, call.argument<String>("kind") ?: "jatah"))
                else -> result.notImplemented()
            }
        }
        MethodChannel(messenger, "com.capt.hitungin/share").setMethodCallHandler { call, result ->
            if (call.method == "text") {
                val send = Intent(Intent.ACTION_SEND).apply {
                    type = "text/plain"
                    putExtra(Intent.EXTRA_TEXT, call.argument<String>("text") ?: "")
                }
                shareResult?.success(null)
                shareResult = result
                @Suppress("DEPRECATION")
                startActivityForResult(Intent.createChooser(send, call.argument<String>("title")), REQ_SHARE)
            } else {
                result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.capt.hitungin/app_icon").setMethodCallHandler { call, result ->
            when (call.method) {
                "get" -> result.success(currentIcon())
                "set" -> {
                    val key = call.argument<String>("key")
                    if (key == null || key !in iconComponents) {
                        result.error("bad_key", "Varian ikon tidak dikenal: $key", null)
                    } else {
                        // Diterapkan saat aplikasi ke latar (onStop): menonaktifkan ikon yang sedang
                        // dipakai bisa membuat launcher (mis. Samsung One UI) menutup aplikasi.
                        pendingIcon = if (key == appliedIcon()) null else key
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

    /** Varian yang dipilih tapi belum diterapkan (menunggu aplikasi ke latar). */
    private var pendingIcon: String? = null

    private fun enabledLauncher(): ComponentName? =
        iconComponents.values.firstOrNull { isEnabled(it) }?.let { ComponentName(this, it) }

    private fun appliedIcon(): String =
        iconComponents.entries.firstOrNull { isEnabled(it.value) }?.key ?: "standar"

    private fun currentIcon(): String = pendingIcon ?: appliedIcon()

    override fun onStop() {
        super.onStop()
        pendingIcon?.let {
            pendingIcon = null
            setIcon(it)
        }
    }

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
        // Pintasan ikut pindah ke peluncur yang baru.
        AppShortcuts.publish(this, ComponentName(this, iconComponents.getValue(key)))
    }
}
