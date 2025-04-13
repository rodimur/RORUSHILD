package com.example.rorusheild2

import android.content.Intent
import android.net.VpnService
import android.os.ParcelFileDescriptor
import android.util.Log
import android.os.Handler
import android.os.Looper
import android.system.OsConstants
import io.flutter.plugin.common.EventChannel
import java.io.FileInputStream
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class MyVpnService : VpnService() {
    private var vpnInterface: ParcelFileDescriptor? = null
    private val TAG = "MyVpnService"
    var isRunning = false
    private val mainHandler = Handler(Looper.getMainLooper())
    private var vpnInput: FileInputStream? = null
    private var vpnOutput: FileOutputStream? = null
    private var executor: ExecutorService? = null
    
    companion object {
        private const val VPN_ADDRESS = "10.0.0.2"
        
        @JvmStatic
        var instance: MyVpnService? = null
            private set
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
        isRunning = true
        Log.d(TAG, "VPN servisi oluşturuldu")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return if (intent?.getStringExtra("COMMAND") == "STOP") {
            stopVpn()
            stopSelf()
            Log.d(TAG, "VPN servisi durduruldu")
            START_NOT_STICKY
        } else {
            setupVpnAndStart()
            Log.d(TAG, "VPN servisi başlatıldı")
            START_STICKY
        }
    }

    private fun setupVpnAndStart() {
        try {
            vpnInterface = setupVpnInterface()
            vpnInput = FileInputStream(vpnInterface?.fileDescriptor)
            vpnOutput = FileOutputStream(vpnInterface?.fileDescriptor)
            
            // VPN trafiğini işleme
            executor = Executors.newSingleThreadExecutor()
            executor?.submit {
                try {
                    forwardTraffic()
                } catch (e: Exception) {
                    Log.e(TAG, "Trafik iletme hatası: ${e.message}")
                }
            }
            
            // VPN durumunu Flutter tarafına bildir
            MainActivity.channel.invokeMethod("vpnStatus", "active")
            isRunning = true
        } catch (e: Exception) {
            Log.e(TAG, "VPN başlatma hatası: ${e.message}")
            isRunning = false
        }
    }

    private fun setupVpnInterface(): ParcelFileDescriptor {
        return Builder()
            .setSession("RoruShield VPN")
            .addAddress(VPN_ADDRESS, 24)  // 24 bit ağ maskesi
            .addDnsServer("8.8.8.8")
            .addDnsServer("1.1.1.1")
            .addRoute("8.8.8.8", 32)  // Sadece Google DNS trafiği VPN'den geçsin
            .setMtu(1500)
            .allowFamily(OsConstants.AF_INET)
            .allowBypass()  // Bazı uygulamaların VPN'i atlamasına izin ver
            .establish() ?: throw IllegalStateException("VPN arayüzü oluşturulamadı")
    }
    
    private fun forwardTraffic() {
        val buffer = ByteBuffer.allocate(32767)
        
        try {
            // Basit bir tünel oluşturma - paketleri sadece gönder ve al
            while (isRunning) {
                try {
                    // VPN'den gelen trafiği oku
                    val readLen = vpnInput?.read(buffer.array()) ?: -1
                    if (readLen <= 0) {
                        Thread.sleep(100)
                        continue
                    }
                    
                    // Paketleri işle ve geri gönder - gerekli çalışan kısım
                    vpnOutput?.write(buffer.array(), 0, readLen)
                    
                    // VPN durumunu Flutter'a bildir (daha az sıklıkta)
                    if (Math.random() < 0.05) {
                        mainHandler.post {
                            try {
                                MainActivity.channel.invokeMethod("vpnStatus", "active")
                            } catch (e: Exception) {
                                Log.e(TAG, "Durum bildirim hatası: ${e.message}")
                            }
                        }
                    }
                } catch (e: Exception) {
                    if (isRunning) {
                        Log.e(TAG, "Paket işleme hatası: ${e.message}")
                        Thread.sleep(100)
                    } else {
                        break
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Trafik iletme hatası: ${e.message}")
        }
    }

    private fun stopVpn() {
        isRunning = false
        try {
            executor?.shutdownNow()
            executor = null
            vpnInput?.close()
            vpnOutput?.close()
            vpnInterface?.close()
            vpnInterface = null
            
            // VPN durumunu Flutter tarafına bildir
            mainHandler.post {
                try {
                    MainActivity.channel.invokeMethod("vpnStatus", "inactive")
                } catch (e: Exception) {
                    Log.e(TAG, "Durum bildirim hatası: ${e.message}")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "VPN durdurma hatası: ${e.message}")
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        try {
            executor?.shutdownNow()
            executor = null
            vpnInput?.close()
            vpnOutput?.close()
            vpnInterface?.close()
            vpnInterface = null
        } catch (e: Exception) {
            Log.e(TAG, "VPN arayüzü kapatma hatası: ${e.message}")
        }
        instance = null
        Log.d(TAG, "VPN servisi yok edildi")
    }
}
