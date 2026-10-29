import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/bill_model.dart';
import '../models/customer_model.dart';
import '../models/product_model.dart';

class CartItem {
  final ProductModel? product;
  String name;
  String unit;
  double qty;
  int rate; // in paise
  int discount; // in paise
  String? imageUrl;

  CartItem({
    this.product,
    required this.name,
    this.unit = 'pcs',
    this.qty = 1.0,
    required this.rate,
    this.discount = 0,
    this.imageUrl,
  });

  String get displayImageUrl => (imageUrl != null && imageUrl!.isNotEmpty)
      ? imageUrl!
      : (product?.imageUrl ?? '');

  int get lineTotal => (qty * rate - discount).clamp(0, 999999999).round();
}

class BillingProvider extends ChangeNotifier {
  final ApiClient _client = ApiClient();

  final List<CartItem> _items = [];
  CustomerModel? _selectedCustomer;
  String _paymentType = 'Cash';
  int _billDiscount = 0; // in paise
  int? _customReceived; // in paise
  bool _isSaving = false;
  String? _errorMessage;

  List<CartItem> get items => _items;
  CustomerModel? get selectedCustomer => _selectedCustomer;
  String get paymentType => _paymentType;
  int get billDiscount => _billDiscount;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  int get subtotal => _items.fold(0, (sum, i) => sum + i.lineTotal);

  int get grandTotal {
    final unrounded = (subtotal - _billDiscount).clamp(0, 999999999);
    return ((unrounded / 100).round()) * 100;
  }

  int get amountReceived {
    if (_paymentType == 'Credit') return 0;
    return _customReceived ?? grandTotal;
  }

  int get balanceDue => (grandTotal - amountReceived).clamp(0, grandTotal);

  void addItemFromProduct(ProductModel prod, {double qty = 1.0}) {
    final existingIndex = _items.indexWhere((i) => i.product?.id == prod.id);
    if (existingIndex >= 0) {
      _items[existingIndex].qty += qty;
    } else {
      _items.add(
        CartItem(
          product: prod,
          name: prod.name,
          unit: prod.unit,
          qty: qty,
          rate: prod.sellingPrice,
          imageUrl: prod.imageUrl,
        ),
      );
    }
    notifyListeners();
  }

  void addCustomItem({required String name, required int rate, double qty = 1.0, String unit = 'pcs'}) {
    _items.add(
      CartItem(
        name: name,
        rate: rate,
        qty: qty,
        unit: unit,
      ),
    );
    notifyListeners();
  }

  void updateQuantity(int index, double newQty) {
    if (index >= 0 && index < _items.length) {
      if (newQty <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].qty = newQty;
      }
      notifyListeners();
    }
  }

  void updateRate(int index, int newRate) {
    if (index >= 0 && index < _items.length) {
      _items[index].rate = newRate;
      notifyListeners();
    }
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  void setCustomer(CustomerModel? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void setPaymentType(String type) {
    _paymentType = type;
    if (type == 'Credit') {
      _customReceived = 0;
    } else {
      _customReceived = null;
    }
    notifyListeners();
  }

  void setBillDiscount(int discountPaise) {
    _billDiscount = discountPaise;
    notifyListeners();
  }

  void setAmountReceived(int receivedPaise) {
    _customReceived = receivedPaise;
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _selectedCustomer = null;
    _paymentType = 'Cash';
    _billDiscount = 0;
    _customReceived = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<BillModel?> saveBill() async {
    if (_items.isEmpty) {
      _errorMessage = 'Cart is empty';
      notifyListeners();
      return null;
    }

    if (balanceDue > 0 && (_selectedCustomer == null || (_selectedCustomer!.id.isEmpty && _selectedCustomer!.name.isEmpty))) {
      _errorMessage = 'Customer is required for credit balance';
      notifyListeners();
      return null;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = {
        if (_selectedCustomer != null && _selectedCustomer!.id.isNotEmpty) 'customerId': _selectedCustomer!.id,
        'customerName': _selectedCustomer?.name ?? 'Walk-in Customer',
        if (_selectedCustomer != null && _selectedCustomer!.mobile.isNotEmpty) 'customerPhone': _selectedCustomer!.mobile,
        'items': _items.map((i) {
          return {
            if (i.product != null) 'productId': i.product!.id,
            'name': i.name,
            'unit': i.unit,
            'qty': i.qty,
            'rate': i.rate,
            'discount': i.discount,
            'imageUrl': i.displayImageUrl,
          };
        }).toList(),
        'billDiscount': _billDiscount,
        'paymentType': _paymentType,
        'amountReceived': amountReceived,
      };

      final response = await _client.dio.post(ApiConstants.bills, data: payload);

      if (response.statusCode == 201 && response.data['success'] == true) {
        final bill = BillModel.fromJson(response.data['bill']);
        clearCart();
        _isSaving = false;
        notifyListeners();
        return bill;
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      _errorMessage = (data is Map ? data['message'] : null)?.toString() ?? 'Failed to save bill';
    } catch (_) {
      _errorMessage = 'Failed to save bill. Please check connection.';
    }

    _isSaving = false;
    notifyListeners();
    return null;
  }
}

