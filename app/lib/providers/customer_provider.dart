import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/customer_model.dart';

class LedgerEntryModel {
  final String id;
  final String type;
  final int amount; // in paise
  final int balanceAfter;
  final String note;
  final DateTime createdAt;

  LedgerEntryModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.note,
    required this.createdAt,
  });

  bool get isPayment => type == 'payment';
  bool get isCredit => type == 'credit' || type == 'opening';

  factory LedgerEntryModel.fromJson(Map<String, dynamic> json) {
    return LedgerEntryModel(
      id: json['id'] ?? json['_id'] ?? '',
      type: json['type'] ?? 'credit',
      amount: json['amount'] ?? 0,
      balanceAfter: json['balanceAfter'] ?? 0,
      note: json['note'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}

class CustomerProvider extends ChangeNotifier {
  final ApiClient _client = ApiClient();

  List<CustomerModel> _customers = [];
  int _totalOutstanding = 0; // in paise
  int _countWithBalance = 0;
  bool _isLoading = false;
  String? _errorMessage;

  List<CustomerModel> get customers => _customers;
  int get totalOutstanding => _totalOutstanding;
  int get countWithBalance => _countWithBalance;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchCustomers({String? search, bool? hasBalance}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _client.dio.get(
        ApiConstants.customers,
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (hasBalance == true) 'hasBalance': 'true',
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List raw = response.data['customers'] ?? [];
        _customers = raw.map((e) => CustomerModel.fromJson(e)).toList();
        _totalOutstanding = response.data['totalOutstanding'] ?? 0;
        _countWithBalance = response.data['countWithBalance'] ?? 0;
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      _errorMessage = (data is Map ? data['message'] : null)?.toString() ?? 'Failed to load customers';
    } catch (_) {
      _errorMessage = 'Could not load customers.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<CustomerModel?> createCustomer({
    required String name,
    String mobile = '',
    String address = '',
    int openingBalance = 0,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiConstants.customers,
        data: {
          'name': name.trim(),
          if (mobile.isNotEmpty) 'mobile': mobile.trim(),
          if (address.isNotEmpty) 'address': address.trim(),
          'openingBalance': openingBalance,
        },
      );

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data['success'] == true) {
        final newCust = CustomerModel.fromJson(response.data['customer']);
        await fetchCustomers();
        return newCust;
      }
    } catch (_) {}
    return null;
  }

  Future<List<LedgerEntryModel>> fetchLedger(String customerId) async {
    try {
      final response = await _client.dio.get('${ApiConstants.customers}/$customerId/ledger');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List raw = response.data['entries'] ?? [];
        return raw.map((e) => LedgerEntryModel.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<bool> receivePayment(String customerId, int amount, {String mode = 'Cash', String note = ''}) async {
    try {
      final response = await _client.dio.post(
        '${ApiConstants.customers}/$customerId/payments',
        data: {'amount': amount, 'mode': mode, 'note': note},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        await fetchCustomers();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> addCredit(String customerId, int amount, {String note = ''}) async {
    try {
      final response = await _client.dio.post(
        '${ApiConstants.customers}/$customerId/credit',
        data: {'amount': amount, 'note': note},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        await fetchCustomers();
        return true;
      }
    } catch (_) {}
    return false;
  }
}

