class ProductItem {
  ProductItem({
    required this.name,
    required this.pack,
    required this.price,
    required this.stock,
    this.barcode = '',
    this.imageUrl = '',
    this.profit = 0,
    this.soldCount = 0,
  });

  String name;
  String pack;
  double price;
  int stock;
  String barcode;
  String imageUrl;
  double profit;
  int soldCount;
  bool get isLow => stock <= 5;

  ProductItem copyWith({
    String? name,
    String? pack,
    double? price,
    int? stock,
    String? barcode,
    String? imageUrl,
    double? profit,
    int? soldCount,
  }) {
    return ProductItem(
      name: name ?? this.name,
      pack: pack ?? this.pack,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      barcode: barcode ?? this.barcode,
      imageUrl: imageUrl ?? this.imageUrl,
      profit: profit ?? this.profit,
      soldCount: soldCount ?? this.soldCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'pack': pack,
        'price': price,
        'stock': stock,
        'barcode': barcode,
        'imageUrl': imageUrl,
        'profit': profit,
        'soldCount': soldCount,
      };

  factory ProductItem.fromJson(Map<String, dynamic> json) => ProductItem(
        name: json['name'] as String? ?? '',
        pack: json['pack'] as String? ?? 'piece',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        stock: (json['stock'] as num?)?.toInt() ?? 0,
        barcode: json['barcode'] as String? ?? '',
        imageUrl: json['imageUrl'] as String? ?? '',
        profit: (json['profit'] as num?)?.toDouble() ?? 0.0,
        soldCount: (json['soldCount'] as num?)?.toInt() ?? 0,
      );
}

class BillLine {
  BillLine(this.product, this.qty);
  final ProductItem product;
  int qty;
  double get total => product.price * qty;

  Map<String, dynamic> toJson() => {
        'product': product.toJson(),
        'qty': qty,
      };

  factory BillLine.fromJson(Map<String, dynamic> json) => BillLine(
        ProductItem.fromJson(Map<String, dynamic>.from(json['product'] as Map)),
        (json['qty'] as num?)?.toInt() ?? 1,
      );
}

class OrderRecord {
  OrderRecord({
    required this.time,
    required this.items,
    required this.total,
    required this.profit,
    this.isUdhaar = false,
    this.customerName,
    this.customerPhone,
    this.isPaid = false,
    this.date,
    this.billNo,
  });

  final String time;
  final List<BillLine> items;
  final double total;
  final double profit;
  final bool isUdhaar;
  final String? customerName;
  final String? customerPhone;
  bool isPaid;
  final String? date;
  String? billNo;

  Map<String, dynamic> toJson() => {
        'time': time,
        'items': items.map((i) => i.toJson()).toList(),
        'total': total,
        'profit': profit,
        'isUdhaar': isUdhaar,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'isPaid': isPaid,
        'date': date,
        'billNo': billNo,
      };

  factory OrderRecord.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    return OrderRecord(
      time: json['time'] as String? ?? '',
      items: rawItems.map((e) => BillLine.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      profit: (json['profit'] as num?)?.toDouble() ?? 0.0,
      isUdhaar: json['isUdhaar'] as bool? ?? false,
      customerName: json['customerName'] as String?,
      customerPhone: json['customerPhone'] as String?,
      isPaid: json['isPaid'] as bool? ?? false,
      date: json['date'] as String?,
      billNo: json['billNo'] as String?,
    );
  }
}

final List<ProductItem> initialProducts = const [];

String sanitizeBarcode(String input) {
  var s = input.trim();
  if (s.startsWith(']') && s.length > 3) {
    s = s.substring(3).trim();
  }
  s = s.replaceAll(RegExp(r'[\u0000-\u001F\u007F-\u009F\u200B-\u200D\uFEFF]'), '');
  return s.trim();
}

bool isBarcodeMatch(String a, String b) {
  final cleanA = sanitizeBarcode(a);
  final cleanB = sanitizeBarcode(b);
  if (cleanA.isEmpty || cleanB.isEmpty) return false;
  if (cleanA == cleanB) return true;
  if (cleanA.toLowerCase() == cleanB.toLowerCase()) return true;

  final normA = cleanA.replaceFirst(RegExp(r'^0+'), '');
  final normB = cleanB.replaceFirst(RegExp(r'^0+'), '');
  if (normA.isNotEmpty && normA.toLowerCase() == normB.toLowerCase()) return true;

  if (cleanA.length == 12 && cleanB.length == 13 && '0$cleanA' == cleanB) return true;
  if (cleanB.length == 12 && cleanA.length == 13 && '0$cleanB' == cleanA) return true;

  return false;
}
