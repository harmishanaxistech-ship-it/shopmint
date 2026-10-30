class BillItemModel {
  final String? productId;
  final String name;
  final String unit;
  final double qty;
  final int rate; // in paise
  final int purchasePrice;
  final int discount;
  final String imageUrl;
  final int amount;

  BillItemModel({
    this.productId,
    required this.name,
    this.unit = 'pcs',
    required this.qty,
    required this.rate,
    this.purchasePrice = 0,
    this.discount = 0,
    this.imageUrl = '',
    required this.amount,
  });

  factory BillItemModel.fromJson(Map<String, dynamic> json) {
    return BillItemModel(
      productId: json['productId'],
      name: json['name'] ?? '',
      unit: json['unit'] ?? 'pcs',
      qty: (json['qty'] ?? 1).toDouble(),
      rate: json['rate'] ?? 0,
      purchasePrice: json['purchasePrice'] ?? 0,
      discount: json['discount'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      amount: json['amount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'unit': unit,
      'qty': qty,
      'rate': rate,
      'purchasePrice': purchasePrice,
      'discount': discount,
      'imageUrl': imageUrl,
      'amount': amount,
    };
  }
}

class BillModel {
  final String id;
  final String billNo;
  final String? customerId;
  final String customerName;
  final String? customerPhone;
  final List<BillItemModel> items;
  final int subtotal;
  final int billDiscount;
  final int roundOff;
  final int grandTotal;
  final String paymentType;
  final int amountReceived;
  final int balanceDue;
  final String note;
  final String status;
  final DateTime createdAt;

  BillModel({
    required this.id,
    required this.billNo,
    this.customerId,
    this.customerName = 'Walk-in Customer',
    this.customerPhone,
    required this.items,
    required this.subtotal,
    this.billDiscount = 0,
    this.roundOff = 0,
    required this.grandTotal,
    this.paymentType = 'Cash',
    required this.amountReceived,
    this.balanceDue = 0,
    this.note = '',
    this.status = 'active',
    required this.createdAt,
  });

  bool get isCancelled => status == 'cancelled';
  int get totalProfit => items.fold(0, (sum, it) => sum + ((it.rate - it.purchasePrice) * it.qty).round());

  factory BillModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List? ?? [];
    List<BillItemModel> itemsList = rawItems.map((e) => BillItemModel.fromJson(e)).toList();

    return BillModel(
      id: json['id'] ?? json['_id'] ?? '',
      billNo: json['billNo'] ?? '',
      customerId: json['customerId'],
      customerName: json['customerName'] ?? 'Walk-in Customer',
      customerPhone: json['customerPhone'] as String?,
      items: itemsList,
      subtotal: json['subtotal'] ?? 0,
      billDiscount: json['billDiscount'] ?? 0,
      roundOff: json['roundOff'] ?? 0,
      grandTotal: json['grandTotal'] ?? 0,
      paymentType: json['paymentType'] ?? 'Cash',
      amountReceived: json['amountReceived'] ?? 0,
      balanceDue: json['balanceDue'] ?? 0,
      note: json['note'] ?? '',
      status: json['status'] ?? 'active',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}

