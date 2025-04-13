package com.example.rorusheild2

import android.app.AppOpsManager
import android.app.usage.NetworkStats
import android.app.usage.NetworkStatsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.*

class NetworkUsagePlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var networkStatsManager: NetworkStatsManager
    private lateinit var usageStatsManager: UsageStatsManager

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.example.rorusheild2/network_usage")
        context = flutterPluginBinding.applicationContext
        networkStatsManager = context.getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager
        usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "checkUsagePermission" -> {
                val hasPermission = checkUsagePermission()
                result.success(hasPermission)
            }
            "requestUsagePermission" -> {
                requestUsagePermission()
                result.success(null)
            }
            "getTotalNetworkUsage" -> {
                val networkStats = getTotalNetworkUsage()
                result.success(networkStats)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun checkUsagePermission(): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            context.packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun requestUsagePermission() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        context.startActivity(intent)
    }

    private fun getTotalNetworkUsage(): Map<String, Long> {
        val endTime = System.currentTimeMillis()
        val startTime = endTime - (24 * 60 * 60 * 1000) // Son 24 saat

        val mobileStats = networkStatsManager.querySummary(
            ConnectivityManager.TYPE_MOBILE,
            null,
            startTime,
            endTime
        )
        val wifiStats = networkStatsManager.querySummary(
            ConnectivityManager.TYPE_WIFI,
            null,
            startTime,
            endTime
        )

        var mobileBytes = 0L
        var wifiBytes = 0L

        mobileStats?.let { stats ->
            val bucket = NetworkStats.Bucket()
            while (stats.hasNextBucket()) {
                stats.getNextBucket(bucket)
                mobileBytes += bucket.rxBytes + bucket.txBytes
            }
        }

        wifiStats?.let { stats ->
            val bucket = NetworkStats.Bucket()
            while (stats.hasNextBucket()) {
                stats.getNextBucket(bucket)
                wifiBytes += bucket.rxBytes + bucket.txBytes
            }
        }

        val totalBytes = mobileBytes + wifiBytes

        return mapOf(
            "mobileData" to mobileBytes,
            "wifiData" to wifiBytes,
            "totalData" to totalBytes
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
} 