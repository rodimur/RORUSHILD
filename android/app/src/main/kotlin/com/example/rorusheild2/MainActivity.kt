package com.example.rorusheild2

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.app.AppOpsManager
import android.content.Intent
import android.provider.Settings
import android.os.Process
import android.net.TrafficStats
import android.content.pm.PackageManager
import android.util.Log
import kotlinx.coroutines.*
import java.util.concurrent.atomic.AtomicBoolean
import androidx.annotation.NonNull

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.rorusheild2/network_usage"
    private val TAG = "MainActivity"
    private val scope = CoroutineScope(Dispatchers.Default + Job())
    private val isDisposed = AtomicBoolean(false)

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(NetworkUsagePlugin())

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkUsagePermission" -> {
                    Log.d(TAG, "checkUsagePermission çağrıldı")
                    scope.launch(Dispatchers.IO) {
                        val hasPermission = checkUsageStatsPermission()
                        withContext(Dispatchers.Main) {
                            Log.d(TAG, "İzin durumu: $hasPermission")
                            result.success(hasPermission)
                        }
                    }
                }
                "requestUsagePermission" -> {
                    Log.d(TAG, "requestUsagePermission çağrıldı")
                    scope.launch(Dispatchers.Main) {
                        try {
                            requestUsageStatsPermission()
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e(TAG, "İzin isteme hatası: ${e.message}")
                            result.error("PERMISSION_ERROR", e.message, null)
                        }
                    }
                }
                "getTotalNetworkUsage" -> {
                    scope.launch(Dispatchers.IO) {
                        if (checkUsageStatsPermission()) {
                            val usage = getTotalNetworkUsage()
                            withContext(Dispatchers.Main) {
                                result.success(usage)
                            }
                        } else {
                            withContext(Dispatchers.Main) {
                                result.error("PERMISSION_DENIED", "Usage access not granted", null)
                            }
                        }
                    }
                }
                "getAppNetworkUsage" -> {
                    scope.launch(Dispatchers.IO) {
                        if (checkUsageStatsPermission()) {
                            val packageName = call.argument<String>("packageName")
                            if (packageName != null) {
                                val usage = getAppNetworkUsage(packageName)
                                withContext(Dispatchers.Main) {
                                    result.success(usage)
                                }
                            } else {
                                withContext(Dispatchers.Main) {
                                    result.error("INVALID_ARGUMENT", "Package name is required", null)
                                }
                            }
                        } else {
                            withContext(Dispatchers.Main) {
                                result.error("PERMISSION_DENIED", "Usage access not granted", null)
                            }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private suspend fun checkUsageStatsPermission(): Boolean = withContext(Dispatchers.IO) {
        try {
            val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            val mode = appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
            val hasPermission = mode == AppOpsManager.MODE_ALLOWED
            Log.d(TAG, "İzin durumu kontrol edildi: $hasPermission")
            hasPermission
        } catch (e: Exception) {
            Log.e(TAG, "İzin kontrolünde hata: ${e.message}")
            false
        }
    }

    private suspend fun requestUsageStatsPermission() = withContext(Dispatchers.Main) {
        try {
            Log.d(TAG, "İzin isteme başlatılıyor...")
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            intent.addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY)
            intent.addFlags(Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS)
            startActivity(intent)
            Log.d(TAG, "İzin isteme ekranı açıldı")
        } catch (e: Exception) {
            Log.e(TAG, "İzin isteme hatası: ${e.message}")
            throw e
        }
    }

    private suspend fun getTotalNetworkUsage(): Map<String, Long> = withContext(Dispatchers.IO) {
        try {
            val totalRx = TrafficStats.getTotalRxBytes()
            val totalTx = TrafficStats.getTotalTxBytes()
            val mobileRx = TrafficStats.getMobileRxBytes()
            val mobileTx = TrafficStats.getMobileTxBytes()
            
            if (totalRx == TrafficStats.UNSUPPORTED.toLong() || 
                totalTx == TrafficStats.UNSUPPORTED.toLong() ||
                mobileRx == TrafficStats.UNSUPPORTED.toLong() || 
                mobileTx == TrafficStats.UNSUPPORTED.toLong()) {
                Log.e(TAG, "TrafficStats desteklenmiyor")
                return@withContext mapOf(
                    "mobileData" to 0L,
                    "wifiData" to 0L,
                    "totalData" to 0L
                )
            }
            
            val totalMobile = mobileRx + mobileTx
            val totalWifi = (totalRx + totalTx) - totalMobile
            
            val finalMobile = if (totalMobile < 0) 0L else totalMobile
            val finalWifi = if (totalWifi < 0) 0L else totalWifi
            val finalTotal = if ((totalRx + totalTx) < 0) 0L else (totalRx + totalTx)
            
            Log.d(TAG, "Ağ kullanımı alındı: Mobile=$finalMobile, WiFi=$finalWifi, Total=$finalTotal")
            
            mapOf(
                "mobileData" to finalMobile,
                "wifiData" to finalWifi,
                "totalData" to finalTotal
            )
        } catch (e: Exception) {
            Log.e(TAG, "Network stats alınamadı: ${e.message}")
            mapOf(
                "mobileData" to 0L,
                "wifiData" to 0L,
                "totalData" to 0L
            )
        }
    }

    private suspend fun getAppNetworkUsage(packageName: String): Map<String, Long> = withContext(Dispatchers.IO) {
        try {
            val uid = packageManager.getPackageUid(packageName, 0)
            val rxBytes = TrafficStats.getUidRxBytes(uid)
            val txBytes = TrafficStats.getUidTxBytes(uid)
            
            mapOf(
                "totalData" to (rxBytes + txBytes)
            )
        } catch (e: Exception) {
            Log.e(TAG, "Uygulama network kullanımı alınamadı: ${e.message}")
            mapOf("totalData" to 0L)
        }
    }

    override fun onDestroy() {
        if (!isDisposed.get()) {
            isDisposed.set(true)
            scope.cancel()
        }
        super.onDestroy()
    }
}
