import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/master_catalog_service.dart';

class UniversalBarcodeService {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(milliseconds: 3500),
      receiveTimeout: const Duration(milliseconds: 3500),
      headers: {
        'User-Agent': 'ScanKiranaApp/1.0 (support@scankirana.in)',
        'Accept': 'application/json',
      },
    ),
  );

  static Future<MasterProductItem?> lookupOnline(String rawBarcode) async {
    final clean = rawBarcode.trim();
    if (clean.isEmpty) return null;

    final candidates = <String>[clean];
    if (clean.startsWith('0') && clean.length > 1) {
      candidates.add(clean.substring(1));
    }

    for (final barcode in candidates) {
      final offItem = await _queryOpenFoodFacts(barcode);
      if (offItem != null) return offItem;

      final obfItem = await _queryOpenBeautyFacts(barcode);
      if (obfItem != null) return obfItem;

      final opfItem = await _queryOpenProductsFacts(barcode);
      if (opfItem != null) return opfItem;

      final upcItem = await _queryUpcItemDb(barcode);
      if (upcItem != null) return upcItem;
    }

    return null;
  }

  static Future<MasterProductItem?> _queryOpenFoodFacts(String barcode) async {
    try {
      final url = 'https://world.openfoodfacts.org/api/v0/product/$barcode.json';
      final response = await _dio.get(
        url,
        queryParameters: {
          'fields': 'product_name,product_name_en,generic_name,brands,quantity,image_front_url,image_url',
        },
      );

      if (response.statusCode == 200 && response.data is Map) {
        return _parseOpenFactsResponse(barcode, response.data as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('OpenFoodFacts lookup failed for $barcode: $e');
    }
    return null;
  }

  static Future<MasterProductItem?> _queryOpenBeautyFacts(String barcode) async {
    try {
      final url = 'https://world.openbeautyfacts.org/api/v0/product/$barcode.json';
      final response = await _dio.get(
        url,
        queryParameters: {
          'fields': 'product_name,product_name_en,generic_name,brands,quantity,image_front_url,image_url',
        },
      );

      if (response.statusCode == 200 && response.data is Map) {
        return _parseOpenFactsResponse(barcode, response.data as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('OpenBeautyFacts lookup failed for $barcode: $e');
    }
    return null;
  }

  static Future<MasterProductItem?> _queryOpenProductsFacts(String barcode) async {
    try {
      final url = 'https://world.openproductsfacts.org/api/v0/product/$barcode.json';
      final response = await _dio.get(
        url,
        queryParameters: {
          'fields': 'product_name,product_name_en,generic_name,brands,quantity,image_front_url,image_url',
        },
      );

      if (response.statusCode == 200 && response.data is Map) {
        return _parseOpenFactsResponse(barcode, response.data as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('OpenProductsFacts lookup failed for $barcode: $e');
    }
    return null;
  }

  static Future<MasterProductItem?> _queryUpcItemDb(String barcode) async {
    try {
      final url = 'https://api.upcitemdb.com/prod/trial/lookup';
      final response = await _dio.get(
        url,
        queryParameters: {'upc': barcode},
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final items = data['items'];
        if (items is List && items.isNotEmpty) {
          final first = items[0] as Map<String, dynamic>;
          final title = (first['title']?.toString() ?? '').trim();
          if (title.isNotEmpty) {
            String image = '';
            final images = first['images'];
            if (images is List && images.isNotEmpty) {
              image = images[0]?.toString() ?? '';
              if (image.startsWith('http://')) {
                image = image.replaceFirst('http://', 'https://');
              }
            }

            return MasterProductItem(
              barcode: barcode,
              name: _cleanTitle(title),
              image: image,
              unit: 'pcs',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('UPCItemDB lookup failed for $barcode: $e');
    }
    return null;
  }

  static MasterProductItem? _parseOpenFactsResponse(
    String barcode,
    Map<String, dynamic> data,
  ) {
    if (data['status'] != 1 || data['product'] is! Map) return null;

    final p = data['product'] as Map<String, dynamic>;
    final rawName = (p['product_name'] ?? p['product_name_en'] ?? p['generic_name'])?.toString() ?? '';
    final cleanName = _cleanTitle(rawName);
    if (cleanName.isEmpty) return null;

    final brand = (p['brands']?.toString() ?? '').split(',').first.trim();
    String finalName = cleanName;
    if (brand.isNotEmpty && !finalName.toLowerCase().contains(brand.toLowerCase())) {
      finalName = '$brand $finalName';
    }

    String imageUrl = (p['image_front_url'] ?? p['image_url'])?.toString() ?? '';
    if (imageUrl.startsWith('http://')) {
      imageUrl = imageUrl.replaceFirst('http://', 'https://');
    }

    final quantity = (p['quantity']?.toString() ?? '').toLowerCase();
    String unit = 'pcs';
    if (quantity.contains('kg')) {
      unit = 'kg';
    } else if (quantity.contains('g') && !quantity.contains('kg')) {
      unit = 'g';
    } else if (quantity.contains('ml')) {
      unit = 'ml';
    } else if (quantity.contains('l') && !quantity.contains('ml')) {
      unit = 'l';
    } else if (quantity.contains('pack') || quantity.contains('box')) {
      unit = 'pack';
    }

    return MasterProductItem(
      barcode: barcode,
      name: finalName,
      image: imageUrl,
      unit: unit,
    );
  }

  static String _cleanTitle(String title) {
    return title.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

