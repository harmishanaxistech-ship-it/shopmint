class ProductModel {
  final String id;
  final String name;
  final String barcode;
  final String unit;
  final int purchasePrice; // in paise
  final int sellingPrice; // in paise
  final double currentStock;
  final double minStock;
  final bool isLoose;
  final String imageUrl;
  final bool active;

  ProductModel({
    required this.id,
    required this.name,
    this.barcode = '',
    this.unit = 'pcs',
    required this.purchasePrice,
    required this.sellingPrice,
    this.currentStock = 0,
    this.minStock = 0,
    this.isLoose = false,
    this.imageUrl = '',
    this.active = true,
  });

  bool get isLowStock => currentStock <= minStock;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      barcode: json['barcode'] ?? '',
      unit: json['unit'] ?? 'pcs',
      purchasePrice: json['purchasePrice'] ?? 0,
      sellingPrice: json['sellingPrice'] ?? 0,
      currentStock: (json['currentStock'] ?? 0).toDouble(),
      minStock: (json['minStock'] ?? 0).toDouble(),
      isLoose: json['isLoose'] ?? false,
      imageUrl: json['imageUrl'] ?? '',
      active: json['active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'unit': unit,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'currentStock': currentStock,
      'minStock': minStock,
      'isLoose': isLoose,
      'imageUrl': imageUrl,
      'active': active,
    };
  }
}

