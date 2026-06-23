import 'dart:ui';
import 'package:flutter/material.dart';

/// Rec.709-based saturation matrix.
/// s = 1.0 → identity; s > 1 → more vivid.
List<double> _saturationMatrix(double s) {
  final r = 0.213 * (1 - s);
  final g = 0.715 * (1 - s);
  final b = 0.072 * (1 - s);
  return [
    r + s, g,     b,     0, 0,
    r,     g + s, b,     0, 0,
    r,     g,     b + s, 0, 0,
    0,     0,     0,     1, 0,
  ];
}

/// Apple iOS 26 "Liquid Glass" surface material implemented in pure Flutter.
///
/// Three-ingredient recipe:
///   1. BackdropFilter with composed blur + saturation boost.
///   2. Translucent white tint so the blurred backdrop reads through.
///   3. Specular edge-highlight gradient (thin rim from ~25% to ~5% white).
///
/// Usage — floating capsule (bottom tab bar):
/// ```dart
/// LiquidGlass(
///   borderRadius: BorderRadius.circular(28),
///   child: ...,
/// )
/// ```
///
/// Usage — full-width header bar:
/// ```dart
/// LiquidGlass(
///   borderRadius: BorderRadius.zero,   // no clip needed for a full-width bar
///   addSpecularEdge: true,
///   child: ...,
/// )
/// ```
class LiquidGlass extends StatelessWidget {
  const LiquidGlass({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
    this.blurSigma = 40.0,
    this.saturation = 1.5,
    this.tintOpacity = 0.60,
    this.tintColor = Colors.white,
    this.border,
    this.addSpecularEdge = true,
  });

  /// The widget to render inside the glass surface.
  final Widget child;

  /// Clip and specular-edge shape. Use [BorderRadius.zero] for full-width bars.
  final BorderRadius borderRadius;

  /// Gaussian blur radius (both X and Y). Default 40 — nav/tab tier.
  final double blurSigma;

  /// Saturation multiplier applied on top of the blurred backdrop.
  /// 1.0 = neutral, 1.5 = vivid (Apple's default for Liquid Glass).
  final double saturation;

  /// Opacity of the white tint layer. 0.60 keeps the blur visible while
  /// preserving legibility on light app backgrounds.
  final double tintOpacity;

  /// Tint colour. Override to warm/cool the glass for dark-mode surfaces.
  final Color tintColor;

  /// Optional explicit border drawn around the glass surface.
  /// If null, [LiquidGlass] draws its own specular rim via [addSpecularEdge].
  final Border? border;

  /// When true (default), a thin gradient highlight ring (25% → 5% white)
  /// is painted as a ShaderMask overlay to mimic Apple's refractive rim.
  final bool addSpecularEdge;

  @override
  Widget build(BuildContext context) {
    // --- Layer 1: blur + saturation ---
    Widget glass = BackdropFilter(
      filter: ImageFilter.compose(
        outer: ColorFilter.matrix(_saturationMatrix(saturation)),
        inner: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
      ),
      child: Container(
        // Layer 2: translucent tint
        decoration: BoxDecoration(
          color: tintColor.withValues(alpha: tintOpacity),
          borderRadius: borderRadius,
          border: border,
        ),
        child: child,
      ),
    );

    // --- Layer 3: specular edge highlight ---
    if (addSpecularEdge && border == null) {
      glass = Stack(
        fit: StackFit.passthrough,
        children: [
          glass,
          // Specular rim: gradient stroke from 25% white (top-left) to 5%
          // white (bottom-right), painted as a 1.5px inset ring.
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: borderRadius,
                child: CustomPaint(
                  painter: _SpecularRimPainter(borderRadius: borderRadius),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Clip to shape
    return ClipRRect(
      borderRadius: borderRadius,
      child: glass,
    );
  }
}

/// Paints a 1.5 px inset gradient rim:
/// top-left corner = white 25%, bottom-right corner = white 5%.
class _SpecularRimPainter extends CustomPainter {
  const _SpecularRimPainter({required this.borderRadius});

  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Gradient going from top-left to bottom-right
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: 0.25),
        Colors.white.withValues(alpha: 0.05),
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rrect = borderRadius.toRRect(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_SpecularRimPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius;
}
