package com.example.rorusheild2

import android.app.usage.NetworkStats
import android.app.usage.NetworkStatsManager
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.net.ConnectivityManager
import android.os.RemoteException
import android.util.Base64
import java.io.ByteArrayOutputStream
import java.util.*

class AppUsageHelper(private val context: Context) {
    private fun drawableToBitmap(drawable: Drawable): Bitmap {
        try {
            val width = drawable.intrinsicWidth.coerceAtLeast(48)
            val height = drawable.intrinsicHeight.coerceAtLeast(48)
            
            val bitmap = Bitmap.createBitmap(
                width,
                height,
                Bitmap.Config.ARGB_8888
            )
            val canvas = Canvas(bitmap)
            drawable.setBounds(0, 0, width, height)
            drawable.draw(canvas)
            return bitmap
        } catch (e: Exception) {
            e.printStackTrace()
            // Fallback için küçük bir bitmap oluştur
            return Bitmap.createBitmap(48, 48, Bitmap.Config.ARGB_8888)
        }
    }

    private fun bitmapToBase64(bitmap: Bitmap): String {
        return try {
            val byteArrayOutputStream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, byteArrayOutputStream)
            val byteArray = byteArrayOutputStream.toByteArray()
            Base64.encodeToString(byteArray, Base64.NO_WRAP)
        } catch (e: Exception) {
            e.printStackTrace()
            ""
        } finally {
            bitmap.recycle()
        }
    }

    fun getAppUsage(): List<Map<String, Any>> {
        val networkStatsManager = context.getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager
        val packageManager = context.packageManager
        val appUsageList = mutableListOf<Map<String, Any>>()

        try {
            val subscriberId = ""
            val bucket = NetworkStats.Bucket()
            
            // Başlangıç zamanını 1 ay öncesine ayarla (daha uzun süreli veri için)
            val calendar = Calendar.getInstance()
            calendar.add(Calendar.MONTH, -1)
            val startTime = calendar.timeInMillis
            val endTime = System.currentTimeMillis()
            
            val wifiStats = networkStatsManager.querySummary(
                ConnectivityManager.TYPE_WIFI,
                subscriberId,
                startTime,
                endTime
            )
            
            val mobileStats = networkStatsManager.querySummary(
                ConnectivityManager.TYPE_MOBILE,
                subscriberId,
                startTime,
                endTime
            )

            val appStats = mutableMapOf<String, Double>()
            var totalWifiUsage = 0.0
            var totalMobileUsage = 0.0
            
            while (wifiStats.hasNextBucket()) {
                wifiStats.getNextBucket(bucket)
                val uid = bucket.uid
                try {
                    val packages = packageManager.getPackagesForUid(uid)
                    if (packages != null && packages.isNotEmpty()) {
                        val usage = (bucket.rxBytes + bucket.txBytes) / (1024.0 * 1024.0 * 1024.0)
                        appStats[packages[0]] = (appStats[packages[0]] ?: 0.0) + usage
                        totalWifiUsage += usage
                    }
                } catch (e: Exception) {
                    continue
                }
            }
            
            while (mobileStats.hasNextBucket()) {
                mobileStats.getNextBucket(bucket)
                val uid = bucket.uid
                try {
                    val packages = packageManager.getPackagesForUid(uid)
                    if (packages != null && packages.isNotEmpty()) {
                        val usage = (bucket.rxBytes + bucket.txBytes) / (1024.0 * 1024.0 * 1024.0)
                        appStats[packages[0]] = (appStats[packages[0]] ?: 0.0) + usage
                        totalMobileUsage += usage
                    }
                } catch (e: Exception) {
                    continue
                }
            }

            // Toplam kullanım değerlerini hesapla
            var totalDownload = 0.0
            var totalUpload = 0.0
            var totalUsage = 0.0

            for ((packageName, usage) in appStats) {
                try {
                    val appInfo = packageManager.getApplicationInfo(packageName, 0)
                    val appName = packageManager.getApplicationLabel(appInfo).toString()
                    val appIcon = packageManager.getApplicationIcon(packageName)
                    val iconBitmap = drawableToBitmap(appIcon)
                    val iconBase64 = bitmapToBase64(iconBitmap)

                    appUsageList.add(mapOf(
                        "appName" to appName,
                        "packageName" to packageName,
                        "usage" to usage,
                        "icon" to iconBase64
                    ))
                    
                    totalUsage += usage
                } catch (e: Exception) {
                    e.printStackTrace()
                    continue
                }
            }

            // Toplam değerleri global olarak sakla
            totalNetworkStats = mapOf(
                "totalUsage" to totalUsage,
                "totalWifiUsage" to totalWifiUsage,
                "totalMobileUsage" to totalMobileUsage,
                "totalDownload" to totalUsage * 0.7, // Yaklaşık olarak %70 download
                "totalUpload" to totalUsage * 0.3    // Yaklaşık olarak %30 upload
            )

            return appUsageList.sortedByDescending { it["usage"] as Double }
        } catch (e: RemoteException) {
            e.printStackTrace()
            return emptyList()
        }
    }
    
    // Toplam ağ istatistiklerini saklamak için companion object
    companion object {
        var totalNetworkStats: Map<String, Double> = mapOf(
            "totalUsage" to 0.0,
            "totalWifiUsage" to 0.0,
            "totalMobileUsage" to 0.0,
            "totalDownload" to 0.0,
            "totalUpload" to 0.0
        )
    }
} 