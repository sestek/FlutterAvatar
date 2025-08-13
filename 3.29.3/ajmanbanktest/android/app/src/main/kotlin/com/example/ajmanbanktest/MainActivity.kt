package com.example.ajmanbanktest

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.webkit.WebView
import android.webkit.WebSettings

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // WebView için mikrofon erişimini etkinleştir
        WebView.setWebContentsDebuggingEnabled(true)
    }
}
