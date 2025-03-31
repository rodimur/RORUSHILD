package com.example.rorusheild2

import android.app.AppOpsManager
import android.app.usage.NetworkStats
import android.app.usage.NetworkStatsManager
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.VpnService
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.telephony.TelephonyManager
import android.view.accessibility.AccessibilityManager
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.example.rorusheild2.MyVpnService
import java.util.Calendar

class MainActivity : FlutterActivity() {
    companion object {
        lateinit var channel: MethodChannel
    }

    private val CHANNEL = "com.example.rorusheild2/accessibility"
    private val EVENT_CHANNEL = "com.example.rorusheild2/url_events"
    private val NETWORK_USAGE_CHANNEL = "com.example.rorusheild2/network_usage"
    // Uygulama kullanım verilerini sağlamak için yeni channel
    private val APP_USAGE_CHANNEL = "com.example.rorusheild2/app_usage"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Otomatik kullanım erişimi izni kontrolü
        if (!hasUsageAccessPermission()) {
            openUsageAccessSettings()
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // VPN channel
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

        // Erişilebilirlik ve kullanım erişimi ayarlarına yönlendirme için kanal
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkAccessibilityPermission" -> {
                        result.success(isAccessibilityServiceEnabled())
                    }
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

        // Network kullanım verileri (detaylı: download/upload vs.)
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

        // Uygulama kullanım verilerini getiren channel handler
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APP_USAGE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAppUsage" -> {
                        try {
                            val appUsageList = mutableListOf<Map<String, Any>>()
                            val networkStatsManager = getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager
                            // Son 7 gün için
                            val startTime = System.currentTimeMillis() - (7L * 24 * 60 * 60 * 1000)
                            val endTime = System.currentTimeMillis()

                            val pm = packageManager
                            val installedApps = pm.getInstalledApplications(PackageManager.GET_META_DATA)
                            val tempBucket = NetworkStats.Bucket()

                            for (app in installedApps) {
                                // Eğer uygulama sistem uygulaması VE güncellenmiş sistem uygulaması değilse atla.
                                if ((app.flags and ApplicationInfo.FLAG_SYSTEM) != 0 &&
                                    (app.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) == 0) {
                                    continue
                                }
                                try {
                                    val uid = app.uid

                                    // Mobil veri kullanımı sorgulaması
                                    val subscriberId = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                        ""
                                    } else {
                                        try {
                                            val tm = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
                                            tm.subscriberId ?: ""
                                        } catch (e: Exception) {
                                            ""
                                        }
                                    }
                                    val mobileBucket = networkStatsManager.queryDetailsForUid(
                                        ConnectivityManager.TYPE_MOBILE,
                                        subscriberId,
                                        startTime,
                                        endTime,
                                        uid
                                    )
                                    var mobileBytes = 0L
                                    while (mobileBucket.hasNextBucket()) {
                                        mobileBucket.getNextBucket(tempBucket)
                                        mobileBytes += tempBucket.rxBytes + tempBucket.txBytes
                                    }
                                    mobileBucket.close()

                                    // Wi-Fi kullanımı sorgulaması
                                    val wifiBucket = networkStatsManager.queryDetailsForUid(
                                        ConnectivityManager.TYPE_WIFI,
                                        "",
                                        startTime,
                                        endTime,
                                        uid
                                    )
                                    var wifiBytes = 0L
                                    while (wifiBucket.hasNextBucket()) {
                                        wifiBucket.getNextBucket(tempBucket)
                                        wifiBytes += tempBucket.rxBytes + tempBucket.txBytes
                                    }
                                    wifiBucket.close()

                                    val totalBytes = mobileBytes + wifiBytes
                                    val usageGB = totalBytes.toDouble() / (1024 * 1024 * 1024)
                                    val appLabel = pm.getApplicationLabel(app).toString()
                                    appUsageList.add(mapOf("appName" to appLabel, "usage" to usageGB))
                                } catch (ex: Exception) {
                                    continue
                                }
                            }
                            appUsageList.sortByDescending { it["usage"] as Double }
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

    private fun getMobileDataUsage(): Double {
        try {
            val networkStatsManager = getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager
            // Son 7 gün için
            val startTime = System.currentTimeMillis() - (7L * 24 * 60 * 60 * 1000)
            val endTime = System.currentTimeMillis()
            val telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
            val subscriberId = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) "" else {
                try {
                    telephonyManager.subscriberId ?: ""
                } catch (e: Exception) {
                    ""
                }
            }
            val bucket = networkStatsManager.querySummaryForDevice(
                ConnectivityManager.TYPE_MOBILE,
                subscriberId,
                startTime,
                endTime
            )
            val mobileBytes = bucket.rxBytes + bucket.txBytes
            return mobileBytes.toDouble() / (1024 * 1024 * 1024)
        } catch (e: Exception) {
            e.printStackTrace()
            return 0.0
        }
    }

    private fun getWifiDataUsage(): Double {
        try {
            val networkStatsManager = getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager
            // Son 7 gün için
            val startTime = System.currentTimeMillis() - (7L * 24 * 60 * 60 * 1000)
            val endTime = System.currentTimeMillis()
            val bucket = networkStatsManager.querySummaryForDevice(
                ConnectivityManager.TYPE_WIFI,
                "",
                startTime,
                endTime
            )
            val wifiBytes = bucket.rxBytes + bucket.txBytes
            return wifiBytes.toDouble() / (1024 * 1024 * 1024)
        } catch (e: Exception) {
            e.printStackTrace()
            return 0.0
        }
    }

    // Yeni: Ayrı download & upload verilerini toplayan metot
    private fun getDetailedNetworkUsage(): Map<String, Double> {
        // Son 7 gün
        val startTime = System.currentTimeMillis() - (7L * 24 * 60 * 60 * 1000)
        val endTime = System.currentTimeMillis()

        val networkStatsManager = getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager
        val telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        val subscriberId = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) "" else {
            try {
                telephonyManager.subscriberId ?: ""
            } catch (e: Exception) {
                ""
            }
        }

        var mobileRx = 0L
        var mobileTx = 0L
        var wifiRx = 0L
        var wifiTx = 0L

        // Mobil veri
        val mobileStats = networkStatsManager.querySummary(
            ConnectivityManager.TYPE_MOBILE,
            subscriberId,
            startTime,
            endTime
        )
        val mobileBucket = NetworkStats.Bucket()
        while (mobileStats.hasNextBucket()) {
            mobileStats.getNextBucket(mobileBucket)
            mobileRx += mobileBucket.rxBytes
            mobileTx += mobileBucket.txBytes
        }
        mobileStats.close()

        // Wi-Fi
        val wifiStats = networkStatsManager.querySummary(
            ConnectivityManager.TYPE_WIFI,
            "",
            startTime,
            endTime
        )
        val wifiBucket = NetworkStats.Bucket()
        while (wifiStats.hasNextBucket()) {
            wifiStats.getNextBucket(wifiBucket)
            wifiRx += wifiBucket.rxBytes
            wifiTx += wifiBucket.txBytes
        }
        wifiStats.close()

        fun bytesToGb(value: Long): Double {
            return value.toDouble() / (1024 * 1024 * 1024)
        }

        return mapOf(
            "mobileRx" to bytesToGb(mobileRx),
            "mobileTx" to bytesToGb(mobileTx),
            "wifiRx" to bytesToGb(wifiRx),
            "wifiTx" to bytesToGb(wifiTx)
        )
    }

    // Kullanım erişimi iznini kontrol eden metod
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
