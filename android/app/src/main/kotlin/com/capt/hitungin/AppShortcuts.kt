package com.capt.hitungin

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.drawable.Icon
import android.os.Build

/**
 * Pintasan tekan-lama ikon (P1-2). Dibuat dinamis dan ditempel ke peluncur
 * yang sedang aktif, supaya tetap muncul saat ikon alternatif dipakai.
 */
object AppShortcuts {
    fun publish(context: Context, launcher: ComponentName?) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N_MR1) return
        val sm = context.getSystemService(ShortcutManager::class.java) ?: return
        fun item(id: String, label: String, icon: Int, route: String): ShortcutInfo =
            ShortcutInfo.Builder(context, id)
                .setShortLabel(label)
                .setLongLabel(label)
                .setIcon(Icon.createWithResource(context, icon))
                .setIntent(
                    Intent(context, MainActivity::class.java).apply {
                        action = Intent.ACTION_VIEW
                        putExtra(MainActivity.EXTRA_ROUTE, route)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                    },
                )
                .apply { if (launcher != null) setActivity(launcher) }
                .build()
        try {
            sm.dynamicShortcuts = listOf(
                item("catat_keluar", context.getString(R.string.shortcut_out), R.drawable.ic_sc_out, "/catat"),
                item("catat_masuk", context.getString(R.string.shortcut_in), R.drawable.ic_sc_in, "/catat?kind=pemasukan"),
                item("pindah_saldo", context.getString(R.string.shortcut_tf), R.drawable.ic_sc_tf, "/catat?kind=transfer"),
                item("riwayat", context.getString(R.string.shortcut_hist), R.drawable.ic_sc_hist, "/riwayat"),
            )
        } catch (e: Exception) {
            // Launcher tanpa dukungan pintasan: abaikan.
        }
    }
}
