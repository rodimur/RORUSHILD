package com.example.rorusheild2

import android.content.Intent
import android.net.VpnService
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.util.Log
import kotlinx.coroutines.*
import java.io.FileInputStream
import java.io.FileOutputStream
import java.net.InetSocketAddress
import java.nio.ByteBuffer
import java.nio.channels.DatagramChannel
import java.nio.channels.SocketChannel
import android.system.OsConstants
import java.net.InetAddress
import io.flutter.plugin.common.EventChannel
import java.io.IOException
import java.util.ArrayDeque
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicLong
import java.util.LinkedHashMap
import kotlinx.coroutines.channels.Channel

class MyVpnService : VpnService() {
    private var vpnInterface: ParcelFileDescriptor? = null
    private var vpnInput: FileInputStream? = null
    private var vpnOutput: FileOutputStream? = null
    private val packetProcessingScope = CoroutineScope(SupervisorJob() + Dispatchers.IO + CoroutineName("PacketProcessing"))
    private val dnsProcessingScope = CoroutineScope(SupervisorJob() + Dispatchers.IO + CoroutineName("DnsProcessing"))
    private val httpProcessingScope = CoroutineScope(SupervisorJob() + Dispatchers.IO + CoroutineName("HttpProcessing"))
    private var processedPackets = 0L
    private var lastErrorTime = 0L
    private var consecutiveErrors = 0
    var isRunning = false
    private var udpChannel: DatagramChannel? = null
    private val scope = CoroutineScope(Dispatchers.Default + SupervisorJob())
    private val mainHandler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null
    private val TAG = "MyVpnService"
    private val packetChannel = Channel<ByteArray>(Channel.BUFFERED)
    private val dnsChannel = Channel<ByteArray>(Channel.BUFFERED)
    private val httpChannel = Channel<ByteArray>(Channel.BUFFERED)

    companion object {
        private const val VPN_ADDRESS = "10.0.0.2"
        private const val VPN_ROUTE = "0.0.0.0"
        private const val DNS_SERVERS = "8.8.8.8,8.8.4.4"
        private const val BUFFER_SIZE = 32768
        private const val MAX_PACKET_SIZE = 32767
        private const val DNS_PORT = 53
        private const val HTTP_PORT = 80
        private const val HTTPS_PORT = 443
        private const val TIMEOUT = 1000L
        private const val MAX_CONSECUTIVE_ERRORS = 5
        private const val ERROR_DELAY = 100L
        private const val RESTART_DELAY = 1000L
        
        @JvmStatic
        var instance: MyVpnService? = null
            private set
    }

    override fun onCreate() {
        super.onCreate()
        isRunning = true
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return if (intent?.getStringExtra("COMMAND") == "STOP") {
            stopVpn()
            stopSelf()
            START_NOT_STICKY
        } else {
            setupVpnAndStart()
            START_STICKY
        }
    }

    private fun setupVpnAndStart() {
        try {
            vpnInterface = setupVpnInterface()
            vpnInput = FileInputStream(vpnInterface?.fileDescriptor)
            vpnOutput = FileOutputStream(vpnInterface?.fileDescriptor)
            startPacketProcessing()
        } catch (e: Exception) {
            Log.e(TAG, "VPN başlatma hatası: ${e.message}")
        }
    }

    private fun setupVpnInterface(): ParcelFileDescriptor {
        return Builder()
            .setSession("RoruShield VPN")
            .addAddress(VPN_ADDRESS, 32)
            .addDnsServer("8.8.8.8")
            .addDnsServer("1.1.1.1")
            .addRoute(VPN_ROUTE, 0)
            .setMtu(1500)
            .allowFamily(OsConstants.AF_INET)
            .allowFamily(OsConstants.AF_INET6)
            .allowBypass()
            .setBlocking(true)
            .establish() ?: throw IllegalStateException("VPN arayüzü oluşturulamadı")
    }

    private fun setupUdpChannel() {
        try {
            if (udpChannel == null || !udpChannel!!.isOpen) {
                udpChannel = DatagramChannel.open()
                udpChannel?.configureBlocking(true)
                protect(udpChannel?.socket()!!)
                udpChannel?.connect(InetSocketAddress("8.8.8.8", 53))
                Log.d(TAG, "UDP kanalı başarıyla kuruldu")
            }
        } catch (e: Exception) {
            Log.e(TAG, "UDP kanalı kurulumunda hata: ${e.message}")
            udpChannel = null
        }
    }

    private fun startPacketProcessing() {
        packetProcessingScope.launch {
            val buffer = ByteArray(32768)
            while (isActive) {
                try {
                    val length = vpnInput?.read(buffer) ?: -1
                    if (length > 0) {
                        val packet = buffer.copyOfRange(0, length)
                        packetChannel.send(packet)
                        processedPackets++
                        
                        if (processedPackets % 1000 == 0L) {
                            Log.d(TAG, "İşlenen paket sayısı: $processedPackets")
                        }
                    }
                } catch (e: Exception) {
                    val currentTime = System.currentTimeMillis()
                    if (currentTime - lastErrorTime > 1000) {
                        consecutiveErrors = 0
                    }
                    consecutiveErrors++
                    lastErrorTime = currentTime
                    
                    if (consecutiveErrors >= 5) {
                        Log.e(TAG, "Kritik hata: VPN yeniden başlatılıyor")
                        restartVpn()
                        consecutiveErrors = 0
                    } else {
                        Log.e(TAG, "Paket işleme hatası: ${e.message}")
                        delay(100L * consecutiveErrors)
                    }
                }
            }
        }

        packetProcessingScope.launch {
            for (packet in packetChannel) {
                try {
                    val version = packet[0].toInt() shr 4
                    when (version) {
                        4 -> handleIpv4Packet(packet)
                        6 -> handleIpv6Packet(packet)
                        else -> Log.w(TAG, "Desteklenmeyen IP versiyonu: $version")
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Paket işleme hatası: ${e.message}")
                }
            }
        }

        dnsProcessingScope.launch {
            for (packet in dnsChannel) {
                try {
                    handleDnsQuery(packet)
                } catch (e: Exception) {
                    Log.e(TAG, "DNS işleme hatası: ${e.message}")
                }
            }
        }

        httpProcessingScope.launch {
            for (packet in httpChannel) {
                try {
                    handleHttpTraffic(packet)
                } catch (e: Exception) {
                    Log.e(TAG, "HTTP işleme hatası: ${e.message}")
                }
            }
        }
    }

    private suspend fun handleIpv4Packet(packet: ByteArray) {
        withContext(Dispatchers.IO) {
            try {
                val protocol = packet[9].toInt() and 0xFF
                val sourcePort = ((packet[20].toInt() and 0xFF) shl 8) or (packet[21].toInt() and 0xFF)
                val destPort = ((packet[22].toInt() and 0xFF) shl 8) or (packet[23].toInt() and 0xFF)
                
                when (protocol) {
                    OsConstants.IPPROTO_UDP -> {
                        if (destPort == DNS_PORT) {
                            dnsChannel.send(packet)
                        } else {
                            forwardPacket(packet)
                        }
                    }
                    OsConstants.IPPROTO_TCP -> {
                        if (sourcePort == HTTP_PORT || sourcePort == HTTPS_PORT || 
                            destPort == HTTP_PORT || destPort == HTTPS_PORT) {
                            httpChannel.send(packet)
                        } else {
                            forwardPacket(packet)
                        }
                    }
                    else -> {
                        forwardPacket(packet)
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "IPv4 paket işleme hatası: ${e.message}")
                forwardPacket(packet)
            }
        }
    }

    private suspend fun handleIpv6Packet(packet: ByteArray) {
        withContext(Dispatchers.IO) {
            try {
                forwardPacket(packet)
            } catch (e: Exception) {
                Log.e(TAG, "IPv6 paket işleme hatası: ${e.message}")
            }
        }
    }

    private suspend fun handleDnsQuery(packet: ByteArray) {
        withContext(Dispatchers.IO) {
            try {
                setupUdpChannel()
                if (udpChannel?.isOpen == true) {
                    udpChannel?.write(ByteBuffer.wrap(packet))
                    
                    val responseBuffer = ByteBuffer.allocate(32768)
                    val responseLength = udpChannel?.read(responseBuffer)
                    
                    if (responseLength != null && responseLength > 0) {
                        val response = responseBuffer.array().copyOfRange(0, responseLength)
                        forwardPacket(response)
                    } else {
                        forwardPacket(packet)
                    }
                } else {
                    forwardPacket(packet)
                }
            } catch (e: Exception) {
                Log.e(TAG, "DNS sorgu hatası: ${e.message}")
                forwardPacket(packet)
            }
        }
    }

    private suspend fun handleHttpTraffic(packet: ByteArray) {
        withContext(Dispatchers.IO) {
            try {
                val domain = extractDomain(packet)
                if (domain != null) {
                    Log.d(TAG, "HTTP/HTTPS trafiği: $domain")
                    mainHandler.post {
                        eventSink?.success(mapOf(
                            "type" to "domain",
                            "domain" to domain
                        ))
                    }
                }
                forwardPacket(packet)
            } catch (e: Exception) {
                Log.e(TAG, "HTTP trafik hatası: ${e.message}")
                forwardPacket(packet)
            }
        }
    }

    private fun extractDomain(buffer: ByteArray): String? {
        try {
            var position = 12 // DNS başlığını atla
            val domain = StringBuilder()
            
            while (position < buffer.size) {
                val length = buffer[position].toInt() and 0xFF
                if (length == 0) break
                
                position++
                if (position + length > buffer.size) return null
                
                val labelBytes = buffer.copyOfRange(position, position + length)
                position += length
                
                // Geçerli ASCII karakterleri kontrol et
                val label = labelBytes.map { byte -> 
                    if (byte.toInt() in 32..126) byte.toChar() else return null
                }.joinToString("")
                
                if (domain.isNotEmpty()) domain.append(".")
                domain.append(label)
            }
            
            return if (domain.isNotEmpty()) domain.toString() else null
            
        } catch (e: Exception) {
            Log.e(TAG, "Domain çıkarma hatası: ${e.message}")
            return null
        }
    }

    private fun forwardPacket(packet: ByteArray) {
        try {
            vpnOutput?.write(packet)
        } catch (e: Exception) {
            Log.e(TAG, "Paket iletme hatası: ${e.message}")
        }
    }

    private fun stopVpn() {
        isRunning = false
        try {
            vpnInterface?.close()
            vpnInput?.close()
            vpnOutput?.close()
            udpChannel?.close()
        } catch (e: Exception) {
            Log.e(TAG, "VPN durdurma hatası: ${e.message}")
        }
        scope.cancel()
    }

    private suspend fun restartVpn() {
        withContext(Dispatchers.IO) {
            stopVpn()
            delay(1000)
            setupVpnAndStart()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        packetProcessingScope.cancel()
        dnsProcessingScope.cancel()
        httpProcessingScope.cancel()
        packetChannel.close()
        dnsChannel.close()
        httpChannel.close()
        vpnInput?.close()
        vpnOutput?.close()
        vpnInterface?.close()
    }
}
