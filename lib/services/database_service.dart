import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import '../models/visited_domain.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('domains.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE visited_domains (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT NOT NULL,
        domain TEXT NOT NULL,
        path TEXT,
        timestamp INTEGER NOT NULL,
        isSafe INTEGER NOT NULL
      )
    ''');
  }

  // Ziyaret edilen bir domain ekler
  Future<int> addVisitedDomain(VisitedDomain domain) async {
    final db = await database;
    
    // Doğrudan yeni kayıt ekle (aynı domain olsa bile)
    return await db.insert('visited_domains', domain.toJson());
  }

  // Tüm ziyaret edilen domainleri getirir
  Future<List<VisitedDomain>> getAllVisitedDomains() async {
    final db = await database;
    final result = await db.query(
      'visited_domains',
      orderBy: 'timestamp DESC',
    );

    return result.map((json) => VisitedDomain.fromJson(json)).toList();
  }

  // Güvenli olmayan domainleri getirir
  Future<List<VisitedDomain>> getUnsafeDomains() async {
    final db = await database;
    final result = await db.query(
      'visited_domains',
      where: 'isSafe = ?',
      whereArgs: [0],
      orderBy: 'timestamp DESC',
    );

    return result.map((json) => VisitedDomain.fromJson(json)).toList();
  }

  // Tehlikeli domainleri getirir (getUnsafeDomains ile aynı işlevi görür)
  Future<List<VisitedDomain>> getDangerousDomains() async {
    final db = await database;
    final result = await db.query(
      'visited_domains',
      where: 'isSafe = ?',
      whereArgs: [0],
      orderBy: 'timestamp DESC',
    );

    return result.map((json) => VisitedDomain.fromJson(json)).toList();
  }

  // Güvenli domainleri getirir
  Future<List<VisitedDomain>> getSafeDomains() async {
    final db = await database;
    final result = await db.query(
      'visited_domains',
      where: 'isSafe = ?',
      whereArgs: [1],
      orderBy: 'timestamp DESC',
    );

    return result.map((json) => VisitedDomain.fromJson(json)).toList();
  }

  // Veritabanını kapatır
  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
} 