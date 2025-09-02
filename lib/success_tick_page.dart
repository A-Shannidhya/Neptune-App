import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

/// Modern success tick animation page.
/// Shows expanding gradient burst, scaling glass card with animated stroke-drawn check mark.
class SuccessTickPage extends StatefulWidget {
  final String amount;
  final String recipient;
  const SuccessTickPage({super.key, required this.amount, required this.recipient});
  @override
  State<SuccessTickPage> createState() => _SuccessTickPageState();
}

class _SuccessTickPageState extends State<SuccessTickPage> with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  late final Animation<double> _burst = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic));
  late final Animation<double> _scaleCard = CurvedAnimation(parent: _controller, curve: const Interval(0.15, 0.55, curve: OvershootCurve()));
  late final Animation<double> _checkStroke = CurvedAnimation(parent: _controller, curve: const Interval(0.40, 0.85, curve: Curves.easeInOutCubic));
  late final Animation<double> _fadeText = CurvedAnimation(parent: _controller, curve: const Interval(0.55, 1.0, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _BurstPainter(progress: _burst.value, scheme: scheme),
                ),
              ),
              Center(
                child: Transform.scale(
                  scale: _scaleCard.value,
                  child: Opacity(
                    opacity: _scaleCard.value.clamp(0, 1),
                    child: _GlassCard(
                      child: SizedBox(
                        width: 220,
                        height: 220,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 140,
                              height: 140,
                              child: CustomPaint(
                                painter: _CheckPainter(progress: _checkStroke.value, color: scheme.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 80),
                  child: Opacity(
                    opacity: _fadeText.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Transfer Successful', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        Text('₹${widget.amount} sent to ${widget.recipient}', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                        const SizedBox(height: 28),
                        FilledButton.icon(
                          onPressed: () => Navigator.of(context).maybePop(true),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Done'),
                        )
                      ],
                    ),
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}

class OvershootCurve extends Curve {
  final double intensity; // higher => bigger overshoot
  const OvershootCurve({this.intensity = 1.4});
  @override
  double transform(double t) {
    t -= 1.0;
    return t * t * ((intensity + 1) * t + intensity) + 1;
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: scheme.primary.withValues(alpha: .25), width: 1.2),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.surfaceContainerHigh.withValues(alpha: .55),
                scheme.surfaceContainerHighest.withValues(alpha: .35),
              ],
            ),
            boxShadow: [
              BoxShadow(color: scheme.primary.withValues(alpha: .20), blurRadius: 32, spreadRadius: -8, offset: const Offset(0, 12)),
              BoxShadow(color: scheme.primary.withValues(alpha: .10), blurRadius: 8, spreadRadius: -2, offset: const Offset(0, 2)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  final double progress;
  final ColorScheme scheme;
  _BurstPainter({required this.progress, required this.scheme});
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = size.shortestSide * .9;
    final layers = 5;
    for (var i = 0; i < layers; i++) {
      final layerT = (progress - i * 0.10).clamp(0.0, 1.0);
      if (layerT <= 0) continue;
      final r = layerT * maxR * (0.4 + i * 0.14);
      final opacity = (1 - layerT).clamp(0.0, 1.0) * (0.35 - i * 0.05);
      final paint = Paint()
        ..shader = RadialGradient(colors: [
          scheme.primary.withValues(alpha: opacity),
          scheme.primary.withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: center, radius: r));
      canvas.drawCircle(center, r, paint);
    }

    // Radial small star sparks
    final sparkCount = 22;
    final sparkPaint = Paint()..strokeCap = StrokeCap.round;
    for (var i = 0; i < sparkCount; i++) {
      final seed = i / sparkCount;
      final angle = seed * math.pi * 2;
      final baseR = maxR * 0.12;
      final extend = Curves.easeOut.transform(progress) * maxR * 0.28;
      final start = center + Offset(math.cos(angle), math.sin(angle)) * baseR;
      final end = center + Offset(math.cos(angle), math.sin(angle)) * (baseR + extend);
      sparkPaint
        ..color = scheme.secondary.withValues(alpha: (1 - progress) * 0.55)
        ..strokeWidth = 2.0 * (1 - progress);
      canvas.drawLine(start, end, sparkPaint);
    }
  }
  @override
  bool shouldRepaint(covariant _BurstPainter old) => old.progress != progress || old.scheme != scheme;
}

class _CheckPainter extends CustomPainter {
  final double progress; // 0..1
  final Color color;
  _CheckPainter({required this.progress, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(w * 0.18, h * 0.52);
    path.lineTo(w * 0.42, h * 0.74);
    path.lineTo(w * 0.80, h * 0.30);
    final metrics = path.computeMetrics().toList();
    final totalLength = metrics.fold<double>(0, (p, m) => p + m.length);
    final current = totalLength * progress;
    final drawPath = Path();
    double remaining = current;
    for (final metric in metrics) {
      if (remaining <= 0) break;
      final extract = metric.extractPath(0, math.min(metric.length, remaining));
      drawPath.addPath(extract, Offset.zero);
      remaining -= metric.length;
    }
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(colors: [color, color.withValues(alpha: .6)]).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(drawPath, strokePaint);

    // Soft outer glow
    canvas.drawPath(
      drawPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color.withValues(alpha: .15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
  }

  @override
  bool shouldRepaint(covariant _CheckPainter old) => old.progress != progress || old.color != color;
}
