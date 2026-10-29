import 'package:flutter/material.dart';

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
  final Color? color;
  final IconData? icon;

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
    this.color,
    this.icon,
  });

  bool get isLowStock => currentStock <= (minStock > 0 ? minStock : 5);
  bool get isLow => isLowStock;
  double get price => sellingPrice / 100.0;

  Color get categoryColor {
    if (color != null) return color!;
    final lower = name.toLowerCase();
    if (lower.contains('milk') || lower.contains('dairy') || lower.contains('curd')) return const Color(0xFFE8F5FF);
    if (lower.contains('atta') || lower.contains('flour') || lower.contains('wheat')) return const Color(0xFFFFF1DC);
    if (lower.contains('salt') || lower.contains('sugar')) return const Color(0xFFE8F6F5);
    if (lower.contains('biscuit') || lower.contains('parle') || lower.contains('cookie')) return const Color(0xFFFFEBD9);
    if (lower.contains('oil') || lower.contains('ghee')) return const Color(0xFFFFF6D9);
    if (lower.contains('tea') || lower.contains('coffee')) return const Color(0xFFF1E8DD);
    if (lower.contains('maggi') || lower.contains('noodle')) return const Color(0xFFFFE7D9);
    if (lower.contains('soap') || lower.contains('surf') || lower.contains('wash')) return const Color(0xFFE7EEFF);
    return const Color(0xFFE8F6F5);
  }

  IconData get categoryIcon {
    if (icon != null) return icon!;
    final lower = name.toLowerCase();
    if (lower.contains('milk') || lower.contains('dairy') || lower.contains('curd')) return Icons.water_drop_outlined;
    if (lower.contains('atta') || lower.contains('flour') || lower.contains('wheat')) return Icons.breakfast_dining;
    if (lower.contains('salt') || lower.contains('sugar') || lower.contains('grain')) return Icons.grain;
    if (lower.contains('biscuit') || lower.contains('cookie')) return Icons.cookie_outlined;
    if (lower.contains('oil') || lower.contains('ghee')) return Icons.oil_barrel_outlined;
    if (lower.contains('tea') || lower.contains('coffee')) return Icons.local_cafe_outlined;
    if (lower.contains('maggi') || lower.contains('noodle')) return Icons.ramen_dining;
    if (lower.contains('soap') || lower.contains('surf') || lower.contains('wash')) return Icons.local_laundry_service_outlined;
    if (isLoose) return Icons.scale_outlined;
    return Icons.inventory_2_outlined;
  }

  static final List<ProductModel> demoProducts = [
    ProductModel(
      id: 'demo_1',
      name: 'Amul Gold Milk',
      unit: '500 ml',
      sellingPrice: 3400,
      purchasePrice: 2800,
      currentStock: 28,
      minStock: 5,
      barcode: '8901262030015',
      color: const Color(0xFFE8F5FF),
      icon: Icons.water_drop_outlined,
    ),
    ProductModel(
      id: 'demo_2',
      name: 'Aashirvaad Atta',
      unit: '5 kg',
      sellingPrice: 28900,
      purchasePrice: 24000,
      currentStock: 3,
      minStock: 5,
      barcode: '8901725130013',
      color: const Color(0xFFFFF1DC),
      icon: Icons.breakfast_dining,
    ),
    ProductModel(
      id: 'demo_3',
      name: 'Tata Salt',
      unit: '1 kg',
      sellingPrice: 2800,
      purchasePrice: 2200,
      currentStock: 42,
      minStock: 10,
      barcode: '8904043901107',
      color: const Color(0xFFE8F6F5),
      icon: Icons.grain,
    ),
    ProductModel(
      id: 'demo_4',
      name: 'Parle-G Gold',
      unit: '1 pack',
      sellingPrice: 2000,
      purchasePrice: 1600,
      currentStock: 4,
      minStock: 5,
      barcode: '8901719101018',
      color: const Color(0xFFFFEBD9),
      icon: Icons.cookie_outlined,
    ),
    ProductModel(
      id: 'demo_5',
      name: 'Fortune Sunflower Oil',
      unit: '1 L',
      sellingPrice: 14500,
      purchasePrice: 12500,
      currentStock: 16,
      minStock: 5,
      barcode: '8906007280019',
      color: const Color(0xFFFFF6D9),
      icon: Icons.oil_barrel_outlined,
    ),
    ProductModel(
      id: 'demo_6',
      name: 'Tata Tea Gold',
      unit: '250 g',
      sellingPrice: 15500,
      purchasePrice: 13000,
      currentStock: 11,
      minStock: 5,
      barcode: '8901058001025',
      color: const Color(0xFFF1E8DD),
      icon: Icons.local_cafe_outlined,
    ),
    ProductModel(
      id: 'demo_7',
      name: 'Maggi 2-Minute Noodles',
      unit: '70 g',
      sellingPrice: 1400,
      purchasePrice: 1100,
      currentStock: 36,
      minStock: 10,
      barcode: '8901058010218',
      color: const Color(0xFFFFE7D9),
      icon: Icons.ramen_dining,
    ),
    ProductModel(
      id: 'demo_8',
      name: 'Surf Excel Easy Wash',
      unit: '500 g',
      sellingPrice: 9200,
      purchasePrice: 7500,
      currentStock: 2,
      minStock: 5,
      barcode: '8901030865070',
      color: const Color(0xFFE7EEFF),
      icon: Icons.local_laundry_service_outlined,
    ),
  ];

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

