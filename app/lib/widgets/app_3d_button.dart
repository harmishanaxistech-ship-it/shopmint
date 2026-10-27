import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';

/// Tactile 3D Button with glass gloss sheen and mechanical push-down interaction.
class App3dButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String? label;
  final Widget? child;
  final IconData? icon;
  final IconData? trailingIcon;
  final double height;
  final double? width;
  final Color color;
  final Color endColor;
  final Color depthColor;
  final Color textColor;
  final double borderRadius;
  final double depth;
  final bool showGloss;
  final bool isLoading;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;

  const App3dButton({
    super.key,
    this.onPressed,
    this.label,
    this.child,
    this.icon,
    this.trailingIcon,
    this.height = 48.0,
    this.width,
    this.color = const Color(0xFF17C3B2),
    this.endColor = AppColors.primaryDark,
    this.depthColor = const Color(0xFF084B45),
    this.textColor = Colors.white,
    this.borderRadius = 12.0,
    this.depth = 4.5,
    this.showGloss = true,
    this.isLoading = false,
    this.textStyle,
    this.padding,
  });

  /// Factory constructor for ShopMint Teal Mint theme (App brand colors)
  factory App3dButton.mint({
    Key? key,
    VoidCallback? onPressed,
    String? label,
    Widget? child,
    IconData? icon,
    IconData? trailingIcon,
    double height = 48.0,
    double? width,
    double borderRadius = 12.0,
    double depth = 4.5,
    bool isLoading = false,
    TextStyle? textStyle,
  }) {
    return App3dButton(
      key: key,
      onPressed: onPressed,
      label: label,
      icon: icon,
      trailingIcon: trailingIcon,
      height: height,
      width: width,
      color: const Color(0xFF17C3B2),
      endColor: AppColors.primaryDark,
      depthColor: const Color(0xFF084B45),
      textColor: Colors.white,
      borderRadius: borderRadius,
      depth: depth,
      showGloss: true,
      isLoading: isLoading,
      textStyle: textStyle,
      child: child,
    );
  }

  /// Factory constructor for ShopMint bright Teal theme
  factory App3dButton.teal({
    Key? key,
    VoidCallback? onPressed,
    String? label,
    Widget? child,
    IconData? icon,
    IconData? trailingIcon,
    double height = 48.0,
    double? width,
    double borderRadius = 12.0,
    double depth = 4.5,
    bool isLoading = false,
    TextStyle? textStyle,
  }) {
    return App3dButton(
      key: key,
      onPressed: onPressed,
      label: label,
      icon: icon,
      trailingIcon: trailingIcon,
      height: height,
      width: width,
      color: const Color(0xFF2DD4BF),
      endColor: AppColors.primary,
      depthColor: AppColors.primaryDark,
      textColor: Colors.white,
      borderRadius: borderRadius,
      depth: depth,
      showGloss: true,
      isLoading: isLoading,
      textStyle: textStyle,
      child: child,
    );
  }

  /// Factory constructor for Deep Teal contrast
  factory App3dButton.darkTeal({
    Key? key,
    VoidCallback? onPressed,
    String? label,
    Widget? child,
    IconData? icon,
    IconData? trailingIcon,
    double height = 48.0,
    double? width,
    double borderRadius = 12.0,
    double depth = 4.5,
    bool isLoading = false,
    TextStyle? textStyle,
  }) {
    return App3dButton(
      key: key,
      onPressed: onPressed,
      label: label,
      icon: icon,
      trailingIcon: trailingIcon,
      height: height,
      width: width,
      color: AppColors.primary,
      endColor: AppColors.primaryDark,
      depthColor: const Color(0xFF05332F),
      textColor: Colors.white,
      borderRadius: borderRadius,
      depth: depth,
      showGloss: true,
      isLoading: isLoading,
      textStyle: textStyle,
      child: child,
    );
  }

  @override
  State<App3dButton> createState() => _App3dButtonState();
}

class _App3dButtonState extends State<App3dButton> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed == null || widget.isLoading) return;
    setState(() => _isPressed = true);
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed == null || widget.isLoading) return;
    setState(() => _isPressed = false);
    widget.onPressed?.call();
  }

  void _onTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null && !widget.isLoading;
    final double depth = widget.depth;
    final double topOffset = _isPressed ? depth - 1.0 : 0.0;
    final double bottomMargin = _isPressed ? 1.0 : depth;

    final Color faceColor = isEnabled ? widget.color : const Color(0xFF9CA3AF);
    final Color endFaceColor = isEnabled ? widget.endColor : const Color(0xFF6B7280);
    final Color baseDepthColor = isEnabled ? widget.depthColor : const Color(0xFF4B5563);

    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: GestureDetector(
        onTapDown: isEnabled ? _onTapDown : null,
        onTapUp: isEnabled ? _onTapUp : null,
        onTapCancel: isEnabled ? _onTapCancel : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: baseDepthColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(28),
                offset: const Offset(0, 3),
                blurRadius: 4,
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 50),
            margin: EdgeInsets.only(top: topOffset, bottom: bottomMargin),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [faceColor, endFaceColor],
              ),
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: Stack(
                children: [
                  // Specular gloss reflection overlay (as seen in reference image)
                  if (widget.showGloss && isEnabled)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _GlossSheenPainter(),
                      ),
                    ),

                  // Button content (Text, Icons, or custom child)
                  Center(
                    child: Padding(
                      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 14),
                      child: widget.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : widget.child ??
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if (widget.icon != null) ...[
                                    Icon(widget.icon, color: widget.textColor, size: 20),
                                    const SizedBox(width: 8),
                                  ],
                                  Text(
                                    widget.label ?? '',
                                    style: widget.textStyle ??
                                        TextStyle(
                                          color: widget.textColor,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.6,
                                        ),
                                  ),
                                  if (widget.trailingIcon != null) ...[
                                    const SizedBox(width: 8),
                                    Icon(widget.trailingIcon, color: widget.textColor, size: 20),
                                  ],
                                ],
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter that renders the sleek curved glass gloss reflection
class _GlossSheenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withAlpha(95),
          Colors.white.withAlpha(18),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.65))
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    // Gloss right endpoint
    path.lineTo(size.width, size.height * 0.42);
    // Gentle curved arch across the middle
    path.quadraticBezierTo(
      size.width * 0.48,
      size.height * 0.70,
      0,
      size.height * 0.52,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
