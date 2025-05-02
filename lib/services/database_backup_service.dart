import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:rorusheild2/services/database_service.dart';

class DatabaseBackupService {
  static const String dbFileName = 'domains.db';

  // Veritabanını Downloads klasörüne yedekler
  static Future<String> backupDatabase() async {
    final dbPath = await getDatabasesPath();
    final dbFile = File(join(dbPath, dbFileName));
    final Directory downloadsDir = Directory('/storage/emulated/0/Download');
    if (!await downloadsDir.exists()) {
      throw Exception('Downloads klasörü bulunamadı');
    }
    final backupFile = File(join(downloadsDir.path, 'domains_backup_${DateTime.now().millisecondsSinceEpoch}.db'));
    await dbFile.copy(backupFile.path);
    return backupFile.path;
  }

  // Kullanıcıdan .db dosyası seçmesini ister ve mevcut veritabanının üzerine yazar
  static Future<String?> restoreDatabase() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      if (!result.files.single.path!.endsWith('.db')) {
        // Seçilen dosya .db uzantılı değilse işlemi iptal et
        return null;
      }
      final selectedFile = File(result.files.single.path!);
      final dbPath = await getDatabasesPath();
      final dbFile = File(join(dbPath, dbFileName));
      // Veritabanı bağlantısını kapat
      await DatabaseService.instance.close();
      if (await dbFile.exists()) {
        await dbFile.delete(); // Eski veritabanını sil
      }
      await selectedFile.copy(dbFile.path); // Yeni dosyayı kopyala
      return dbFile.path;
    }
    return null;
  }
}
