import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';

// Brand colors for tactile buttons
const _teal = Color(0xFF0F766E);
const _darkTeal = Color(0xFF084B45);
const _brightTeal = Color(0xFF17C3B2);
const _mintTint = Color(0xFFE5F8F4);
const _mintTintShadow = Color(0xFFBFEDE3);
const _amber = Color(0xFFD97706);
const _amberShadow = Color(0xFF9A5205);

enum VanikButtonVariant {
  green, // Primary ShopMint Teal Mint with gloss
  beige, // Secondary Soft Mint Tint
  amber, // Warm Accent
}

class Vanik3DButton extends StatefulWidget {
  const Vanik3DButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.variant = VanikButtonVariant.green,
    this.height = 46,
    this.width,
    this.fontSize = 14,
    this.textColor,
    this.borderRadius = 12,
  });

  final VoidCallback onPressed;
  final String label;
  final Widget? icon;
  final VanikButtonVariant variant;
  final double height;
  final double? width;
  final double fontSize;
  final Color? textColor;
  final double borderRadius;

  @override
  State<Vanik3DButton> createState() => _Vanik3DButtonState();
}

class _Vanik3DButtonState extends State<Vanik3DButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final (gradient, faceColor, shadowColor, borderColor, defaultTextColor) = switch (widget.variant) {
      VanikButtonVariant.green => (
        const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_brightTeal, _teal],
        ),
        _teal,
        _darkTeal,
        const Color(0xFF084B45),
        Colors.white,
      ),
      VanikButtonVariant.amber => (
        const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF59E0B), _amber],
        ),
        _amber,
        _amberShadow,
        const Color(0xFF9A5205),
        Colors.white,
      ),
      VanikButtonVariant.beige => (
        null,
        _mintTint,
        _mintTintShadow,
        const Color(0xFFCCEFE8),
        _teal,
      ),
    };

    final effectiveTextColor = widget.textColor ?? defaultTextColor;
    const double bevelDepth = 3.5;
    final double currentOffset = _isPressed ? bevelDepth : 0.0;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          children: [
            // Bottom 3D bevel / base layer
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              top: bevelDepth,
              child: Container(
                decoration: BoxDecoration(
                  color: shadowColor,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                ),
              ),
            ),
            // Top face layer with gradient and gloss that depresses on tap
            AnimatedPositioned(
              duration: const Duration(milliseconds: 50),
              curve: Curves.easeOut,
              left: 0,
              right: 0,
              top: currentOffset,
              bottom: bevelDepth - currentOffset,
              child: Container(
                decoration: BoxDecoration(
                  gradient: gradient,
                  color: gradient == null ? faceColor : null,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(color: borderColor, width: 1),
                  boxShadow: const [
                    BoxShadow(color: Color(0x10000000), blurRadius: 2, offset: Offset(0, 1)),
                  ],
                ),
                child: Stack(
                  children: [
                    if (gradient != null)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(widget.borderRadius),
                          child: CustomPaint(painter: _GlossPainter()),
                        ),
                      ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.icon != null) ...[
                                widget.icon!,
                                if (widget.label.isNotEmpty) const SizedBox(width: 8),
                              ],
                              if (widget.label.isNotEmpty)
                                Text(
                                  widget.label,
                                  style: TextStyle(
                                    fontSize: widget.fontSize,
                                    fontWeight: FontWeight.w800,
                                    color: effectiveTextColor,
                                    letterSpacing: 0.3,
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
            ),
          ],
        ),
      ),
    );
  }
}

class App3dButton extends StatefulWidget {
  const App3dButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 50,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final IconData? icon;
  final bool isLoading;

  factory App3dButton.mint({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    double height = 50,
    IconData? icon,
    IconData? trailingIcon,
    bool isLoading = false,
  }) {
    return App3dButton(
      key: key,
      label: label,
      onPressed: onPressed,
      height: height,
      icon: icon ?? trailingIcon,
      isLoading: isLoading,
    );
  }

  @override
  State<App3dButton> createState() => _App3dButtonState();
}

class _App3dButtonState extends State<App3dButton> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null && !widget.isLoading;

    return GestureDetector(
      onTapDown: (_) {
        if (isEnabled) {
          setState(() => pressed = true);
          HapticFeedback.lightImpact();
        }
      },
      onTapCancel: () {
        if (pressed) setState(() => pressed = false);
      },
      onTapUp: (_) {
        if (isEnabled) {
          setState(() => pressed = false);
          widget.onPressed!();
        }
      },
      child: Container(
        height: widget.height + 4,
        decoration: BoxDecoration(
          color: isEnabled ? AppColors.deepTeal : const Color(0xFF4B5563),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1C000000),
              blurRadius: 4,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          transform: Matrix4.translationValues(0, pressed ? 3 : 0, 0),
          margin: EdgeInsets.only(bottom: pressed ? 1 : 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isEnabled
                  ? [AppColors.brightTeal, AppColors.teal]
                  : [const Color(0xFF9CA3AF), const Color(0xFF6B7280)],
            ),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Stack(
            children: [
              if (isEnabled)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: CustomPaint(painter: _GlossPainter()),
                  ),
                ),
              Center(
                child: widget.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, color: Colors.white, size: 19),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              widget.label,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .45,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlossPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * .42)
      ..quadraticBezierTo(size.width * .5, size.height * .68, 0, size.height * .3)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x5FFFFFFF), Color(0x12FFFFFF)],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
