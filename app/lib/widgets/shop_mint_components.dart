import 'dart:io';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/product_model.dart';

// Official ShopMint Palette Constants
const Color mint = Color(0xFF14B8A6);
const Color teal = Color(0xFF0F766E);
const Color darkTeal = Color(0xFF084B45);
const Color brightTeal = Color(0xFF17C3B2);
const Color mintTint = Color(0xFFE5F8F4);
const Color mintTintShadow = Color(0xFFBFEDE3);
const Color canvas = Color(0xFFF5FAF9);
const Color ink = Color(0xFF153330);
const Color muted = Color(0xFF708784);
const Color line = Color(0xFFE4EFED);
const Color amber = Color(0xFFD97706);
const Color amberShadow = Color(0xFF9A5205);
const Color red = Color(0xFFD94B4B);
const Color green = Color(0xFF16845B);
const Color segmentBg = Color(0xFFE6F4F1);
const Color segmentActive = Colors.white;
const Color segmentText = Color(0xFF0F766E);

// Legacy/Compatibility Widgets
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key});

  @override
  Widget build(BuildContext context) => const Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'Shop',
              style: TextStyle(
                color: AppColors.teal,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            TextSpan(
              text: 'Mint',
              style: TextStyle(
                color: AppColors.mint,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
}

class FilterButton extends StatelessWidget {
  const FilterButton({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 39,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.paleMint : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: active ? AppColors.paleMint : AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: active ? AppColors.teal : AppColors.muted,
            ),
          ),
        ),
      );
}

class SmallAction extends StatelessWidget {
  const SmallAction({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.teal, size: 22),
        ),
      );
}

class ProductThumb extends StatelessWidget {
  const ProductThumb({super.key, required this.product, this.size = 46});

  final ProductModel product;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (product.imageUrl.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: product.categoryColor,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFFE5EFED)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          product.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => Icon(
            product.categoryIcon,
            color: AppColors.teal.withAlpha(204),
            size: size * .48,
          ),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: product.categoryColor,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE5EFED)),
      ),
      child: Icon(
        product.categoryIcon,
        color: AppColors.teal.withAlpha(204),
        size: size * .48,
      ),
    );
  }
}

class ProductRow extends StatelessWidget {
  const ProductRow({super.key, required this.product, required this.onTap});

  final ProductModel product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              ProductThumb(product: product, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.currentStock.toInt()} ${product.unit} in stock',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: product.isLow ? FontWeight.w700 : FontWeight.w400,
                        color: product.isLow ? AppColors.red : AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '₹${product.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Color(0xFF9DB5B3)),
            ],
          ),
        ),
      );
}

// Custom Artworks and ShopMint Components
class ProductThumbnail extends StatelessWidget {
  const ProductThumbnail({
    super.key,
    required this.name,
    required this.size,
    this.imageUrl,
  });

  final String name;
  final double size;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      final img = imageUrl!.trim();
      final bool isNetwork = img.startsWith('http://') || img.startsWith('https://');

      Widget imageContent;
      if (isNetwork) {
        imageContent = Image.network(
          img,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallback(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: size,
              height: size,
              color: const Color(0xFFF1EFE9),
              child: const Center(
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: teal),
                ),
              ),
            );
          },
        );
      } else {
        try {
          final file = File(img);
          if (file.existsSync()) {
            imageContent = Image.file(
              file,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildFallback(),
            );
          } else {
            imageContent = _buildFallback();
          }
        } catch (_) {
          imageContent = _buildFallback();
        }
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: line),
          ),
          child: imageContent,
        ),
      );
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    final (bg, fg, label) = _getStyle(name);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: line),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: (size * 0.28).clamp(8, 14),
          fontWeight: FontWeight.w900,
          color: fg,
        ),
      ),
    );
  }

  (Color, Color, String) _getStyle(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('mad angles')) return (const Color(0xFFFFECE5), const Color(0xFFD5521E), 'MAD');
    if (lower.contains('coconut')) return (const Color(0xFFE5F8ED), const Color(0xFF288B4B), 'COCO');
    if (lower.contains('peanut')) return (const Color(0xFFFFF3DE), const Color(0xFFA15A17), 'PB');
    if (lower.contains('bourbon') || lower.contains('dark')) return (const Color(0xFFFFE6E6), const Color(0xFFA62525), 'DRK');
    if (lower.contains('maggi')) return (const Color(0xFFFFF7C2), const Color(0xFFB88200), 'MAG');
    if (lower.contains('jimjam')) return (const Color(0xFFF3E5F8), const Color(0xFF7A2594), 'JIM');
    if (lower.contains('dal')) return (const Color(0xFFFFFAD6), const Color(0xFF8C790D), 'DAL');
    if (lower.contains('rice')) return (const Color(0xFFEBF4FA), const Color(0xFF336C94), 'RICE');
    return (const Color(0xFFF1EFE9), const Color(0xFF6B6554), 'ITEM');
  }
}

class SegmentTab extends StatelessWidget {
  const SegmentTab({
    super.key,
    required this.label,
    this.badge,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: selected ? segmentActive : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: selected ? Border.all(color: const Color(0xFF99F6E4), width: 1) : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? segmentText : muted,
                  ),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: teal,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}

class ChartBar extends StatelessWidget {
  const ChartBar({
    super.key,
    required this.date,
    required this.amount,
    required this.heightFraction,
    required this.isToday,
  });

  final String date;
  final int amount;
  final double heightFraction;
  final bool isToday;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '₹$amount',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isToday ? teal : muted,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 28,
            height: 70 * heightFraction.clamp(0.1, 1.0),
            decoration: BoxDecoration(
              gradient: isToday
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [brightTeal, teal],
                    )
                  : null,
              color: isToday ? null : const Color(0xFFD6EBE7),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            date,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
              color: isToday ? ink : muted,
            ),
          ),
        ],
      );
}

class StorefrontArtwork extends StatelessWidget {
  const StorefrontArtwork({super.key, this.size = 24});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _StorefrontPainter()),
      );
}

class _StorefrontPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = true;
    final w = size.width;
    final h = size.height;

    p.color = mintTint;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.15, h * 0.35, w * 0.7, h * 0.6), const Radius.circular(3)), p);

    p.color = teal;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.1, h * 0.2, w * 0.8, h * 0.2), const Radius.circular(3)), p);

    p.color = Colors.white;
    for (int i = 0; i < 4; i++) {
      canvas.drawRect(Rect.fromLTWH(w * (0.15 + i * 0.18), h * 0.2, w * 0.09, h * 0.2), p);
    }

    p.color = darkTeal;
    canvas.drawRect(Rect.fromLTWH(w * 0.38, h * 0.55, w * 0.24, h * 0.4), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PrinterArtwork extends StatelessWidget {
  const PrinterArtwork({super.key, this.size = 24});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _PrinterPainter()),
      );
}

class _PrinterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = true;
    final w = size.width;
    final h = size.height;

    p.color = const Color(0xFF2C3E50);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.15, h * 0.4, w * 0.7, h * 0.5), const Radius.circular(4)), p);

    p.color = const Color(0xFF1A252F);
    canvas.drawRect(Rect.fromLTWH(w * 0.25, h * 0.38, w * 0.5, h * 0.08), p);

    p.color = Colors.white;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.3, h * 0.15, w * 0.4, h * 0.3), const Radius.circular(2)), p);

    p.color = const Color(0xFFBDC3C7);
    p.strokeWidth = 1.2;
    canvas.drawLine(Offset(w * 0.36, h * 0.22), Offset(w * 0.64, h * 0.22), p);
    canvas.drawLine(Offset(w * 0.36, h * 0.28), Offset(w * 0.64, h * 0.28), p);
    canvas.drawLine(Offset(w * 0.36, h * 0.34), Offset(w * 0.56, h * 0.34), p);

    p.color = mint;
    canvas.drawCircle(Offset(w * 0.75, h * 0.65), 1.5, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WalletArtwork extends StatelessWidget {
  const WalletArtwork({super.key, this.size = 24});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _WalletPainter()),
      );
}

class _WalletPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = true;
    final w = size.width;
    final h = size.height;

    p.color = const Color(0xFF8B5A2B);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.15, h * 0.3, w * 0.7, h * 0.55), const Radius.circular(4)), p);

    p.color = mint;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.25, h * 0.18, w * 0.45, h * 0.2), const Radius.circular(2)), p);

    p.color = const Color(0xFF6B4226);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.15, h * 0.45, w * 0.7, h * 0.3), const Radius.circular(3)), p);

    p.color = const Color(0xFFF1C40F);
    canvas.drawCircle(Offset(w * 0.72, h * 0.45), 3, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ShopkeeperAvatarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..isAntiAlias = true;
    final w = size.width;
    final h = size.height;

    p.color = mintTint;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), p);

    p.color = teal;
    canvas.drawOval(Rect.fromLTWH(w * 0.1, h * 0.6, w * 0.8, h * 0.6), p);

    p.color = const Color(0xFFD9A066);
    canvas.drawCircle(Offset(w * 0.5, h * 0.4), w * 0.24, p);

    p.color = const Color(0xFF2C241E);
    canvas.drawArc(Rect.fromLTWH(w * 0.26, h * 0.16, w * 0.48, w * 0.48), 3.14, 3.14, true, p);

    p.color = const Color(0xFF1E1A17);
    p.strokeWidth = 2;
    p.style = PaintingStyle.stroke;
    canvas.drawArc(Rect.fromLTWH(w * 0.4, h * 0.44, w * 0.2, h * 0.1), 0, 3.14, false, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ShopMintBrandLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;

    p.color = mint;
    final path = Path()
      ..moveTo(w * 0.1, h * 0.35)
      ..lineTo(w * 0.5, h * 0.85)
      ..lineTo(w * 0.9, h * 0.35)
      ..lineTo(w * 0.7, h * 0.35)
      ..lineTo(w * 0.5, h * 0.65)
      ..lineTo(w * 0.3, h * 0.35)
      ..close();
    canvas.drawPath(path, p);

    p.color = teal;
    canvas.drawCircle(Offset(w * 0.5, h * 0.22), 2.5, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CameraGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white12
      ..strokeWidth = 0.5;

    final w = size.width;
    final h = size.height;

    canvas.drawLine(Offset(w * 0.33, 0), Offset(w * 0.33, h), p);
    canvas.drawLine(Offset(w * 0.66, 0), Offset(w * 0.66, h), p);
    canvas.drawLine(Offset(0, h * 0.33), Offset(w, h * 0.33), p);
    canvas.drawLine(Offset(0, h * 0.66), Offset(w, h * 0.66), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void showNote(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: ink,
      duration: actionLabel != null ? const Duration(seconds: 4) : const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      action: (actionLabel != null && onAction != null)
          ? SnackBarAction(
              label: actionLabel,
              textColor: mint,
              onPressed: onAction,
            )
          : null,
    ),
  );
}
