import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../core/storage/master_catalog_service.dart';
import '../../models/customer_model.dart';
import '../../models/product_model.dart';
import '../../models/shop_mint_models.dart';
import '../../providers/customer_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/app_3d_button.dart';
import '../../widgets/shop_mint_components.dart';

class MakeBillTab extends StatefulWidget {
  const MakeBillTab({
    super.key,
    this.isActive = true,
    required this.products,
    required this.bill,
    required this.total,
    required this.onAdd,
    required this.onQty,
    required this.onRemove,
    required this.onClear,
    required this.onCheckout,
    this.onAddProduct,
    this.onEditProduct,
  });

  final bool isActive;
  final List<ProductItem> products;
  final Map<String, BillLine> bill;
  final double total;
  final void Function(ProductItem, [int]) onAdd;
  final void Function(ProductItem, int) onQty;
  final void Function(String) onRemove;
  final VoidCallback onClear;
  final void Function(bool isUdhaar, String? customerName, String? phone) onCheckout;
  final void Function(ProductItem)? onAddProduct;
  final void Function(ProductItem)? onEditProduct;

  @override
  State<MakeBillTab> createState() => _MakeBillTabState();
}

class _MakeBillTabState extends State<MakeBillTab> with SingleTickerProviderStateMixin {
  bool _torchOn = false;
  bool _isProcessingScan = false;
  bool _isLookingUpBarcode = false;
  String? _capturedBarcode;
  MobileScannerController? _cameraController;
  DateTime _lastScanTime = DateTime.now().subtract(const Duration(seconds: 5));
  String? _lastCode;
  String? _duplicateAlertBarcode;
  String? _successAlertBarcode;
  Timer? _duplicateClearTimer;
  Timer? _successClearTimer;
  late final AnimationController _laserAnim;
  double _zoomScale = 0.0;

  @override
  void initState() {
    super.initState();
    final bool isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    _laserAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (!isTest) {
      if (widget.isActive) {
        _laserAnim.repeat(reverse: true);
      }
      try {
        _cameraController = MobileScannerController(
          facing: CameraFacing.back,
          detectionSpeed: DetectionSpeed.unrestricted,
          cameraResolution: const Size(1280, 720),
          autoZoom: false,
          autoStart: widget.isActive,
          formats: const [
            BarcodeFormat.ean13,
            BarcodeFormat.ean8,
            BarcodeFormat.upcA,
            BarcodeFormat.upcE,
            BarcodeFormat.code128,
            BarcodeFormat.qrCode,
          ],
        );
      } catch (_) {}
    }
  }

  @override
  void didUpdateWidget(MakeBillTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      final bool isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
      if (widget.isActive) {
        if (!isTest) {
          _laserAnim.repeat(reverse: true);
          try {
            _cameraController?.start();
          } catch (_) {}
        }
      } else {
        _laserAnim.stop();
        try {
          _cameraController?.stop();
        } catch (_) {}
        _duplicateClearTimer?.cancel();
        _successClearTimer?.cancel();
        _duplicateAlertBarcode = null;
        _successAlertBarcode = null;
        _isLookingUpBarcode = false;
        _capturedBarcode = null;
      }
    }
  }

  @override
  void dispose() {
    _laserAnim.dispose();
    _duplicateClearTimer?.cancel();
    _successClearTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  void _triggerDuplicateAlert(ProductItem product, int currentQty) {
    HapticFeedback.heavyImpact();
    _duplicateClearTimer?.cancel();
    setState(() {
      _duplicateAlertBarcode = product.barcode;
      _successAlertBarcode = null;
    });
    _duplicateClearTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _duplicateAlertBarcode = null);
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (product.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  product.imageUrl,
                  width: 30,
                  height: 30,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
                ),
              )
            else
              const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${product.name} already in bill (Qty: $currentQty)',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: '+1 More',
          textColor: Colors.white,
          onPressed: () => widget.onQty(product, 1),
        ),
        duration: const Duration(milliseconds: 2500),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        backgroundColor: amber,
      ),
    );
  }

  void _triggerSuccessScan(ProductItem product, {int? updatedQty, bool showToast = true}) {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.mediumImpact();
    _successClearTimer?.cancel();
    setState(() {
      _successAlertBarcode = product.barcode;
      _duplicateAlertBarcode = null;
    });
    _successClearTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _successAlertBarcode = null);
    });

    if (showToast) {
      ScaffoldMessenger.of(context).clearSnackBars();
      final qtyText = updatedQty != null && updatedQty > 1 ? ' (Qty: $updatedQty)' : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              if (product.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    product.imageUrl,
                    width: 32,
                    height: 32,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  ),
                )
              else
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${product.name}$qtyText',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    Text(
                      '₹${product.price.toInt()} per ${product.pack}',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          duration: const Duration(milliseconds: 900),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          backgroundColor: teal,
        ),
      );
    }
  }

  Future<void> _onBarcodeDetected(String rawCode) async {
    if (!widget.isActive) return;
    final code = sanitizeBarcode(rawCode);
    if (code.isEmpty || _isProcessingScan) return;
    final now = DateTime.now();

    if (_lastCode != null && isBarcodeMatch(_lastCode!, code) && now.difference(_lastScanTime).inMilliseconds < 1200) {
      return;
    }

    _lastCode = code;
    _lastScanTime = now;
    _isProcessingScan = true;

    final prodProv = Provider.of<ProductProvider>(context, listen: false);

    // 1. Audio and Haptic feedback for barcode captured
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.mediumImpact();

    // 2. Immediate visual state: Barcode captured + Loading display with barcode
    setState(() {
      _capturedBarcode = code;
      _isLookingUpBarcode = true;
    });

    try {
      // Minimum duration so user visually perceives "Barcode captured -> Loading with barcode"
      final minDelay = Future.delayed(const Duration(milliseconds: 400));

      // 1. Search in active bill items
      ProductItem? match;
      for (final entry in widget.bill.entries) {
        if (isBarcodeMatch(entry.key, code) || isBarcodeMatch(entry.value.product.barcode, code)) {
          match = entry.value.product;
          break;
        }
      }

      // 2. Search in shop products list
      if (match == null) {
        for (final p in widget.products) {
          if (isBarcodeMatch(p.barcode, code)) {
            match = p;
            break;
          }
        }
      }

      // 3. Search in live ProductProvider database
      if (match == null) {
        try {
          for (final p in prodProv.products) {
            if (isBarcodeMatch(p.barcode, code)) {
              match = ProductItem(
                name: p.name,
                pack: p.unit.isNotEmpty ? p.unit : 'piece',
                price: p.price,
                stock: p.currentStock.toInt(),
                barcode: p.barcode.trim(),
                imageUrl: p.imageUrl,
                profit: (p.price - (p.purchasePrice / 100.0)).clamp(0, 99999),
              );
              widget.onAddProduct?.call(match);
              break;
            }
          }
        } catch (_) {}
      }

      MasterProductItem? masterItem;
      ProductModel? serverGlobalProduct;

      // 4. If not found in shop, check global master catalog and backend server
      if (match == null) {
        try {
          masterItem = await MasterCatalogService.lookupBarcode(code);
        } catch (_) {}

        if (masterItem == null) {
          try {
            final lookupRes = await prodProv.lookupBarcode(code);
            if (lookupRes.existingProduct != null) {
              serverGlobalProduct = lookupRes.existingProduct;
            } else if (lookupRes.masterItem != null) {
              masterItem = lookupRes.masterItem;
            }
          } catch (_) {}
        }
      }

      await minDelay;

      if (!mounted) return;

      // Dismiss camera loading overlay before opening modal
      setState(() {
        _isLookingUpBarcode = false;
      });

      // 5. View Product Popup
      if (match != null) {
        int existingQty = 0;
        for (final entry in widget.bill.entries) {
          if (isBarcodeMatch(entry.key, code) || isBarcodeMatch(entry.value.product.barcode, code)) {
            existingQty = entry.value.qty;
            break;
          }
        }

        await showScannedProductModal(
          context: context,
          product: match,
          currentBillQty: existingQty,
          onAdd: (item, qty) {
            widget.onAdd(item, qty);
            _triggerSuccessScan(item, updatedQty: existingQty > 0 ? existingQty + qty : qty);
          },
          onEdit: widget.onEditProduct,
        );
      } else {
        final initialName = masterItem?.name ?? serverGlobalProduct?.name ?? '';
        final initialUnit = masterItem?.unit ?? serverGlobalProduct?.unit ?? 'piece';
        final initialImage = masterItem?.image ?? serverGlobalProduct?.imageUrl ?? '';
        final isFound = masterItem != null || serverGlobalProduct != null;

        await showAddNewBarcodeProductModal(
          context,
          barcode: code,
          initialName: initialName,
          initialUnit: initialUnit,
          initialImage: initialImage,
          isMasterFound: isFound,
          onAdded: (newItem) {
            MasterCatalogService.saveToMaster(MasterProductItem(
              barcode: newItem.barcode,
              name: newItem.name,
              image: newItem.imageUrl,
              unit: newItem.pack,
            ));
            widget.onAddProduct?.call(newItem);
            widget.onAdd(newItem, 1);
            _triggerSuccessScan(newItem);
          },
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLookingUpBarcode = false;
          _capturedBarcode = null;
        });
      }
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) _isProcessingScan = false;
      });
    }
  }

  void _showManualBarcodeInput(BuildContext context) {
    setState(() => _isProcessingScan = true);
    final textCtrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(color: const Color(0xFFCCE3DF), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 14),
                const Row(
                  children: [
                    Icon(Icons.keyboard_alt_outlined, color: teal, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Enter Barcode Manually',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ink),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: canvas,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: line),
                  ),
                  child: TextField(
                    controller: textCtrl,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ink),
                    decoration: const InputDecoration(
                      hintText: 'e.g. 8901030865070',
                      hintStyle: TextStyle(fontSize: 14, color: muted),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (val) {
                      final valTrim = val.trim();
                      if (valTrim.isNotEmpty) {
                        Navigator.pop(ctx);
                        setState(() => _isProcessingScan = false);
                        _onBarcodeDetected(valTrim);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Vanik3DButton(
                  variant: VanikButtonVariant.green,
                  height: 48,
                  label: 'Lookup Barcode',
                  icon: const Icon(Icons.search_rounded, size: 18, color: Colors.white),
                  onPressed: () {
                    final valTrim = textCtrl.text.trim();
                    if (valTrim.isNotEmpty) {
                      Navigator.pop(ctx);
                      setState(() => _isProcessingScan = false);
                      _onBarcodeDetected(valTrim);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      if (mounted) setState(() => _isProcessingScan = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.bill.values.toList();
    final screenH = MediaQuery.of(context).size.height;
    final cameraHeight = screenH < 650 ? 150.0 : (screenH < 780 ? 175.0 : 210.0);
    final reticleHeight = (cameraHeight * 0.48).clamp(70.0, 110.0);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // Camera viewfinder container at top
          Container(
            height: cameraHeight,
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.isActive && _cameraController != null)
                    MobileScanner(
                      controller: _cameraController!,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err) => CustomPaint(painter: CameraGridPainter()),
                      onDetect: (capture) {
                        if (!widget.isActive) return;
                        for (final barcode in capture.barcodes) {
                          final code = (barcode.displayValue ?? barcode.rawValue ?? '').trim();
                          if (code.isNotEmpty) {
                            _onBarcodeDetected(code);
                            break;
                          }
                        }
                      },
                    )
                  else
                    CustomPaint(painter: CameraGridPainter()),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xB3000000), Colors.transparent, Color(0xB3000000)],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 12,
                    right: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: const BoxDecoration(
                                  color: mint,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const Flexible(
                                child: Text(
                                  'Scan Barcode',
                                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () async {
                                final nextZoom = _zoomScale > 0.1 ? 0.0 : 0.35;
                                try {
                                  await _cameraController?.setZoomScale(nextZoom);
                                  if (mounted) setState(() => _zoomScale = nextZoom);
                                } catch (_) {}
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                margin: const EdgeInsets.only(right: 4),
                                decoration: BoxDecoration(
                                  color: _zoomScale > 0.1 ? mint : Colors.white24,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _zoomScale > 0.1 ? '2.0x' : '1.0x',
                                  style: TextStyle(
                                    color: _zoomScale > 0.1 ? ink : Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Type Barcode',
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              icon: const Icon(Icons.keyboard_alt_outlined, color: Colors.white, size: 19),
                              onPressed: () => _showManualBarcodeInput(context),
                            ),
                            IconButton(
                              tooltip: 'Torch',
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              icon: Icon(_torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded, color: Colors.white, size: 18),
                              onPressed: () {
                                setState(() => _torchOn = !_torchOn);
                                try {
                                  _cameraController?.toggleTorch();
                                } catch (_) {}
                              },
                            ),
                            if (widget.bill.isNotEmpty)
                              IconButton(
                                tooltip: 'Clear Bill',
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 18),
                                onPressed: widget.onClear,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 210,
                      height: reticleHeight,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _duplicateAlertBarcode != null
                              ? amber
                              : (_successAlertBarcode != null ? const Color(0xFF10B981) : mint),
                          width: 2.2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          if (_successAlertBarcode != null)
                            BoxShadow(
                              color: const Color(0xFF10B981).withAlpha(120),
                              blurRadius: 10,
                              spreadRadius: 2,
                            )
                          else if (_duplicateAlertBarcode != null)
                            BoxShadow(
                              color: amber.withAlpha(120),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _laserAnim,
                            builder: (context, _) => Positioned(
                              top: 6 + (_laserAnim.value * (reticleHeight - 20)),
                              child: Container(
                                height: 2,
                                width: 185,
                                decoration: BoxDecoration(
                                  color: _duplicateAlertBarcode != null
                                      ? amber
                                      : (_successAlertBarcode != null ? const Color(0xFF10B981) : mint),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_duplicateAlertBarcode != null ? amber : mint).withAlpha(150),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (_successAlertBarcode != null)
                            const Center(
                              child: Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 36),
                            ),
                          Positioned(
                            bottom: 6,
                            child: Text(
                              _duplicateAlertBarcode != null
                                  ? 'Already in bill!'
                                  : (_successAlertBarcode != null ? 'Added to bill!' : 'Aim at barcode'),
                              style: TextStyle(
                                color: _duplicateAlertBarcode != null
                                    ? amber
                                    : (_successAlertBarcode != null ? const Color(0xFF10B981) : Colors.white70),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 12,
                    right: 12,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: widget.products
                            .map(
                              (p) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: InkWell(
                                  onTap: () {
                                    final existingLine = widget.bill[p.barcode];
                                    if (existingLine != null) {
                                      _triggerDuplicateAlert(p, existingLine.qty);
                                    } else {
                                      widget.onAdd(p, 1);
                                      _triggerSuccessScan(p, showToast: false);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: ProductThumbnail(name: p.name, size: 16, imageUrl: p.imageUrl),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          p.name.split(' ').first,
                                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(width: 2),
                                        const Icon(Icons.add_rounded, size: 13, color: Colors.white70),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                  if (_isLookingUpBarcode && _capturedBarcode != null)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withAlpha(190),
                        child: Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F3E36),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: mint, width: 1.8),
                              boxShadow: [
                                BoxShadow(
                                  color: mint.withAlpha(90),
                                  blurRadius: 14,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: mint.withAlpha(50),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle_rounded, color: mint, size: 14),
                                      SizedBox(width: 5),
                                      Text(
                                        'Barcode Captured',
                                        style: TextStyle(color: mint, fontSize: 12, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.black38,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.qr_code_scanner_rounded, color: Colors.white70, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        _capturedBarcode!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'monospace',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: mint),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Loading product details...',
                                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bill',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: teal),
                ),
                Vanik3DButton(
                  variant: VanikButtonVariant.beige,
                  height: 36,
                  width: 115,
                  fontSize: 12,
                  icon: const Icon(Icons.inventory_2_outlined, size: 15, color: teal),
                  label: 'Loose Item',
                  onPressed: () {
                    setState(() => _isProcessingScan = true);
                    showAddLooseBillLineModal(context, widget.products, (item, qty) {
                      final existingLine = widget.bill[item.barcode];
                      if (existingLine != null) {
                        _triggerDuplicateAlert(item, existingLine.qty);
                      } else {
                        widget.onAdd(item, qty);
                      }
                    }).then((_) {
                      if (mounted) setState(() => _isProcessingScan = false);
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: lines.isEmpty
                ? const Center(
                    child: SingleChildScrollView(
                      physics: NeverScrollableScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_basket_outlined, size: 36, color: Color(0xFFC7DFDA)),
                            SizedBox(height: 6),
                            Text('Bill is empty', style: TextStyle(color: muted, fontWeight: FontWeight.w600, fontSize: 13)),
                            SizedBox(height: 2),
                            Text('Tap items above to scan them into bill', style: TextStyle(color: muted, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    itemCount: lines.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: line),
                    itemBuilder: (context, index) {
                      final lineItem = lines[index];
                      final isDuplicateAlert = _duplicateAlertBarcode != null &&
                          isBarcodeMatch(_duplicateAlertBarcode!, lineItem.product.barcode);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDuplicateAlert ? const Color(0xFFFEF3C7) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDuplicateAlert ? amber : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            ProductThumbnail(
                              name: lineItem.product.name,
                              size: 38,
                              imageUrl: lineItem.product.imageUrl,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lineItem.product.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ink),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '₹${lineItem.product.price.toStringAsFixed(0)} / ${lineItem.product.pack}',
                                    style: const TextStyle(fontSize: 11, color: muted),
                                  ),
                                ],
                              ),
                            ),
                            // Direct inline quantity stepper [-] [Qty] [+]
                            Container(
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: line),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    key: ValueKey('stepper_minus_${lineItem.product.barcode}'),
                                    onTap: () => widget.onQty(lineItem.product, -1),
                                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      child: Icon(Icons.remove_rounded, size: 16, color: ink),
                                    ),
                                  ),
                                  InkWell(
                                    key: ValueKey('stepper_qty_${lineItem.product.barcode}'),
                                    onTap: () => showEditQtyDialog(context, lineItem, (delta) => widget.onQty(lineItem.product, delta)),
                                    child: Container(
                                      constraints: const BoxConstraints(minWidth: 28),
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      color: Colors.white,
                                      child: Text(
                                        '${lineItem.qty}',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: teal),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    key: ValueKey('stepper_plus_${lineItem.product.barcode}'),
                                    onTap: () => widget.onQty(lineItem.product, 1),
                                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      child: Icon(Icons.add_rounded, size: 16, color: ink),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 54,
                              child: Text(
                                '₹${lineItem.total.toStringAsFixed(0)}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: ink),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Quick remove button
                            GestureDetector(
                              key: ValueKey('remove_${lineItem.product.barcode}'),
                              onTap: () => widget.onRemove(lineItem.product.barcode),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.close_rounded, size: 16, color: red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          // Sticky bottom checkout bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: line)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Total', style: TextStyle(fontSize: 12, color: muted, fontWeight: FontWeight.w600)),
                      Text(
                        '₹${widget.total.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: ink),
                      ),
                    ],
                  ),
                ),
                Vanik3DButton(
                  variant: VanikButtonVariant.green,
                  height: 48,
                  width: 140,
                  fontSize: 14,
                  icon: const PrinterArtwork(size: 20),
                  label: 'Complete',
                  onPressed: () {
                    if (widget.bill.isEmpty) {
                      showNote(context, 'Add items to the bill first');
                      return;
                    }
                    setState(() => _isProcessingScan = true);
                    _showPaymentModal(context, widget.total, widget.onCheckout).then((_) {
                      if (mounted) setState(() => _isProcessingScan = false);
                    });
                  },
                ),
                const SizedBox(width: 8),
                Vanik3DButton(
                  variant: VanikButtonVariant.beige,
                  height: 48,
                  width: 48,
                  label: '',
                  icon: const Icon(Icons.receipt_long_rounded, size: 22, color: teal),
                  onPressed: () {
                    if (widget.bill.isEmpty) {
                      showNote(context, 'Bill is empty');
                      return;
                    }
                    setState(() => _isProcessingScan = true);
                    _showPaymentModal(context, widget.total, widget.onCheckout).then((_) {
                      if (mounted) setState(() => _isProcessingScan = false);
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void showEditQtyDialog(BuildContext context, BillLine line, void Function(int delta) onUpdate) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(line.product.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline_rounded, size: 28, color: muted),
            onPressed: () {
              onUpdate(-1);
              Navigator.pop(ctx);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${line.qty} ${line.product.pack}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ink),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_rounded, size: 28, color: teal),
            onPressed: () {
              onUpdate(1);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Done', style: TextStyle(color: teal, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
}

Future<void> showAddLooseBillLineModal(BuildContext context, List<ProductItem> products, void Function(ProductItem item, int qty) onAdd) {
  final looseItems = products.where((p) => p.pack == 'kg' || p.barcode.startsWith('LOOSE')).toList();

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFFCCE3DF), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Select Loose Item to Add', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ink)),
            const SizedBox(height: 12),
            if (looseItems.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('No loose items found. Add one from My Shop.', style: TextStyle(color: muted))),
              )
            else
              ...looseItems.map(
                (it) => ListTile(
                  leading: ProductThumbnail(name: it.name, size: 36, imageUrl: it.imageUrl),
                  title: Text(it.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('₹${it.price.toStringAsFixed(0)} per ${it.pack}'),
                  trailing: const Icon(Icons.add_circle_outline_rounded, color: teal),
                  onTap: () {
                    Navigator.pop(ctx);
                    onAdd(it, 1);
                  },
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildImagePreviewWidget(String path, {double size = 60}) {
  final clean = path.trim();
  if (clean.isEmpty) {
    return Container(
      color: mintTint,
      child: const Icon(Icons.add_a_photo_outlined, color: teal, size: 26),
    );
  }
  if (clean.startsWith('http://') || clean.startsWith('https://')) {
    return Image.network(
      clean,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: mintTint,
        child: const Icon(Icons.broken_image_rounded, color: teal, size: 26),
      ),
    );
  } else {
    try {
      final f = File(clean);
      if (f.existsSync()) {
        return Image.file(
          f,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: mintTint,
            child: const Icon(Icons.broken_image_rounded, color: teal, size: 26),
          ),
        );
      }
    } catch (_) {}
    return Container(
      color: mintTint,
      child: const Icon(Icons.image_outlined, color: teal, size: 26),
    );
  }
}

Future<void> _pickImageForModal({
  required ImageSource source,
  required TextEditingController controller,
  required void Function(void Function()) setModalState,
}) async {
  try {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked != null) {
      setModalState(() {
        controller.text = picked.path;
      });
    }
  } catch (e) {
    debugPrint('Image pick error: $e');
  }
}

void _showImagePickerSheet(
  BuildContext context, {
  required TextEditingController controller,
  required void Function(void Function()) setModalState,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFFCCE3DF), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Select Product Photo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ink),
            ),
            const SizedBox(height: 14),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: mintTint, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.camera_alt_rounded, color: teal),
              ),
              title: const Text('Take Photo with Camera', style: TextStyle(fontWeight: FontWeight.w700, color: ink)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImageForModal(source: ImageSource.camera, controller: controller, setModalState: setModalState);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: canvas, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.photo_library_outlined, color: ink),
              ),
              title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w700, color: ink)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImageForModal(source: ImageSource.gallery, controller: controller, setModalState: setModalState);
              },
            ),
            if (controller.text.isNotEmpty)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626)),
                ),
                title: const Text('Remove Image', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFDC2626))),
                onTap: () {
                  Navigator.pop(ctx);
                  setModalState(() => controller.clear());
                },
              ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showScannedProductModal({
  required BuildContext context,
  required ProductItem product,
  required int currentBillQty,
  required void Function(ProductItem item, int qty) onAdd,
  void Function(ProductItem item)? onEdit,
}) async {
  int selectedQty = 1;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) {
        final lineTotal = product.price * selectedQty;

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            top: false,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCCE3DF),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: mintTint,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: mint),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, color: teal, size: 14),
                              SizedBox(width: 5),
                              Text(
                                'Product Scanned',
                                style: TextStyle(color: teal, fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.close_rounded, color: muted),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: canvas,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: line),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 64,
                              height: 64,
                              color: Colors.white,
                              child: _buildImagePreviewWidget(product.imageUrl, size: 64),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (product.barcode.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    margin: const EdgeInsets.only(bottom: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: line),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.qr_code_2_rounded, size: 12, color: muted),
                                        const SizedBox(width: 4),
                                        Text(
                                          product.barcode,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: muted,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: ink,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      '₹${product.price.toInt()}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: teal,
                                      ),
                                    ),
                                    Text(
                                      ' / ${product.pack}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: muted,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: product.stock <= 5 ? const Color(0xFFFEF3C7) : mintTint,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Stock: ${product.stock}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: product.stock <= 5 ? amber : teal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (currentBillQty > 0) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: amber, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Already in current bill: $currentBillQty ${product.pack}${currentBillQty > 1 ? 's' : ''} (₹${(product.price * currentBillQty).toInt()})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Quantity to Add',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ink),
                        ),
                        Row(
                          children: [
                            InkWell(
                              onTap: selectedQty > 1
                                  ? () => setModalState(() => selectedQty--)
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: selectedQty > 1 ? mintTint : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: selectedQty > 1 ? mint : Colors.grey.shade300,
                                  ),
                                ),
                                child: Icon(
                                  Icons.remove_rounded,
                                  color: selectedQty > 1 ? teal : Colors.grey,
                                  size: 18,
                                ),
                              ),
                            ),
                            Container(
                              constraints: const BoxConstraints(minWidth: 48),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: line),
                              ),
                              child: Center(
                                child: Text(
                                  '$selectedQty',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: ink,
                                  ),
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => setModalState(() => selectedQty++),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: mintTint,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: mint),
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  color: teal,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [1, 2, 5, 10].map((qtyVal) {
                        final isSelected = selectedQty == qtyVal;
                        return ChoiceChip(
                          label: Text('+$qtyVal'),
                          selected: isSelected,
                          onSelected: (_) => setModalState(() => selectedQty = qtyVal),
                          selectedColor: mintTint,
                          backgroundColor: canvas,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? teal : ink,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: isSelected ? mint : line),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: line, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Item Price',
                          style: TextStyle(fontSize: 13, color: muted, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '₹${lineTotal.toInt()}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: teal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (onEdit != null) ...[
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: teal,
                              side: const BorderSide(color: line, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Edit', style: TextStyle(fontWeight: FontWeight.w700)),
                            onPressed: () {
                              Navigator.pop(ctx);
                              onEdit(product);
                            },
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Vanik3DButton(
                            variant: VanikButtonVariant.green,
                            height: 48,
                            fontSize: 14,
                            icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 18),
                            label: currentBillQty > 0
                                ? 'Update Bill (+₹${lineTotal.toInt()})'
                                : 'Add to Bill • ₹${lineTotal.toInt()}',
                            onPressed: () {
                              Navigator.pop(ctx);
                              onAdd(product, selectedQty);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

Future<void> showAddNewBarcodeProductModal(
  BuildContext context, {
  required String barcode,
  String initialName = '',
  String initialUnit = 'piece',
  String initialImage = '',
  bool isMasterFound = false,
  required void Function(ProductItem newItem) onAdded,
}) async {
  final nameController = TextEditingController(text: initialName);
  final priceController = TextEditingController();
  final stockController = TextEditingController(text: '10');
  final imageController = TextEditingController(text: initialImage);
  String pack = ['piece', 'kg', 'packet', 'litre'].contains(initialUnit.toLowerCase())
      ? initialUnit.toLowerCase()
      : 'piece';

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            top: false,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(color: const Color(0xFFCCE3DF), borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () => _showImagePickerSheet(ctx, controller: imageController, setModalState: setModalState),
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: line, width: 1.5),
                                  ),
                                  child: _buildImagePreviewWidget(imageController.text, size: 64),
                                ),
                              ),
                              Positioned(
                                right: 2,
                                bottom: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(color: teal, shape: BoxShape.circle),
                                  child: const Icon(Icons.camera_alt_rounded, size: 10, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isMasterFound ? 'Product Recognized!' : 'New Barcode Scanned',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ink),
                              ),
                              Text(
                                barcode,
                                style: const TextStyle(fontSize: 12, color: muted, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  InkWell(
                                    onTap: () => _pickImageForModal(
                                      source: ImageSource.camera,
                                      controller: imageController,
                                      setModalState: setModalState,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: mintTint,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: mint),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.camera_alt_rounded, size: 13, color: teal),
                                          SizedBox(width: 4),
                                          Text('Take Photo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: teal)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () => _pickImageForModal(
                                      source: ImageSource.gallery,
                                      controller: imageController,
                                      setModalState: setModalState,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: canvas,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: line),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.photo_library_outlined, size: 13, color: muted),
                                          SizedBox(width: 4),
                                          Text('Gallery', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ink)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (isMasterFound) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(color: const Color(0xFF86EFAC)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified_rounded, size: 13, color: Color(0xFF16A34A)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Master FMCG Catalog Match',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: muted),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: canvas,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: line),
                      ),
                      child: TextField(
                        controller: nameController,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ink),
                        decoration: const InputDecoration(
                          hintText: 'Product Name (e.g. Parle-G Gold)',
                          hintStyle: TextStyle(fontSize: 13, color: muted),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: canvas,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: line),
                            ),
                            child: TextField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ink),
                              decoration: const InputDecoration(
                                hintText: 'Price (₹)',
                                hintStyle: TextStyle(fontSize: 13, color: muted),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: canvas,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: line),
                            ),
                            child: TextField(
                              controller: stockController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ink),
                              decoration: const InputDecoration(
                                hintText: 'Initial Stock',
                                hintStyle: TextStyle(fontSize: 13, color: muted),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['piece', 'kg', 'packet', 'litre'].map((p) {
                          final selected = pack == p;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(p),
                              selected: selected,
                              selectedColor: mintTint,
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: selected ? teal : muted,
                              ),
                              onSelected: (_) => setModalState(() => pack = p),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: canvas,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: line),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.image_outlined, size: 18, color: muted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: imageController,
                              onChanged: (_) => setModalState(() {}),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ink),
                              decoration: const InputDecoration(
                                hintText: 'Product Image URL (optional)',
                                hintStyle: TextStyle(fontSize: 12, color: muted),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (imageController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                imageController.clear();
                                setModalState(() {});
                              },
                              child: const Icon(Icons.clear_rounded, size: 18, color: muted),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _imagePresetChip(
                            label: 'Biscuits',
                            url: 'https://images.openfoodfacts.org/images/products/890/171/910/1018/front_en.3.400.jpg',
                            current: imageController.text,
                            onSelect: (url) {
                              imageController.text = url;
                              setModalState(() {});
                            },
                          ),
                          _imagePresetChip(
                            label: 'Snacks',
                            url: 'https://images.openfoodfacts.org/images/products/890/908/100/7156/front_en.1.400.jpg',
                            current: imageController.text,
                            onSelect: (url) {
                              imageController.text = url;
                              setModalState(() {});
                            },
                          ),
                          _imagePresetChip(
                            label: 'Noodles',
                            url: 'https://images.openfoodfacts.org/images/products/890/105/801/0218/front_en.4.400.jpg',
                            current: imageController.text,
                            onSelect: (url) {
                              imageController.text = url;
                              setModalState(() {});
                            },
                          ),
                          _imagePresetChip(
                            label: 'Drink',
                            url: 'https://images.openfoodfacts.org/images/products/890/103/086/5070/front_en.3.400.jpg',
                            current: imageController.text,
                            onSelect: (url) {
                              imageController.text = url;
                              setModalState(() {});
                            },
                          ),
                          _imagePresetChip(
                            label: 'Grains',
                            url: 'https://images.openfoodfacts.org/images/products/890/404/390/1107/front_en.3.400.jpg',
                            current: imageController.text,
                            onSelect: (url) {
                              imageController.text = url;
                              setModalState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Vanik3DButton(
                      variant: VanikButtonVariant.green,
                      height: 48,
                      label: 'Save and Add to Bill',
                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 18, color: Colors.white),
                      onPressed: () {
                        final name = nameController.text.trim();
                        final price = double.tryParse(priceController.text) ?? 10.0;
                        final stock = int.tryParse(stockController.text) ?? 10;
                        if (name.isEmpty) return;

                        final newItem = ProductItem(
                          name: name,
                          pack: pack,
                          price: price,
                          stock: stock,
                          barcode: barcode,
                          imageUrl: imageController.text.trim(),
                          profit: (price * 0.2).roundToDouble(),
                        );
                        if (newItem.barcode.isNotEmpty) {
                          MasterCatalogService.saveToMaster(MasterProductItem(
                            barcode: newItem.barcode,
                            name: newItem.name,
                            image: newItem.imageUrl,
                            unit: newItem.pack,
                          ));
                        }
                        Navigator.pop(ctx);
                        onAdded(newItem);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

Widget _imagePresetChip({
  required String label,
  required String url,
  required String current,
  required ValueChanged<String> onSelect,
}) {
  final isSelected = current == url;
  return Padding(
    padding: const EdgeInsets.only(right: 6),
    child: InkWell(
      onTap: () => onSelect(isSelected ? '' : url),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? mintTint : canvas,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? teal : line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                url,
                width: 16,
                height: 16,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 14, color: muted),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? teal : ink,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _showPaymentModal(
  BuildContext context,
  double total,
  void Function(bool isUdhaar, String? customerName, String? phone) onDone,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      bool isUdhaar = false;
      final nameCtrl = TextEditingController();
      final phoneCtrl = TextEditingController();
      List<CustomerModel> existingCustomers = [];
      try {
        existingCustomers = Provider.of<CustomerProvider>(context, listen: false).customers;
      } catch (_) {}

      return StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SafeArea(
            top: false,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(color: const Color(0xFFCCE3DF), borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Complete Bill', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ink)),
                      Text(
                        '₹${total.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: teal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!isUdhaar) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Vanik3DButton(
                            variant: VanikButtonVariant.green,
                            height: 48,
                            label: 'Cash Paid',
                            icon: const Icon(Icons.money_rounded, size: 18, color: Colors.white),
                            onPressed: () {
                              Navigator.pop(ctx);
                              onDone(false, null, null);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Vanik3DButton(
                            variant: VanikButtonVariant.green,
                            height: 48,
                            label: 'UPI Paid',
                            icon: const Icon(Icons.qr_code_rounded, size: 18, color: Colors.white),
                            onPressed: () {
                              Navigator.pop(ctx);
                              onDone(false, null, null);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Vanik3DButton(
                      variant: VanikButtonVariant.beige,
                      height: 46,
                      label: 'Mark as Udhaar (Credit)',
                      icon: const Icon(Icons.assignment_late_outlined, size: 16, color: teal),
                      onPressed: () => setModalState(() => isUdhaar = true),
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Customer Info for Udhaar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: ink)),
                        InkWell(
                          onTap: () => setModalState(() => isUdhaar = false),
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Row(
                              children: [
                                Icon(Icons.arrow_back, size: 13, color: teal),
                                SizedBox(width: 3),
                                Text('Cash/UPI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: teal)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (existingCustomers.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text('Quick Select Existing Customer:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: muted)),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: existingCustomers.map((c) {
                            final isSelected = nameCtrl.text.trim().toLowerCase() == c.name.toLowerCase();
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(c.name),
                                selected: isSelected,
                                selectedColor: mintTint,
                                labelStyle: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? teal : ink,
                                ),
                                onSelected: (_) {
                                  setModalState(() {
                                    nameCtrl.text = c.name;
                                    phoneCtrl.text = c.mobile;
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: canvas,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: line),
                      ),
                      child: TextField(
                        controller: nameCtrl,
                        autofocus: true,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ink),
                        decoration: const InputDecoration(
                          hintText: 'Customer Name (e.g. Verma Ji)',
                          hintStyle: TextStyle(fontSize: 13, color: muted),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: canvas,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: line),
                      ),
                      child: TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ink),
                        decoration: const InputDecoration(
                          hintText: 'Phone Number (optional, for WhatsApp)',
                          hintStyle: TextStyle(fontSize: 13, color: muted),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Vanik3DButton(
                            variant: VanikButtonVariant.beige,
                            height: 48,
                            label: 'Back',
                            onPressed: () => setModalState(() => isUdhaar = false),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: Vanik3DButton(
                            variant: VanikButtonVariant.green,
                            height: 48,
                            icon: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                            label: 'Save Udhaar',
                            onPressed: () {
                              final name = nameCtrl.text.trim().isEmpty ? 'Customer' : nameCtrl.text.trim();
                              final phone = phoneCtrl.text.trim();
                              Navigator.pop(ctx);
                              onDone(true, name, phone.isNotEmpty ? phone : null);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

