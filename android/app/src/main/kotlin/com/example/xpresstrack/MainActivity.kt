package com.example.xpresstrack

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        if (intent.action == android.content.Intent.ACTION_MAIN &&
            intent.hasCategory(android.content.Intent.CATEGORY_LAUNCHER)) {
            if (!isTaskRoot) {
                finish()
                return
            }
        }
        super.onCreate(savedInstanceState)
    }
}
