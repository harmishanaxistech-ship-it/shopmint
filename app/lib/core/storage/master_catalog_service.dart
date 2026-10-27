import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../network/universal_barcode_service.dart';

class MasterProductItem {
  final String barcode;
  final String name;
  final String image;
  final String unit;

  MasterProductItem({
    required this.barcode,
    required this.name,
    required this.image,
    required this.unit,
  });

  factory MasterProductItem.fromMap(Map<String, dynamic> map) {
    var u = map['unitmaster']?.toString().toLowerCase().trim() ?? 'pcs';
    if (u == 'piece') u = 'pcs';
    return MasterProductItem(
      barcode: map['barcode']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      image: map['image']?.toString() ?? '',
      unit: u,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'barcode': barcode,
      'name': name,
      'image': image,
      'unitmaster': unit,
    };
  }
}

class MasterCatalogService {
  static Database? _database;

  static Future<Database> getDatabase() async {
    if (_database != null && _database!.isOpen) return _database!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'master_products.db');
    final file = File(path);

    final bool fileExists = await file.exists();
    int currentLength = 0;
    if (fileExists) {
      currentLength = await file.length();
    }

    // Database is ~3.1MB, re-copy if missing or incomplete
    if (!fileExists || currentLength < 500000) {
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      try {
        debugPrint('Copying master_products.db from assets...');
        final ByteData data = await rootBundle.load('assets/db/master_products.db');
        final List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await file.writeAsBytes(bytes, flush: true);
        debugPrint('Successfully extracted master catalog: ${bytes.length} bytes');
      } catch (e, stack) {
        debugPrint('Failed to copy master catalog asset: $e\n$stack');
      }
    }

    _database = await openDatabase(path);
    return _database!;
  }

  /// Fast 0ms offline lookup in local SQLite database
  static Future<MasterProductItem?> lookupLocal(String barcode) async {
    try {
      final db = await getDatabase();
      final clean = barcode.trim();
      if (clean.isEmpty) return null;

      final variations = <String>{clean};
      if (clean.startsWith('0') && clean.length > 1) {
        variations.add(clean.substring(1));
      } else {
        variations.add('0$clean');
      }

      final placeholders = List.filled(variations.length, '?').join(',');
      final List<Map<String, dynamic>> results = await db.query(
        'masterlist',
        where: 'barcode IN ($placeholders)',
        whereArgs: variations.toList(),
        limit: 1,
      );

      if (results.isNotEmpty) {
        return MasterProductItem.fromMap(results.first);
      }
    } catch (e, stack) {
      debugPrint('Error looking up local barcode $barcode: $e\n$stack');
    }
    return null;
  }

  /// Saves or caches a product in the local SQLite master database for instant offline access
  static Future<void> saveToMaster(MasterProductItem item) async {
    try {
      final cleanBarcode = item.barcode.trim();
      if (cleanBarcode.isEmpty || item.name.trim().isEmpty) return;

      final db = await getDatabase();
      await db.delete(
        'masterlist',
        where: 'barcode = ?',
        whereArgs: [cleanBarcode],
      );

      await db.insert('masterlist', {
        'barcode': cleanBarcode,
        'name': item.name.trim(),
        'image': item.image.trim(),
        'unitmaster': item.unit.trim(),
      });

      debugPrint('Cached product into local masterlist: $cleanBarcode -> ${item.name}');
    } catch (e) {
      debugPrint('Error saving to master catalog: $e');
    }
  }

  /// Universal barcode lookup:
  /// 1. Fast local SQLite lookup (17,499 Indian items, 0ms offline)
  /// 2. Multi-category online fallback (Open Food Facts, Open Beauty Facts, Open Products Facts, UPCItemDB)
  /// 3. Automatically caches newly discovered items into local SQLite for offline access
  static Future<MasterProductItem?> lookupBarcode(String barcode) async {
    final clean = barcode.trim();
    if (clean.isEmpty) return null;

    // 1. Check local catalog first (instant 0ms)
    final localItem = await lookupLocal(clean);
    if (localItem != null) {
      return localItem;
    }

    // 2. Query universal online barcode resolver
    final onlineItem = await UniversalBarcodeService.lookupOnline(clean);
    if (onlineItem != null) {
      // 3. Cache into local SQLite for future offline scans
      await saveToMaster(onlineItem);
      return onlineItem;
    }

    return null;
  }
}
