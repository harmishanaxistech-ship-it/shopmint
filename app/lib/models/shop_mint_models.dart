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
  });

  final String time;
  final List<BillLine> items;
  final double total;
  final double profit;
  final bool isUdhaar;
  final String? customerName;
  final String? customerPhone;
  bool isPaid = false;
}

final List<ProductItem> initialProducts = [
  ProductItem(
    name: 'Mad Angles',
    pack: 'piece',
    price: 20,
    stock: 55,
    barcode: '8909081007156',
    imageUrl: 'https://images.openfoodfacts.org/images/products/890/908/100/7156/front_en.1.400.jpg',
    profit: 5,
    soldCount: 5,
  ),
  ProductItem(
    name: 'uji coconut water',
    pack: 'piece',
    price: 60,
    stock: 15,
    barcode: '8901030865070',
    imageUrl: 'https://images.openfoodfacts.org/images/products/890/103/086/5070/front_en.3.400.jpg',
    profit: 20,
    soldCount: 3,
  ),
  ProductItem(
    name: 'Peanut butter',
    pack: 'piece',
    price: 299,
    stock: 3,
    barcode: '8901725130013',
    imageUrl: 'https://images.openfoodfacts.org/images/products/890/172/513/0013/front_en.3.400.jpg',
    profit: 78,
    soldCount: 2,
  ),
  ProductItem(
    name: 'Dark entasy Bourbon',
    pack: 'piece',
    price: 30,
    stock: 54,
    barcode: '8901725016302',
    imageUrl: 'https://images.openfoodfacts.org/images/products/890/172/501/6302/front_en.3.400.jpg',
    profit: 8,
    soldCount: 4,
  ),
  ProductItem(
    name: 'Maggi 2-minutes Noodles',
    pack: 'piece',
    price: 14,
    stock: 113,
    barcode: '8901058010218',
    imageUrl: 'https://images.openfoodfacts.org/images/products/890/105/801/0218/front_en.4.400.jpg',
    profit: 3.5,
    soldCount: 7,
  ),
  ProductItem(
    name: 'Jimjam Pops',
    pack: 'piece',
    price: 20,
    stock: 142,
    barcode: '8901719101018',
    imageUrl: 'https://images.openfoodfacts.org/images/products/890/171/910/1018/front_en.3.400.jpg',
    profit: 6,
    soldCount: 2,
  ),
  ProductItem(
    name: 'moong dal',
    pack: 'kg',
    price: 130,
    stock: 24,
    barcode: '8904043901107',
    imageUrl: '',
    profit: 28,
    soldCount: 17,
  ),
  ProductItem(
    name: 'Basmati rice',
    pack: 'kg',
    price: 150,
    stock: 18,
    barcode: '8901262030022',
    imageUrl: '',
    profit: 32,
    soldCount: 8,
  ),
];

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
