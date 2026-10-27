import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/storage/master_catalog_service.dart';
import 'package:app/providers/product_provider.dart';
import 'package:app/models/product_model.dart';

void main() {
  group('MasterProductItem tests', () {
    test('Correctly maps unitmaster piece to pcs', () {
      final item = MasterProductItem.fromMap({
        'barcode': '8901030672484',
        'name': 'Dove Glycolic Hydration 650 ml',
        'image': 'https://images.openfoodfacts.org/example.jpg',
        'unitmaster': 'piece',
      });

      expect(item.barcode, '8901030672484');
      expect(item.name, 'Dove Glycolic Hydration 650 ml');
      expect(item.image, 'https://images.openfoodfacts.org/example.jpg');
      expect(item.unit, 'pcs');
    });

    test('Preserves custom units like kg, g, ml, pack', () {
      final item = MasterProductItem.fromMap({
        'barcode': '123456789',
        'name': 'Aashirvaad Atta 5kg',
        'image': '',
        'unitmaster': 'kg',
      });

      expect(item.unit, 'kg');
      expect(item.toMap()['unitmaster'], 'kg');
    });
  });

  group('BarcodeLookupResult tests', () {
    test('Correctly identifies found in shop', () {
      final product = ProductModel(
        id: 'p1',
        name: 'Maggi 2-Minute Noodles',
        sellingPrice: 1400,
        purchasePrice: 1200,
        barcode: '8901058852720',
      );

      final result = BarcodeLookupResult(existingProduct: product);
      expect(result.foundInShop, isTrue);
      expect(result.foundInMaster, isFalse);
      expect(result.notFound, isFalse);
    });

    test('Correctly identifies found in master catalog', () {
      final master = MasterProductItem(
        barcode: '097855146747',
        name: 'Logitech M235 Wireless Mouse',
        image: 'https://example.com/mouse.jpg',
        unit: 'pcs',
      );

      final result = BarcodeLookupResult(masterItem: master);
      expect(result.foundInShop, isFalse);
      expect(result.foundInMaster, isTrue);
      expect(result.notFound, isFalse);
    });

    test('Correctly identifies not found', () {
      final result = BarcodeLookupResult();
      expect(result.foundInShop, isFalse);
      expect(result.foundInMaster, isFalse);
      expect(result.notFound, isTrue);
    });
  });
}

