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
            
            val wifiStats = networkStatsManager.querySummary(
                ConnectivityManager.TYPE_WIFI,
                subscriberId,
                0,
                System.currentTimeMillis()
            )
            
            val mobileStats = networkStatsManager.querySummary(
                ConnectivityManager.TYPE_MOBILE,
                subscriberId,
                0,
                System.currentTimeMillis()
            )

            val appStats = mutableMapOf<String, Double>()
            
            while (wifiStats.hasNextBucket()) {
                wifiStats.getNextBucket(bucket)
                val uid = bucket.uid
                try {
                    val packages = packageManager.getPackagesForUid(uid)
                    if (packages != null && packages.isNotEmpty()) {
                        val usage = (bucket.rxBytes + bucket.txBytes) / (1024.0 * 1024.0 * 1024.0)
                        appStats[packages[0]] = (appStats[packages[0]] ?: 0.0) + usage
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
                    }
                } catch (e: Exception) {
                    continue
                }
            }

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
                } catch (e: Exception) {
                    e.printStackTrace()
                    continue
                }
            }

            return appUsageList.sortedByDescending { it["usage"] as Double }
        } catch (e: RemoteException) {
            e.printStackTrace()
            return emptyList()
        }
    }
} 