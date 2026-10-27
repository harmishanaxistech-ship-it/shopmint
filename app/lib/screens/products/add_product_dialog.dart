import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/storage/master_catalog_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/image_picker_helper.dart';
import '../../models/product_model.dart';
import '../../providers/billing_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/app_3d_button.dart';
import '../../widgets/product_image_view.dart';
import '../billing/barcode_scanner_modal.dart';

class AddProductDialog extends StatefulWidget {
  final String? initialBarcode;
  final String? initialName;
  final String? initialUnit;
  final String? initialImageUrl;
  final double? initialSellingPrice;
  final double? initialCostPrice;
  final double? initialStock;
  final bool isFromBilling;

  const AddProductDialog({
    super.key,
    this.initialBarcode,
    this.initialName,
    this.initialUnit,
    this.initialImageUrl,
    this.initialSellingPrice,
    this.initialCostPrice,
    this.initialStock,
    this.isFromBilling = false,
  });

  static Future<ProductModel?> show(
    BuildContext context, {
    String? initialBarcode,
    String? initialName,
    String? initialUnit,
    String? initialImageUrl,
    double? initialSellingPrice,
    double? initialCostPrice,
    double? initialStock,
    bool isFromBilling = false,
  }) {
    return showDialog<ProductModel?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddProductDialog(
        initialBarcode: initialBarcode,
        initialName: initialName,
        initialUnit: initialUnit,
        initialImageUrl: initialImageUrl,
        initialSellingPrice: initialSellingPrice,
        initialCostPrice: initialCostPrice,
        initialStock: initialStock,
        isFromBilling: isFromBilling,
      ),
    );
  }

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  late final TextEditingController _barcodeCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _sellingPriceCtrl;
  late final TextEditingController _costPriceCtrl;
  late final TextEditingController _stockCtrl;

  late String _selectedUnit;
  String _imageUrl = '';
  bool _isLoose = false;
  bool _isSaving = false;
  String? _errorMessage;

  final List<String> _unitOptions = const [
    'pcs',
    'kg',
    'g',
    'litre',
    'ml',
    'packet',
    'box',
    'bottle',
    'meter',
  ];

  @override
  void initState() {
    super.initState();
    _barcodeCtrl = TextEditingController(text: widget.initialBarcode ?? '');
    _nameCtrl = TextEditingController(text: widget.initialName ?? '');
    _sellingPriceCtrl = TextEditingController(
      text: widget.initialSellingPrice != null && widget.initialSellingPrice! > 0
          ? widget.initialSellingPrice!.toStringAsFixed(0)
          : '',
    );
    _costPriceCtrl = TextEditingController(
      text: widget.initialCostPrice != null && widget.initialCostPrice! > 0
          ? widget.initialCostPrice!.toStringAsFixed(0)
          : '',
    );
    _stockCtrl = TextEditingController(
      text: widget.initialStock != null
          ? widget.initialStock!.toStringAsFixed(0)
          : '10',
    );

    _selectedUnit = _normalizeUnit(widget.initialUnit);
    _imageUrl = widget.initialImageUrl?.trim() ?? '';
  }

  String _normalizeUnit(String? unit) {
    if (unit == null || unit.isEmpty) return 'pcs';
    final lower = unit.toLowerCase().trim();
    if (lower == 'piece' || lower == 'pc') return 'pcs';
    if (lower == 'pack') return 'packet';
    if (_unitOptions.contains(lower)) return lower;
    return 'pcs';
  }

  @override
  void dispose() {
    _barcodeCtrl.dispose();
    _nameCtrl.dispose();
    _sellingPriceCtrl.dispose();
    _costPriceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleScanBarcode() async {
    final scanned = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const BarcodeScannerModal(),
    );
    if (scanned != null && scanned.isNotEmpty && mounted) {
      setState(() {
        _barcodeCtrl.text = scanned.trim();
      });
    }
  }

  Future<void> _handlePickImage() async {
    final photo = await ImagePickerHelper.showImageSourceDialog(context);
    if (photo != null && mounted) {
      setState(() {
        _imageUrl = photo;
      });
    }
  }

  Future<void> _handleSave() async {
    final name = _nameCtrl.text.trim();
    final sellRupees = double.tryParse(_sellingPriceCtrl.text.trim()) ?? 0;
    final costRupees = double.tryParse(_costPriceCtrl.text.trim()) ?? 0;
    final stock = double.tryParse(_stockCtrl.text.trim()) ?? 0;
    final barcode = _barcodeCtrl.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter product name.');
      return;
    }
    if (sellRupees <= 0) {
      setState(() => _errorMessage = 'Selling price must be greater than 0.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final prodProv = Provider.of<ProductProvider>(context, listen: false);
      final success = await prodProv.createProduct(
        name: name,
        barcode: barcode.isNotEmpty ? barcode : null,
        unit: _selectedUnit,
        purchasePrice: CurrencyFormatter.toPaise(costRupees),
        sellingPrice: CurrencyFormatter.toPaise(sellRupees),
        currentStock: stock,
        isLoose: _isLoose || barcode.isEmpty,
        imageUrl: _imageUrl.isNotEmpty ? _imageUrl : null,
      );

      if (!success) {
        if (mounted) {
          setState(() {
            _isSaving = false;
            _errorMessage = prodProv.errorMessage ?? 'Failed to save product. Please try again.';
          });
        }
        return;
      }

      // Also persist to local SQLite master catalog for 0ms offline recognition
      if (barcode.isNotEmpty) {
        await MasterCatalogService.saveToMaster(
          MasterProductItem(
            barcode: barcode,
            name: name,
            image: _imageUrl,
            unit: _selectedUnit,
          ),
        );
      }

      // Retrieve newly created product model
      final createdProduct = prodProv.products.firstWhere(
        (p) => (barcode.isNotEmpty && p.barcode == barcode) || p.name.toLowerCase() == name.toLowerCase(),
        orElse: () => ProductModel(
          id: '',
          name: name,
          barcode: barcode,
          unit: _selectedUnit,
          sellingPrice: CurrencyFormatter.toPaise(sellRupees),
          purchasePrice: CurrencyFormatter.toPaise(costRupees),
          imageUrl: _imageUrl,
          currentStock: stock,
        ),
      );

      if (!mounted) return;

      // If called during billing, automatically add to active bill
      if (widget.isFromBilling) {
        final billProv = Provider.of<BillingProvider>(context, listen: false);
        billProv.addItemFromProduct(createdProduct);
      }

      Navigator.pop(context, createdProduct);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name saved successfully'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'An error occurred: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocaleProvider>(context);
    final isMasterPrefill = (widget.initialName?.isNotEmpty ?? false) ||
        (widget.initialImageUrl?.isNotEmpty ?? false);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: AppRadius.smAll,
                      ),
                      child: Icon(
                        isMasterPrefill ? Icons.auto_awesome : Icons.add_box_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isMasterPrefill ? loc.t('masterItemFound') : loc.t('addNewProduct'),
                        style: AppText.h3,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                      tooltip: loc.t('cancel'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Product Photo Area
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          ProductImageView(
                            imageUrl: _imageUrl,
                            width: 96,
                            height: 96,
                            borderRadius: AppRadius.mdAll,
                            fit: BoxFit.contain,
                            placeholderIcon: Icons.add_a_photo_outlined,
                            iconSize: 34,
                          ),
                          if (_imageUrl.isNotEmpty)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: InkWell(
                                onTap: () => setState(() => _imageUrl = ''),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _handlePickImage,
                            icon: Icon(
                              _imageUrl.isEmpty ? Icons.camera_alt_outlined : Icons.edit_outlined,
                              size: 16,
                            ),
                            label: Text(
                              _imageUrl.isEmpty ? 'Add Photo' : 'Change Photo',
                              style: AppText.caption.copyWith(fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              side: const BorderSide(color: AppColors.border),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Product Type Switcher: Packaged vs Loose
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _isLoose = false;
                          });
                        },
                        borderRadius: AppRadius.mdAll,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: !_isLoose ? AppColors.primaryDark : AppColors.background,
                            borderRadius: AppRadius.mdAll,
                            border: Border.all(
                              color: !_isLoose ? AppColors.primaryDark : AppColors.border,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.qr_code_2,
                                size: 16,
                                color: !_isLoose ? Colors.white : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Packaged (Barcode)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: !_isLoose ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _isLoose = true;
                            _barcodeCtrl.clear();
                            if (_selectedUnit == 'pcs') _selectedUnit = 'kg';
                          });
                        },
                        borderRadius: AppRadius.mdAll,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _isLoose ? AppColors.primaryDark : AppColors.background,
                            borderRadius: AppRadius.mdAll,
                            border: Border.all(
                              color: _isLoose ? AppColors.primaryDark : AppColors.border,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.scale_outlined,
                                size: 16,
                                color: _isLoose ? Colors.white : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Loose Item (Weight)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _isLoose ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Barcode Section (Visible for Packaged items)
                if (!_isLoose) ...[
                  TextField(
                    controller: _barcodeCtrl,
                    decoration: InputDecoration(
                      labelText: 'Barcode',
                      hintText: 'Scan or enter barcode number',
                      prefixIcon: const Icon(Icons.qr_code_2, size: 20, color: AppColors.primary),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                        onPressed: _handleScanBarcode,
                        tooltip: 'Scan Barcode',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: AppRadius.smAll,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: AppColors.primaryDark),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Loose Item: Sold by weight/volume. No barcode required.',
                            style: AppText.caption.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Name Section
                TextField(
                  controller: _nameCtrl,
                  autofocus: widget.initialName == null || widget.initialName!.isEmpty,
                  decoration: InputDecoration(
                    labelText: '${loc.t('itemName')} *',
                    hintText: 'e.g. Parle-G Biscuit 100g',
                  ),
                ),
                const SizedBox(height: 12),

                // Unit Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedUnit,
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                  ),
                  isExpanded: true,
                  items: _unitOptions.map((u) {
                    return DropdownMenuItem(
                      value: u,
                      child: Text(u, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedUnit = val);
                  },
                ),
                const SizedBox(height: 12),

                // Prices Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _sellingPriceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: '${loc.t('sellingPrice')} *',
                          hintText: 'e.g. 50',
                          prefixText: '₹ ',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _costPriceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: loc.t('costPrice'),
                          hintText: 'e.g. 40',
                          prefixText: '₹ ',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Stock Field
                TextField(
                  controller: _stockCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: '${loc.t('qty')} (Opening Stock)',
                    hintText: '10',
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: AppRadius.smAll,
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: AppText.caption.copyWith(color: Colors.red.shade800),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      child: Text(loc.t('cancel')),
                    ),
                    const SizedBox(width: 8),
                    App3dButton.mint(
                      height: 44,
                      onPressed: _isSaving ? null : _handleSave,
                      isLoading: _isSaving,
                      label: widget.isFromBilling
                          ? loc.t('saveAndAddToBill')
                          : loc.t('save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
