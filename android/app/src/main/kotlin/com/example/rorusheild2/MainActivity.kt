package com.example.rorusheild2

import android.app.AppOpsManager
import android.app.usage.NetworkStats
import android.app.usage.NetworkStatsManager
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.TrafficStats
import android.net.VpnService
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.telephony.TelephonyManager
import android.view.accessibility.AccessibilityManager
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Environment
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.example.rorusheild2.MyVpnService
import java.util.Calendar

class MainActivity : FlutterActivity() {
    companion object {
        lateinit var channel: MethodChannel
        private var cachedAppUsage: List<Map<String, Any>>? = null
        private var lastCacheTime: Long = 0
        private const val CACHE_DURATION = 10000 // 10 saniye cache süresi
    }

    private val CHANNEL = "com.example.rorusheild2/accessibility"
    private val EVENT_CHANNEL = "com.example.rorusheild2/url_events"
    private val NETWORK_USAGE_CHANNEL = "com.example.rorusheild2/network_usage"
    private val APP_USAGE_CHANNEL = "com.example.rorusheild2/app_usage"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Kullanım erişimi iznini kontrol et – eksikse yönlendir
        if (!hasUsageAccessPermission()) {
            openUsageAccessSettings()
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Depolama izni yönetimi için yeni metot çağrısı
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.rorusheild2/storage_permission").setMethodCallHandler { call, result ->
            when (call.method) {
                "openStorageSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                        intent.data = android.net.Uri.parse("package:${applicationContext.packageName}")
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", "Ayarlar açılamadı", null)
                    }
                }
                "checkStoragePermission" -> {
                    val readPermission = checkSelfPermission(android.Manifest.permission.READ_EXTERNAL_STORAGE)
                    val writePermission = checkSelfPermission(android.Manifest.permission.WRITE_EXTERNAL_STORAGE)
                    result.success(readPermission == PackageManager.PERMISSION_GRANTED && writePermission == PackageManager.PERMISSION_GRANTED)
                }
                else -> result.notImplemented()
            }
        }

        // VPN ile ilgili kanal
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

        // Erişilebilirlik ve kullanım erişimi ayarları kanalı
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkAccessibilityPermission" -> result.success(isAccessibilityServiceEnabled())
                    "openAccessibilitySettings" -> {
                        openAccessibilitySettings()
                        result.success(null)
                    }
                    "openUsageAccessSettings" -> {
                        openUsageAccessSettings()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // Network kullanım verileri kanalı – TrafficStats API kullanımıyla
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NETWORK_USAGE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getDetailedNetworkUsage" -> {
                        try {
                            val usageMap = getDetailedNetworkUsage()
                            result.success(usageMap)
                        } catch (e: Exception) {
                            result.error("UNAVAILABLE", "Detaylı network bilgisi alınamadı: ${e.message}", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // Uygulama kullanım verilerini getiren kanal (mevcut UID bazlı ölçüm yöntemi)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_USAGE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAppUsage" -> {
                        try {
                            val currentTime = System.currentTimeMillis()
                            
                            // Önbellekteki veri 10 saniyeden yeni ise onu kullan
                            if (cachedAppUsage != null && (currentTime - lastCacheTime) < CACHE_DURATION) {
                                result.success(cachedAppUsage)
                                return@setMethodCallHandler
                            }

                            val appUsageHelper = AppUsageHelper(this)
                            val appUsageList = appUsageHelper.getAppUsage()
                            
                            // Sonucu önbelleğe al
                            cachedAppUsage = appUsageList
                            lastCacheTime = currentTime
                            
                            result.success(appUsageList)
                        } catch (e: Exception) {
                            result.error("UNAVAILABLE", "App usage data not available: ${e.message}", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // Event channel
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    events?.let { eventSink ->
                        UrlAccessibilityService.getInstance()?.setEventSink(eventSink)
                    }
                }
                override fun onCancel(arguments: Any?) {
                    UrlAccessibilityService.getInstance()?.setEventSink(null)
                }
            })
    }

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

    // Kullanım erişimi ayarlarına yönlendirme metodu
    private fun openUsageAccessSettings() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        startActivity(intent)
    }

    // TrafficStats API kullanarak anlık mobil veri kullanımını hesaplar
    private fun getMobileDataUsage(): Double {
        val mobileRx = TrafficStats.getMobileRxBytes()
        val mobileTx = TrafficStats.getMobileTxBytes()
        val mobileBytes = mobileRx + mobileTx
        return mobileBytes.toDouble() / (1024 * 1024 * 1024)
    }

    // TrafficStats API kullanarak Wi‑Fi veri kullanımını hesaplar
    private fun getWifiDataUsage(): Double {
        val totalRx = TrafficStats.getTotalRxBytes()
        val totalTx = TrafficStats.getTotalTxBytes()
        val mobileRx = TrafficStats.getMobileRxBytes()
        val mobileTx = TrafficStats.getMobileTxBytes()
        val wifiBytes = (totalRx - mobileRx) + (totalTx - mobileTx)
        return wifiBytes.toDouble() / (1024 * 1024 * 1024)
    }

    // Ayrı download & upload verilerini toplayan metot (AppUsageHelper ile entegre edilmiş)
    private fun getDetailedNetworkUsage(): Map<String, Double> {
        // Önce AppUsageHelper'dan uygulama kullanım verilerini al
        val appUsageHelper = AppUsageHelper(this)
        appUsageHelper.getAppUsage() // Bu çağrı totalNetworkStats'i güncelleyecek
        
        // AppUsageHelper'dan toplam değerleri al
        val totalStats = AppUsageHelper.totalNetworkStats
        
        // Eğer AppUsageHelper'dan gelen değerler sıfırsa, TrafficStats'ten al
        if (totalStats["totalUsage"] == 0.0) {
            val prefs = getSharedPreferences("network_stats", Context.MODE_PRIVATE)

            // Mevcut mobil veri değerlerini al
            val currentMobileRx = TrafficStats.getMobileRxBytes()
            val currentMobileTx = TrafficStats.getMobileTxBytes()

            // Son kaydedilen mobil veri değerlerini al
            val lastMobileRx = prefs.getLong("last_mobile_rx", currentMobileRx)
            val lastMobileTx = prefs.getLong("last_mobile_tx", currentMobileTx)

            // Eğer mevcut değerler 0 ise (WiFi bağlantısında), son kaydedilen değerleri kullan
            val mobileRx = if (currentMobileRx > 0) currentMobileRx else lastMobileRx
            val mobileTx = if (currentMobileTx > 0) currentMobileTx else lastMobileTx

            // Toplam veri değerlerini al
            val totalRx = TrafficStats.getTotalRxBytes()
            val totalTx = TrafficStats.getTotalTxBytes()

            // WiFi değerlerini hesapla (toplam - mobil)
            val wifiRx = totalRx - currentMobileRx
            val wifiTx = totalTx - currentMobileTx

            // Eğer mevcut mobil değerler 0'dan büyükse, değerleri kaydet
            if (currentMobileRx > 0 && currentMobileTx > 0) {
                prefs.edit().apply {
                    putLong("last_mobile_rx", currentMobileRx)
                    putLong("last_mobile_tx", currentMobileTx)
                    apply()
                }
            }

            fun bytesToGb(value: Long): Double {
                return value.toDouble() / (1024 * 1024 * 1024)
            }

            return mapOf(
                "mobileRx" to bytesToGb(mobileRx),
                "mobileTx" to bytesToGb(mobileTx),
                "wifiRx" to bytesToGb(wifiRx),
                "wifiTx" to bytesToGb(wifiTx),
                "totalRx" to bytesToGb(totalRx),  // Toplam download
                "totalTx" to bytesToGb(totalTx),  // Toplam upload
                "totalWifi" to bytesToGb(wifiRx) + bytesToGb(wifiTx),  // Toplam Wi-Fi
                "totalMobile" to bytesToGb(mobileRx) + bytesToGb(mobileTx)  // Toplam Mobile
            )
        } else {
            // AppUsageHelper'dan gelen toplam değerleri kullan
            return mapOf(
                "mobileRx" to totalStats["totalMobileUsage"]!! * 0.7,  // Mobil download (%70)
                "mobileTx" to totalStats["totalMobileUsage"]!! * 0.3,  // Mobil upload (%30)
                "wifiRx" to totalStats["totalWifiUsage"]!! * 0.7,     // WiFi download (%70)
                "wifiTx" to totalStats["totalWifiUsage"]!! * 0.3,     // WiFi upload (%30)
                "totalRx" to totalStats["totalDownload"]!!,           // Toplam download
                "totalTx" to totalStats["totalUpload"]!!,             // Toplam upload
                "totalWifi" to totalStats["totalWifiUsage"]!!,        // Toplam Wi-Fi
                "totalMobile" to totalStats["totalMobileUsage"]!!     // Toplam Mobile
            )
        }
    }

    private fun hasUsageAccessPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), packageName)
        } else {
            appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), packageName)
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }
}
