package com.afalphy.audio_tags_lofty

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin

class AudioTagsLoftyPlugin: FlutterPlugin {

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        // You can load your Rust FFI library here if you want
        // System.loadLibrary("lofty_ffi")
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        // clean up if needed
    }
}
