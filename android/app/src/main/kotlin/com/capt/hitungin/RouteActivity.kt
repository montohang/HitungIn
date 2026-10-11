package com.capt.hitungin

import android.app.Activity
import android.os.Bundle

/** Perantara tak terlihat untuk widget, tile Quick Settings & pintasan ikon. */
class RouteActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Entry.open(this, intent?.getStringExtra(MainActivity.EXTRA_ROUTE))
    }
}
