import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/product_model.dart';
import '../../../providers/billing_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../widgets/product_image_view.dart';
import '../../billing/new_bill_screen.dart';

class PopularProductsSection extends StatelessWidget {
  final List<PopularProductItem> bestSellers;

  const PopularProductsSection({super.key, required this.bestSellers});

  @override
  Widget build(BuildContext context) {
    final prodProv = Provider.of<ProductProvider>(context);
    final billProv = Provider.of<BillingProvider>(context, listen: false);

    final hasBestSellers = bestSellers.isNotEmpty;
    final fallbackProducts = prodProv.products.take(6).toList();

    if (!hasBestSellers && fallbackProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Popular Products',
              style: AppText.label.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            Text(
              '1-Tap to Bill',
              style: AppText.caption.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 10),

        SizedBox(
          height: 85,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: hasBestSellers ? bestSellers.take(6).length : fallbackProducts.length,
            separatorBuilder: (_, index) => const SizedBox(width: 10),
            itemBuilder: (ctx, idx) {
              String name = '';
              String priceStr = '';
              String imageUrl = '';
              ProductModel? product;

              if (hasBestSellers) {
                final item = bestSellers[idx];
                name = item.name;
                product = prodProv.products.cast<ProductModel?>().firstWhere(
                  (p) => p?.id == item.productId || p?.name.toLowerCase() == item.name.toLowerCase(),
                  orElse: () => null,
                );
                final rate = product != null
                    ? product.sellingPrice
                    : (item.totalQty > 0 ? (item.revenue / item.totalQty).round() : 0);
                priceStr = CurrencyFormatter.formatPaise(rate);
                imageUrl = product?.imageUrl ?? '';
              } else {
                product = fallbackProducts[idx];
                name = product.name;
                priceStr = CurrencyFormatter.formatPaise(product.sellingPrice);
                imageUrl = product.imageUrl;
              }

              return InkWell(
                onTap: () {
                  if (product != null) {
                    billProv.addItemFromProduct(product);
                  } else {
                    billProv.addCustomItem(
                      name: name,
                      rate: CurrencyFormatter.toPaise(20),
                    );
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NewBillScreen()),
                  );
                },
                borderRadius: AppRadius.mdAll,
                child: Container(
                  width: 160,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.mdAll,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      ProductImageView(
                        imageUrl: imageUrl,
                        width: 36,
                        height: 36,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              name,
                              style: AppText.label.copyWith(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              priceStr,
                              style: AppText.amount.copyWith(fontSize: 12, color: AppColors.primaryDark),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark,
                          borderRadius: AppRadius.smAll,
                        ),
                        child: const Icon(Icons.add, size: 14, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
