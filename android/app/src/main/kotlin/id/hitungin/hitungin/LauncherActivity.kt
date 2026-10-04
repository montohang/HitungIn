package id.hitungin.hitungin

import android.app.Activity
import android.content.Intent
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
        startActivity(Intent(this, MainActivity::class.java))
        finish()
        // Tanpa animasi: tema peluncur = splash yang sama dengan MainActivity.
        @Suppress("DEPRECATION")
        overridePendingTransition(0, 0)
    }
}
