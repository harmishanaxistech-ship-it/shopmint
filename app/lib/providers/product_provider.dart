import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/master_catalog_service.dart';
import '../models/product_model.dart';

class BarcodeLookupResult {
  final ProductModel? existingProduct;
  final MasterProductItem? masterItem;

  BarcodeLookupResult({this.existingProduct, this.masterItem});

  bool get foundInShop => existingProduct != null;
  bool get foundInMaster => masterItem != null;
  bool get notFound => existingProduct == null && masterItem == null;
}

class ProductProvider extends ChangeNotifier {
  final ApiClient _client = ApiClient();

  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<ProductModel> get lowStockProducts => _products.where((p) => p.isLowStock).toList();
  List<ProductModel> get looseProducts => _products.where((p) => p.isLoose).toList();

  Future<void> fetchProducts({String? search, bool? lowStock, bool? isLoose}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _client.dio.get(
        ApiConstants.products,
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (lowStock == true) 'lowStock': 'true',
          if (isLoose != null) 'isLoose': isLoose.toString(),
          'limit': 100,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List raw = response.data['products'] ?? [];
        _products = raw.map((e) => ProductModel.fromJson(e)).toList();
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data?['message'] ?? 'Failed to load products';
    } catch (_) {
      _errorMessage = 'Could not load products. Please check connection.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<BarcodeLookupResult> lookupBarcode(String barcode) async {
    try {
      final response = await _client.dio.get('${ApiConstants.barcodeSearch}/${barcode.trim()}');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final prod = ProductModel.fromJson(response.data['product']);
        return BarcodeLookupResult(existingProduct: prod);
      }
    } catch (_) {}

    final masterItem = await MasterCatalogService.lookupBarcode(barcode);
    if (masterItem != null) {
      return BarcodeLookupResult(masterItem: masterItem);
    }

    return BarcodeLookupResult();
  }

  Future<bool> createProduct({
    required String name,
    String? barcode,
    String unit = 'pcs',
    required int purchasePrice,
    required int sellingPrice,
    double currentStock = 0,
    double minStock = 0,
    bool isLoose = false,
    String? imageUrl,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiConstants.products,
        data: {
          'name': name.trim(),
          if (barcode != null && barcode.isNotEmpty) 'barcode': barcode.trim(),
          'unit': unit,
          'purchasePrice': purchasePrice,
          'sellingPrice': sellingPrice,
          'currentStock': currentStock,
          'minStock': minStock,
          'isLoose': isLoose,
          if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl.trim(),
        },
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        if (barcode != null && barcode.trim().isNotEmpty) {
          MasterCatalogService.saveToMaster(
            MasterProductItem(
              barcode: barcode.trim(),
              name: name.trim(),
              image: imageUrl?.trim() ?? '',
              unit: unit,
            ),
          );
        }
        await fetchProducts();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> addStock(String productId, double quantity, {int? newPurchasePrice}) async {
    try {
      final response = await _client.dio.post(
        '${ApiConstants.products}/$productId/add-stock',
        data: {
          'quantity': quantity,
          ...?newPurchasePrice == null ? null : {'newPurchasePrice': newPurchasePrice},
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        await fetchProducts();
        return true;
      }
    } catch (_) {}
    return false;
  }
}
