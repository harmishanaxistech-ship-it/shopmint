import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/bill_model.dart';

class PopularProductItem {
  final String? productId;
  final String name;
  final String unit;
  final double totalQty;
  final int revenue; // in paise
  final int profit; // in paise

  PopularProductItem({
    this.productId,
    required this.name,
    this.unit = 'pcs',
    required this.totalQty,
    required this.revenue,
    required this.profit,
  });

  factory PopularProductItem.fromJson(Map<String, dynamic> json) {
    return PopularProductItem(
      productId: json['productId'],
      name: json['name'] ?? '',
      unit: json['unit'] ?? 'pcs',
      totalQty: (json['totalQty'] ?? 0).toDouble(),
      revenue: json['revenue'] ?? 0,
      profit: json['profit'] ?? 0,
    );
  }
}

class DashboardSummary {
  final int todaySales; // in paise
  final int todayProfit; // in paise
  final int pendingUdhaar; // in paise
  final int lowStockCount;
  final List<BillModel> recentBills;

  DashboardSummary({
    this.todaySales = 0,
    this.todayProfit = 0,
    this.pendingUdhaar = 0,
    this.lowStockCount = 0,
    this.recentBills = const [],
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    var rawBills = json['recentBills'] as List? ?? [];
    return DashboardSummary(
      todaySales: json['todaySales'] ?? 0,
      todayProfit: json['todayProfit'] ?? 0,
      pendingUdhaar: json['pendingUdhaar'] ?? 0,
      lowStockCount: json['lowStockCount'] ?? 0,
      recentBills: rawBills.map((e) => BillModel.fromJson(e)).toList(),
    );
  }
}

class DashboardProvider extends ChangeNotifier {
  final ApiClient _client = ApiClient();

  DashboardSummary _summary = DashboardSummary();
  List<PopularProductItem> _bestSellers = [];
  List<BillModel> _salesBills = [];
  bool _isLoading = false;
  String? _errorMessage;

  DashboardSummary get summary => _summary;
  List<PopularProductItem> get bestSellers => _bestSellers;
  List<BillModel> get salesBills => _salesBills;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _client.dio.get(ApiConstants.dashboard);
      if (response.statusCode == 200 && response.data['success'] == true) {
        _summary = DashboardSummary.fromJson(response.data['summary']);
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      _errorMessage = (data is Map ? data['message'] : null)?.toString() ?? 'Failed to load dashboard';
    } catch (_) {
      _errorMessage = 'Could not connect to server.';
    }

    // Load best sellers for popular products display
    try {
      final bestRes = await _client.dio.get(ApiConstants.bestSellers);
      if (bestRes.statusCode == 200 && bestRes.data['success'] == true) {
        final List raw = bestRes.data['bestSellers'] ?? [];
        _bestSellers = raw.map((e) => PopularProductItem.fromJson(Map<String, dynamic>.from(e))).toList();
      }
    } catch (_) {}

    // Load sales bills for filterable chart
    try {
      final salesRes = await _client.dio.get(ApiConstants.sales);
      if (salesRes.statusCode == 200 && salesRes.data['success'] == true) {
        final List rawBills = salesRes.data['bills'] ?? [];
        _salesBills = rawBills.map((e) => BillModel.fromJson(e)).toList();
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }
}
