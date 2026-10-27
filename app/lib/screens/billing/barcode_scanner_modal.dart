import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/storage/storage_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

class BarcodeScannerModal extends StatefulWidget {
  const BarcodeScannerModal({super.key});

  @override
  State<BarcodeScannerModal> createState() => _BarcodeScannerModalState();
}

class _BarcodeScannerModalState extends State<BarcodeScannerModal> {
  late final MobileScannerController _cameraController;
  final _manualCodeController = TextEditingController();
  final StorageService _storage = StorageService();

  CameraFacing _currentFacing = CameraFacing.back;
  bool _isScanned = false;
  bool _isTorchOn = false;

  Timer? _autoZoomTimer;
  double _zoomScale = 0.0;
  double _baseZoomScale = 0.0;
  bool _isAutoZoomTriggered = false;

  bool _isContinuous = false;
  final List<String> _scannedCodes = [];
  String? _lastScannedCode;
  DateTime _lastScannedTime = DateTime.now().subtract(const Duration(seconds: 10));
  String? _recentFeedback;

  static const List<BarcodeFormat> _retailFormats = [
    BarcodeFormat.ean13,
    BarcodeFormat.ean8,
    BarcodeFormat.upcA,
    BarcodeFormat.upcE,
    BarcodeFormat.code128,
    BarcodeFormat.code39,
    BarcodeFormat.code93,
    BarcodeFormat.itf14,
    BarcodeFormat.qrCode,
    BarcodeFormat.dataMatrix,
  ];

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController(
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.noDuplicates,
      cameraResolution: const Size(1920, 1080),
      autoZoom: true,
      formats: _retailFormats,
    );
    _loadCameraPreference();
    _startAutoZoomTimer();
  }

  void _startAutoZoomTimer() {
    _autoZoomTimer?.cancel();
    // If no barcode is detected after 2.4 seconds, smoothly zoom in to 2x for small barcodes
    _autoZoomTimer = Timer(const Duration(milliseconds: 2400), () async {
      if (!mounted || _isScanned || _zoomScale > 0.15) return;
      try {
        await _cameraController.setZoomScale(0.35);
        if (mounted) {
          setState(() {
            _zoomScale = 0.35;
            _isAutoZoomTriggered = true;
          });
        }
      } catch (_) {}
    });
  }

  Future<void> _loadCameraPreference() async {
    final pref = await _storage.getPreferredCamera();
    if (pref == 'front' && mounted) {
      await _toggleCamera();
    }
  }

  @override
  void dispose() {
    _autoZoomTimer?.cancel();
    _cameraController.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  Future<void> _toggleCamera() async {
    try {
      await _cameraController.switchCamera();
      if (!mounted) return;
      setState(() {
        _currentFacing = _currentFacing == CameraFacing.back ? CameraFacing.front : CameraFacing.back;
        if (_currentFacing == CameraFacing.front) {
          _isTorchOn = false;
        }
        _zoomScale = 0.0;
        _isAutoZoomTriggered = false;
      });
      _startAutoZoomTimer();
      await _storage.savePreferredCamera(_currentFacing == CameraFacing.back ? 'back' : 'front');
    } catch (_) {}
  }

  Future<void> _setZoom(double zoom) async {
    _autoZoomTimer?.cancel();
    final clamped = zoom.clamp(0.0, 1.0);
    try {
      await _cameraController.setZoomScale(clamped);
      if (mounted) {
        setState(() {
          _zoomScale = clamped;
          _isAutoZoomTriggered = false;
        });
      }
    } catch (_) {}
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final val = barcode.rawValue?.trim();
      if (val != null && val.length >= 3) {
        if (!_isContinuous) {
          _isScanned = true;
          _autoZoomTimer?.cancel();
          HapticFeedback.mediumImpact();
          Navigator.pop(context, val);
          break;
        } else {
          // Continuous multi-item scanning with debounce
          final now = DateTime.now();
          if (_lastScannedCode == val && now.difference(_lastScannedTime).inMilliseconds < 1200) {
            continue;
          }
          _lastScannedCode = val;
          _lastScannedTime = now;
          _scannedCodes.add(val);
          HapticFeedback.heavyImpact();
          setState(() {
            _recentFeedback = 'Item added ($val)';
          });
        }
      }
    }
  }

  Widget _buildZoomChip({
    required String label,
    required double targetZoom,
    required bool isSelected,
  }) {
    return InkWell(
      borderRadius: AppRadius.smAll,
      onTap: () => _setZoom(targetZoom),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: AppRadius.smAll,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.onPrimary : Colors.white,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocaleProvider>(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.86,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(loc.t('scanBarcode'), style: AppText.h3),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.successSoft,
                        borderRadius: AppRadius.smAll,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.center_focus_strong, size: 12, color: AppColors.success),
                          SizedBox(width: 4),
                          Text(
                            'High Accuracy',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.flip_camera_ios_outlined),
                      tooltip: loc.t('switchCamera'),
                      onPressed: _toggleCamera,
                    ),
                    if (_currentFacing == CameraFacing.back)
                      IconButton(
                        icon: Icon(
                          _isTorchOn ? Icons.flash_on : Icons.flash_off_outlined,
                          color: _isTorchOn ? AppColors.primary : null,
                        ),
                        onPressed: () {
                          _cameraController.toggleTorch();
                          setState(() => _isTorchOn = !_isTorchOn);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Scan Mode Selector: Single vs Continuous Rapid Scan
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: AppRadius.smAll,
                    onTap: () => setState(() => _isContinuous = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !_isContinuous ? AppColors.primaryDark : AppColors.background,
                        borderRadius: AppRadius.smAll,
                        border: Border.all(
                          color: !_isContinuous ? AppColors.primaryDark : AppColors.border,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Single Scan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: !_isContinuous ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    borderRadius: AppRadius.smAll,
                    onTap: () => setState(() => _isContinuous = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _isContinuous ? AppColors.primaryDark : AppColors.background,
                        borderRadius: AppRadius.smAll,
                        border: Border.all(
                          color: _isContinuous ? AppColors.primaryDark : AppColors.border,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.playlist_add,
                            size: 16,
                            color: _isContinuous ? Colors.white : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Rapid Multi-Scan',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _isContinuous ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Divider(height: 1),

          // Camera Scanner Box
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double scanWidth = (constraints.maxWidth * 0.76).clamp(240.0, 320.0);
                final double scanHeight = (constraints.maxHeight * 0.38).clamp(150.0, 220.0);
                final scanWindow = Rect.fromCenter(
                  center: Offset(constraints.maxWidth / 2, constraints.maxHeight / 2),
                  width: scanWidth,
                  height: scanHeight,
                );

                return GestureDetector(
                  onScaleStart: (_) {
                    _baseZoomScale = _zoomScale;
                  },
                  onScaleUpdate: (details) {
                    final newZoom = (_baseZoomScale + (details.scale - 1.0) * 0.4).clamp(0.0, 1.0);
                    _setZoom(newZoom);
                  },
                  onDoubleTap: () {
                    if (_zoomScale > 0.15) {
                      _setZoom(0.0);
                    } else {
                      _setZoom(0.35);
                    }
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      MobileScanner(
                        controller: _cameraController,
                        onDetect: _onDetect,
                        tapToFocus: true,
                        scanWindow: scanWindow,
                      ),

                      // High Contrast Corner Reticle Viewfinder
                      _ViewfinderReticle(width: scanWidth, height: scanHeight),

                      // On-screen Camera Switcher
                      Positioned(
                        top: 14,
                        child: Material(
                          color: Colors.black.withAlpha(160),
                          borderRadius: AppRadius.mdAll,
                          child: InkWell(
                            borderRadius: AppRadius.mdAll,
                            onTap: _toggleCamera,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _currentFacing == CameraFacing.back
                                        ? Icons.camera_rear_outlined
                                        : Icons.camera_front_outlined,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _currentFacing == CameraFacing.back
                                        ? loc.t('backCamera')
                                        : loc.t('frontCamera'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.swap_horiz,
                                    color: AppColors.mint,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Auto Zoom Triggered Notification Badge
                      if (_isAutoZoomTriggered)
                        Positioned(
                          top: 52,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryDark.withAlpha(220),
                              borderRadius: AppRadius.smAll,
                              border: Border.all(color: AppColors.mint, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.zoom_in, color: AppColors.mint, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Auto-zoomed for small barcode',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Tap to focus hint
                      Positioned(
                        top: (constraints.maxHeight / 2) + (scanHeight / 2) + 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(140),
                            borderRadius: AppRadius.smAll,
                          ),
                          child: const Text(
                            'Align barcode on red line • Tap to focus',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      // Continuous Mode Multi-Scan Floating Bottom Dock
                      if (_isContinuous && _scannedCodes.isNotEmpty)
                        Positioned(
                          bottom: 56,
                          left: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: AppRadius.mdAll,
                              border: Border.all(color: AppColors.primary),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(40),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.successSoft,
                                    borderRadius: AppRadius.smAll,
                                  ),
                                  child: Text(
                                    '${_scannedCodes.length}',
                                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.success),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('${_scannedCodes.length} Items Scanned', style: AppText.label),
                                      if (_recentFeedback != null)
                                        Text(
                                          _recentFeedback!,
                                          style: AppText.caption.copyWith(color: AppColors.success),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context, _scannedCodes);
                                  },
                                  child: const Text('Add to Bill'),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Zoom Selector Controls
                      Positioned(
                        bottom: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(170),
                            borderRadius: AppRadius.smAll,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildZoomChip(label: '1x', targetZoom: 0.0, isSelected: _zoomScale < 0.15),
                              const SizedBox(width: 4),
                              _buildZoomChip(label: '2x', targetZoom: 0.35, isSelected: _zoomScale >= 0.15 && _zoomScale < 0.55),
                              const SizedBox(width: 4),
                              _buildZoomChip(label: '3x', targetZoom: 0.70, isSelected: _zoomScale >= 0.55),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Manual Barcode Input Fallback
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _manualCodeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: loc.t('manualBarcodeHint'),
                      hintText: '8901058000269',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    final code = _manualCodeController.text.trim();
                    if (code.isNotEmpty) {
                      if (_isContinuous) {
                        setState(() {
                          _scannedCodes.add(code);
                          _recentFeedback = 'Manual code added: $code';
                          _manualCodeController.clear();
                        });
                      } else {
                        Navigator.pop(context, code);
                      }
                    }
                  },
                  child: Text(_isContinuous ? 'Add' : loc.t('ok')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewfinderReticle extends StatelessWidget {
  final double width;
  final double height;

  const _ViewfinderReticle({
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          // Background frame border
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.mint.withAlpha(70), width: 1.5),
              borderRadius: AppRadius.mdAll,
            ),
          ),

          // Red laser alignment line across center
          Center(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.redAccent.withAlpha(200),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),

          // Top Left Corner
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.mint, width: 3.5),
                  left: BorderSide(color: AppColors.mint, width: 3.5),
                ),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(AppRadius.md)),
              ),
            ),
          ),

          // Top Right Corner
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.mint, width: 3.5),
                  right: BorderSide(color: AppColors.mint, width: 3.5),
                ),
                borderRadius: BorderRadius.only(topRight: Radius.circular(AppRadius.md)),
              ),
            ),
          ),

          // Bottom Left Corner
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.mint, width: 3.5),
                  left: BorderSide(color: AppColors.mint, width: 3.5),
                ),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(AppRadius.md)),
              ),
            ),
          ),

          // Bottom Right Corner
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.mint, width: 3.5),
                  right: BorderSide(color: AppColors.mint, width: 3.5),
                ),
                borderRadius: BorderRadius.only(bottomRight: Radius.circular(AppRadius.md)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
