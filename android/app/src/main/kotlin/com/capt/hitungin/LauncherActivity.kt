package com.capt.hitungin

import android.app.Activity
import android.os.Bundle

/**
 * Peluncur untuk ikon "Standar". Dibuat sebagai activity sungguhan (bukan
 * alias) supaya bisa dimatikan saat pengguna memilih ikon lain, dan supaya
 * `flutter run` tetap menemukan activity peluncur. Langsung meneruskan ke
 * [MainActivity]; temanya sama dengan splash, jadi perpindahannya tak terlihat.
 */
class LauncherActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Tanpa animasi: tema peluncur = splash yang sama dengan MainActivity.
        // Bila HitungIn sudah berjalan (mis. dibuka dari widget), task itu yang dipakai.
        Entry.open(this, null)
    }
}
