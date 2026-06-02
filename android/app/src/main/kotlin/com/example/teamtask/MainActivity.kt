package com.example.teamtask

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity


class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleOAuthCallbackIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleOAuthCallbackIntent(intent)
    }

    private fun handleOAuthCallbackIntent(intent: Intent?) {
        if (intent == null) return
        if (intent.action != Intent.ACTION_VIEW) return

        val data = intent.data

        if (data == null) return

        // Supabase OAuth callback custom scheme
        if (data.scheme == "io.supabase.teamtask" && data.host == "login-callback") {
            // Important:
            // Consume the intent so Flutter/GoRouter won't try to parse it as a route.
            intent.replaceExtras(Bundle())
            setIntent(Intent())
            // Let supabase_flutter retrieve the session from the URL itself (in Dart).
            // We just ensure the deep link doesn't crash the router parser.
        }
    }
}

