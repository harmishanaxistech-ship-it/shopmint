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

  static final List<ProductModel> demoProducts = const [];

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

