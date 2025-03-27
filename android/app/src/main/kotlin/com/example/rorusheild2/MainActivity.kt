package com.example.rorusheild2

import android.content.Intent
import android.net.VpnService
import android.provider.Settings
import android.view.accessibility.AccessibilityManager
import android.accessibilityservice.AccessibilityServiceInfo
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.example.rorusheild2.MyVpnService

class MainActivity : FlutterActivity() {
    companion object {
        lateinit var channel: MethodChannel
    }

    private val CHANNEL = "com.example.rorusheild2/accessibility"
    private val EVENT_CHANNEL = "com.example.rorusheild2/url_events"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.rorusheild2/vpn_channel")

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startVpn" -> {
                    val intent = VpnService.prepare(this)
                    if (intent != null) {
                        startActivityForResult(intent, 0)
                    } else {
                        startService(Intent(this, MyVpnService::class.java))
                        result.success("VPN Başlatıldı")
                    }
                }
                "stopVpn" -> {
                    val stopIntent = Intent(this, MyVpnService::class.java)
                    stopIntent.putExtra("COMMAND", "STOP")
                    startService(stopIntent)
                    result.success("VPN Durduruldu")
                }
                "checkVpnStatus" -> {
                    val vpnService = MyVpnService.instance
                    result.success(vpnService != null && vpnService.isRunning)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkAccessibilityPermission" -> {
                    result.success(isAccessibilityServiceEnabled())
                }
                "openAccessibilitySettings" -> {
                    openAccessibilitySettings()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    events?.let { eventSink ->
                        UrlAccessibilityService.getInstance()?.setEventSink(eventSink)
                    }
                }

                override fun onCancel(arguments: Any?) {
                    UrlAccessibilityService.getInstance()?.setEventSink(null)
                }
            }
        )
    }

    // `startActivityForResult` yerine Activity Result API'yi kullanmanızı öneririm
    // onActivityResult yerine yeni activity sonuçlarını işleme yöntemi kullanılabilir.
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 0) {
            if (resultCode == RESULT_OK) {
                startService(Intent(this, MyVpnService::class.java))
            } else {
                println("VPN için izin verilmedi")
            }
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val accessibilityManager = getSystemService(ACCESSIBILITY_SERVICE) as AccessibilityManager
        val enabledServices = accessibilityManager.getEnabledAccessibilityServiceList(
            AccessibilityServiceInfo.FEEDBACK_GENERIC
        )
        return enabledServices.any { it.id.contains(packageName) }
    }

    private fun openAccessibilitySettings() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        startActivity(intent)
    }
}
