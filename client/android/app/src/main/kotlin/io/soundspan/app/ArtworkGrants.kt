package io.soundspan.app

import android.content.Context
import android.content.Intent
import android.net.Uri

/** Grants the Android Auto hosts read access to artwork content URIs. */
object ArtworkGrants {
    /** The browsing clients that load browse artwork: Android Auto on the
     *  phone and the Android Automotive media centre. */
    private val hosts = listOf(
        "com.google.android.projection.gearhead",
        "com.android.car.media",
    )

    fun grant(context: Context, uri: Uri) {
        if (uri.authority != "${context.packageName}.artwork") return
        for (host in hosts) {
            try {
                context.grantUriPermission(host, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
            } catch (_: Exception) {
                // The host is not installed.
            }
        }
    }
}
