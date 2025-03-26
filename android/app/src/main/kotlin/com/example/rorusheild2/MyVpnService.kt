package com.example.rorusheild2

import android.content.Intent
import android.net.VpnService
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.util.Log
import kotlinx.coroutines.*
import java.io.FileInputStream
import java.nio.ByteBuffer

class MyVpnService : VpnService() {
    private var vpnInterface: ParcelFileDescriptor? = null
    private var readJob: Job? = null

    override fun onCreate() {
        super.onCreate()
        Log.d("MyVpnService", "VPN Service Created")
    }

    override fun onDestroy() {
        super.onDestroy()
        readJob?.cancel()
        vpnInterface?.close()
        Log.d("MyVpnService", "VPN Service Destroyed")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("MyVpnService", "VPN Service Started")

        try {
            // VPN bağlantısını başlat
            val builder = Builder()
            builder.setSession("RoRüShield VPN")
                .addAddress("192.168.2.1", 24)  // IP adresi belirleme
                .addDnsServer("8.8.8.8")
                .addDnsServer("8.8.4.4")
                .addRoute("8.8.8.8", 32)  // Tüm trafiği VPN üzerinden yönlendirme

            vpnInterface = builder.establish()  // VPN arayüzünü başlat

            if (vpnInterface == null) {
                Log.e("MyVpnService", "VPN interface could not be established")
                return START_NOT_STICKY
            }

            // Log mesajı ekleyin
            Log.d("MyVpnService", "Route added: 0.0.0.0 with netmask 0")

            // Veriyi arka planda okuma işlemi
            readJob = CoroutineScope(Dispatchers.IO).launch {
                try {
                    val inputStream = FileInputStream(vpnInterface!!.fileDescriptor)  // VPN bağlantısının dosya tanımlayıcısı ile input stream oluştur
                    val packet = ByteArray(32767)
                    while (isActive) {
                        val length = inputStream.read(packet)
                        if (length > 0) {
                            val buffer = ByteBuffer.wrap(packet, 0, length)
                            val domain = extractDomainFromPacket(buffer)  // Paketlerden domain bilgisi çıkarma
                            if (domain != null) {
                                Log.d("RoRüShield", "Ziyaret edilen domain: $domain")

                                // UI iş parçacığına domain bilgisini gönder
                                Handler(Looper.getMainLooper()).post {
                                    MainActivity.channel.invokeMethod("addDomain", domain)
                                }
                            }
                        }
                    }
                } catch (e: Exception) {
                    Log.e("MyVpnService", "Error while reading packets", e)
                }
            }
        } catch (e: Exception) {
            Log.e("MyVpnService", "VPN service start failed", e)
        }

        return START_STICKY  // Servisin sürekli olarak çalışmasını sağla
    }

    // Paketlerden domain bilgisini çıkaran fonksiyon
    private fun extractDomainFromPacket(buffer: ByteBuffer): String? {
        buffer.position(0)

        // DNS paketlerinde genellikle 12 byte başlık vardır, bu yüzden en az 12 byte veriye sahip olmalıyız
        if (buffer.remaining() < 12) return null // Eğer veri yetersizse, dönüş yapıyoruz.

        // DNS başlıklarını atlıyoruz (12 byte)
        buffer.position(12)

        val domainBuilder = StringBuilder()

        // Domain kısmı var mı diye kontrol ediyoruz
        while (buffer.hasRemaining()) {
            val length = buffer.get().toInt()  // Domain etiketinin uzunluğu

            // Eğer length sıfırsa, domain sonlanmıştır.
            if (length == 0) break

            // Eğer length negatifse geçerli bir domain olmayabilir
            if (length < 0) return null

            // Etiketi okuma
            val label = ByteArray(length)
            buffer.get(label)

            // Etiketi birleştiriyoruz
            domainBuilder.append(String(label)).append(".")
        }

        // Eğer domain tamamlanmışsa, sonundaki noktayı kaldırıyoruz.
        return if (domainBuilder.isNotEmpty()) domainBuilder.toString().removeSuffix(".") else null
    }
}
