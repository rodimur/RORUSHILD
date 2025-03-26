package com.example.rorusheild2

import android.content.Intent
import android.net.VpnService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.example.rorusheild2.MyVpnService

class MainActivity : FlutterActivity() {
    companion object {
        lateinit var channel: MethodChannel
    }

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
                    // VPN servisini durdurma işlemi
                    stopService(Intent(this, MyVpnService::class.java))
                    result.success("VPN Durduruldu")
                }
                else -> result.notImplemented()
            }
        }
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
}
