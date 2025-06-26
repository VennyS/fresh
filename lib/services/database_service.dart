import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory;
    try {
      documentsDirectory = await getApplicationDocumentsDirectory();
    } catch (e) {
      documentsDirectory = Directory.current;
    }

    final path = join(documentsDirectory.path, 'storage.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    final sql = await rootBundle.loadString('migrations/001_create_tables.sql');
    final statements = sql.split(';').where((s) => s.trim().isNotEmpty);

    for (final statement in statements) {
      await db.execute(statement);
    }

    await _insertDefaultLocations(db);
  }

  Future<void> _insertDefaultLocations(Database db) async {
    const defaultLocations = [
      {'name': 'Холодильник'},
      {'name': 'Морозильник'},
      {'name': 'Шкафчик'},
      {'name': 'Кладовая'},
      {'name': 'Балкон'},
    ];

    for (final location in defaultLocations) {
      await db.insert('locations', location);
    }
  }

  Future<int> createLocation(String name) async {
    final db = await database;
    return await db.insert('locations', {'name': name});
  }

  Future<List<Map<String, dynamic>>> getAllLocations() async {
    final db = await database;
    return await db.query('locations', orderBy: 'name');
  }

  Future<int> updateLocation(int id, String newName, {String? newIcon}) async {
    final db = await database;
    return await db.update(
      'locations',
      {'name': newName, if (newIcon != null) 'icon': newIcon},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteLocation(int id) async {
    final db = await database;
    return await db.delete('locations', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> addProduct({
    required String name,
    required int locationId,
    String? expirationDate,
    int? quantity,
    String? unit,
  }) async {
    final db = await database;
    return await db.insert('products', {
      'name': name,
      'location_id': locationId,
      'expiration_date': expirationDate,
      'quantity': quantity,
      'unit': unit,
      'added_date': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getProductsByLocation(
    int locationId,
  ) async {
    final db = await database;
    return await db.query(
      'products',
      where: 'location_id = ?',
      whereArgs: [locationId],
      orderBy: 'expiration_date ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getExpiringSoonProducts() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT * FROM products 
      WHERE expiration_date IS NOT NULL 
      AND expiration_date >= date('now') 
      ORDER BY expiration_date ASC 
      LIMIT 10
    ''');
  }

  Future<List<Map<String, dynamic>>> queryAllProducts() async {
    final db = await database;
    return await db.query('products', orderBy: 'name ASC');
  }

  Future<int> updateProduct(Map<String, dynamic> product) async {
    final db = await database;
    return await db.update(
      'products',
      product,
      where: 'id = ?',
      whereArgs: [product['id']],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
