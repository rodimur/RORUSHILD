package com.example.rorusheild2

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import io.flutter.plugin.common.EventChannel
import android.util.Log

class UrlAccessibilityService : AccessibilityService() {
    private val TAG = "UrlAccessibilityService"
    private var eventSink: EventChannel.EventSink? = null

    companion object {
        private var instance: UrlAccessibilityService? = null
        
        fun getInstance(): UrlAccessibilityService? {
            return instance
        }
    }

    override fun onServiceConnected() {
        instance = this
        val info = AccessibilityServiceInfo()
        info.apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                        AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED or
                        AccessibilityEvent.TYPE_VIEW_FOCUSED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS or
                    AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                    AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
            notificationTimeout = 100
        }
        serviceInfo = info
        Log.d(TAG, "Erişilebilirlik servisi başlatıldı")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (event.packageName == "com.android.chrome") {
            val rootNode = event.source ?: return
            try {
                findUrlInNode(rootNode)?.let { url ->
                    Log.d(TAG, "Tespit edilen URL: $url")
                    eventSink?.success(mapOf(
                        "type" to "url",
                        "url" to url
                    ))
                }
            } finally {
                rootNode.recycle()
            }
        }
    }

    private fun findUrlInNode(node: AccessibilityNodeInfo): String? {
        // Chrome'un URL çubuğunu bul
        val urlBar = node.findAccessibilityNodeInfosByViewId("com.android.chrome:id/url_bar")
        if (!urlBar.isNullOrEmpty()) {
            val url = urlBar[0].text?.toString()
            urlBar.forEach { it.recycle() }
            if (url != null && (url.startsWith("http://") || url.startsWith("https://"))) {
                return url
            }
        }

        // Alt düğümlerde arama yap
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            try {
                findUrlInNode(child)?.let { return it }
            } finally {
                child.recycle()
            }
        }

        return null
    }

    override fun onInterrupt() {
        Log.d(TAG, "Erişilebilirlik servisi kesintiye uğradı")
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        Log.d(TAG, "Erişilebilirlik servisi sonlandırıldı")
    }

    fun setEventSink(sink: EventChannel.EventSink?) {
        eventSink = sink
    }
} 