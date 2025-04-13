import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/visited_domain.dart';
import 'database_service.dart';

class PdfReportService {
  static final PdfReportService _instance = PdfReportService._internal();
  static PdfReportService get instance => _instance;

  PdfReportService._internal();

  pw.Widget _buildStatCard(String title, String value, PdfColor color, String icon) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F5F5F5'),
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: color),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#E3F2FD'),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              icon,
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            title,
            style: pw.TextStyle(color: color),
          ),
        ],
      ),
    );
  }

  Future<String> generateThreatReport() async {
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: await PdfGoogleFonts.nunitoRegular(),
        bold: await PdfGoogleFonts.nunitoBold(),
      ),
    );
    final DatabaseService dbService = DatabaseService.instance;

    // Verileri al
    final List<VisitedDomain> safeDomains = await dbService.getSafeDomains();
    final List<VisitedDomain> unsafeDomains = await dbService.getUnsafeDomains();
    
    // İstatistikleri hesapla
    final int totalDomains = safeDomains.length + unsafeDomains.length;
    final double threatPercentage = totalDomains > 0 
        ? (unsafeDomains.length / totalDomains) * 100 
        : 0.0;

    // PDF sayfasını oluştur
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          _buildHeader(),
          _buildSummarySection(totalDomains, unsafeDomains.length, threatPercentage),
          _buildDomainList('Tehlikeli Domain\'ler', unsafeDomains),
          _buildDomainList('Güvenli Domain\'ler', safeDomains),
        ],
      ),
    );

    // PDF'i Download klasörüne kaydet
    final String fileName = 'RoRuShield_Rapor_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final Directory? directory = Directory('/storage/emulated/0/Download');
    if (!await directory!.exists()) {
      throw Exception('Download klasörü bulunamadı');
    }
    final String path = '${directory.path}/$fileName';
    final File file = File(path);
    await file.writeAsBytes(await pdf.save());
    
    return path;
  }

  pw.Widget _buildHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [PdfColors.blue800, PdfColors.blue400],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(15)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'RoRuShield',
                    style: pw.TextStyle(
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                  pw.Text(
                    'Tehdit Analiz Raporu',
                    style: pw.TextStyle(
                      fontSize: 20,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#E6FFFFFF'),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Text(
                  DateTime.now().toString().split('.')[0],
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.blue800,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummarySection(int total, int unsafe, double percentage) {
    final safeCount = total - unsafe;
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Özet İstatistikler',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
          ),
          pw.SizedBox(height: 15),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard(
                'Toplam Domain',
                total.toString(),
                PdfColors.blue600,
                'O',
              ),
              _buildStatCard(
                'Güvenli',
                safeCount.toString(),
                PdfColors.green600,
                '+',
              ),
              _buildStatCard(
                'Tehlikeli',
                unsafe.toString(),
                PdfColors.red600,
                '!',
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: percentage > 50 ? PdfColors.red50 : PdfColors.green50,
              borderRadius: pw.BorderRadius.circular(10),
              border: pw.Border.all(
                color: percentage > 50 ? PdfColors.red200 : PdfColors.green200,
                width: 1,
              ),
            ),
            child: pw.Row(
              children: [
                pw.Container(
                  width: 50,
                  height: 50,
                  decoration: pw.BoxDecoration(
                    color: percentage > 50 ? PdfColors.red200 : PdfColors.green200,
                    shape: pw.BoxShape.circle,
                  ),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: pw.TextStyle(
                      color: percentage > 50 ? PdfColors.red900 : PdfColors.green900,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(width: 15),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Tehdit Seviyesi',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: percentage > 50 ? PdfColors.red900 : PdfColors.green900,
                      ),
                    ),
                    pw.Text(
                      percentage > 50 ? 'Yüksek Risk' : 'Düşük Risk',
                      style: pw.TextStyle(
                        color: percentage > 50 ? PdfColors.red700 : PdfColors.green700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDomainList(String title, List<VisitedDomain> domains) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(10),
                topRight: pw.Radius.circular(10),
              ),
            ),
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
          ),
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue100),
              borderRadius: const pw.BorderRadius.only(
                bottomLeft: pw.Radius.circular(10),
                bottomRight: pw.Radius.circular(10),
              ),
            ),
            child: pw.Column(
              children: [
                ...domains.map((domain) => pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blue50)),
                  ),
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          domain.domain,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          domain.timestamp.toString().split(' ')[0],
                          style: const pw.TextStyle(color: PdfColors.grey700),
                        ),
                      ),
                    ],
                  ),
                )),
                if (domains.isEmpty)
                  pw.Container(
                    padding: const pw.EdgeInsets.all(15),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      'Kayıt bulunamadı',
                      style: const pw.TextStyle(color: PdfColors.grey),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
