import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/shop_mint_models.dart';
import 'test_fixtures.dart';

void main() {
  group('Barcode Normalization and Matching Tests', () {
    test('isBarcodeMatch handles exact barcode matches', () {
      expect(isBarcodeMatch('8901262030015', '8901262030015'), isTrue);
      expect(isBarcodeMatch('  8901262030015  ', '8901262030015'), isTrue);
    });

    test('isBarcodeMatch normalizes leading zeros for EAN-13 and UPC-A equivalence', () {
      expect(isBarcodeMatch('08901262030015', '8901262030015'), isTrue);
      expect(isBarcodeMatch('8901262030015', '08901262030015'), isTrue);
      expect(isBarcodeMatch('001234567890', '1234567890'), isTrue);
    });

    test('isBarcodeMatch rejects empty or differing barcodes', () {
      expect(isBarcodeMatch('', ''), isFalse);
      expect(isBarcodeMatch('', '8901262030015'), isFalse);
      expect(isBarcodeMatch('8901262030015', ''), isFalse);
      expect(isBarcodeMatch('8901262030015', '8909081007156'), isFalse);
    });

    test('sanitizeBarcode strips AIM prefixes and control characters', () {
      expect(sanitizeBarcode(']E08901262030015'), equals('8901262030015'));
      expect(isBarcodeMatch(']E08901262030015', '8901262030015'), isTrue);
      expect(isBarcodeMatch('8901262030015\r\n', '8901262030015'), isTrue);
    });

    test('isBarcodeMatch supports case-insensitive and UPC-A to EAN-13 matching', () {
      expect(isBarcodeMatch('abc12345', 'ABC12345'), isTrue);
      expect(isBarcodeMatch('012345678905', '0012345678905'), isTrue);
    });

    test('ProductItem default barcode is empty and not hardcoded to Basmati rice', () {
      final item = ProductItem(
        name: 'New Custom Item',
        pack: 'piece',
        price: 50,
        stock: 10,
      );
      expect(item.barcode, equals(''));
      expect(item.barcode, isNot('8901262030015'));
    });

    test('Initial products default to empty catalog and test fixtures have unique barcodes', () {
      expect(initialProducts, isEmpty);
      final barcodes = <String>{};
      for (final p in testProducts) {
        if (p.barcode.isNotEmpty) {
          expect(barcodes.contains(p.barcode), isFalse,
              reason: 'Duplicate barcode found: ${p.barcode} for ${p.name}');
          barcodes.add(p.barcode);
        }
      }
    });
  });
}

