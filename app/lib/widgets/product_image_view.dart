import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_tokens.dart';

class ProductImageView extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final IconData placeholderIcon;
  final double iconSize;

  const ProductImageView({
    super.key,
    required this.imageUrl,
    this.width = 44,
    this.height = 44,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.placeholderIcon = Icons.inventory_2_outlined,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? AppRadius.smAll;
    final trimmed = imageUrl?.trim() ?? '';

    Widget imageContent;

    if (trimmed.isEmpty) {
      imageContent = _buildPlaceholder();
    } else if (trimmed.startsWith('data:image/') || _isRawBase64(trimmed)) {
      try {
        final base64String = trimmed.contains(',') ? trimmed.split(',').last : trimmed;
        final Uint8List bytes = base64Decode(base64String);
        imageContent = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      } catch (_) {
        imageContent = _buildPlaceholder();
      }
    } else if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      imageContent = Image.network(
        trimmed,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: iconSize,
              height: iconSize,
              child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
          );
        },
      );
    } else {
      final file = File(trimmed);
      if (file.existsSync()) {
        imageContent = Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      } else {
        imageContent = _buildPlaceholder();
      }
    }

    return ClipRRect(
      borderRadius: effectiveRadius,
      child: Container(
        width: width,
        height: height,
        color: AppColors.background,
        child: imageContent,
      ),
    );
  }

  bool _isRawBase64(String str) {
    return str.length > 100 && !str.contains(' ') && !str.startsWith('http');
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.surface,
      alignment: Alignment.center,
      child: Icon(
        placeholderIcon,
        size: iconSize,
        color: AppColors.textSecondary.withValues(alpha: 0.6),
      ),
    );
  }
}
