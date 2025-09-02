import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'success_tick_page.dart';

/// A 5 second animated transfer experience inspired by the Neptune planet.
/// Shows a stylized planet with animated rings, pulse waves and particles.
/// Pops automatically when animation completes.
class TransferAnimationPage extends StatefulWidget {
  final String amount;
  final String recipient;
  const TransferAnimationPage({super.key, required this.amount, required this.recipient});

  @override
  State<TransferAnimationPage> createState() => _TransferAnimationPageState();
}

class _TransferAnimationPageState extends State<TransferAnimationPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))
    ..addStatusListener((status) async {
      if (status == AnimationStatus.completed && mounted) {
        // Navigate to success tick animation page
        final success = await Navigator.of(context).push<bool>(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => SuccessTickPage(amount: widget.amount, recipient: widget.recipient),
            transitionsBuilder: (ctx, anim, sec, child) {
              final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
              return FadeTransition(opacity: curved, child: child);
            },
          ),
        );
        if (mounted) Navigator.of(context).pop(success == true);
      }
    });

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
      body: Stack(
        children: [
          Positioned.fill(child: _AnimatedBackdrop(progress: _controller)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  const Spacer(),
                  SizedBox(
                    height: 260,
                    width: 260,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        return CustomPaint(
                          painter: _NeptunePainter(progress: _controller.value, scheme: scheme),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final pct = (_controller.value * 100).clamp(0, 100).toStringAsFixed(0);
                      return Column(
                        children: [
                          Text('Transferring', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text('₹${widget.amount} to ${widget.recipient}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                          const SizedBox(height: 18),
                          _ProgressBar(value: _controller.value),
                          const SizedBox(height: 12),
                          Text('$pct%', style: Theme.of(context).textTheme.labelLarge?.copyWith(letterSpacing: 1.2)),
                        ],
                      );
                    },
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedBackdrop extends StatelessWidget {
  final Animation<double> progress;
  const _AnimatedBackdrop({required this.progress});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: progress,
      builder: (context, _) {
        final t = progress.value;
        return CustomPaint(
          painter: _BackdropPainter(t: t, scheme: scheme),
        );
      },
    );
  }
}

class _BackdropPainter extends CustomPainter {
  final double t;
  final ColorScheme scheme;
  _BackdropPainter({required this.t, required this.scheme});
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * .7;
    // Gradient space glow
    final rect = Rect.fromCircle(center: center, radius: radius);
    final glow = RadialGradient(
      colors: [
        scheme.primary.withValues(alpha: .08 + .04 * math.sin(t * math.pi)),
        scheme.surface,
      ],
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = glow.createShader(rect),
    );

    // Floating faint particles
    final particlePaint = Paint()..color = scheme.primary.withValues(alpha: .12);
    final particleCount = 42;
    for (var i = 0; i < particleCount; i++) {
      final seed = i / particleCount;
      final angle = (seed * math.pi * 2) + (t * 2.2); // slow rotation
      final orbitR = (radius * .15) + (math.sin((t * 4) + i) + 1) * (radius * .25 * seed);
      final px = center.dx + math.cos(angle) * orbitR;
      final py = center.dy + math.sin(angle) * orbitR;
      final pr = 1.5 + 2 * (math.sin(t * 6 + i) + 1) * 0.25;
      canvas.drawCircle(Offset(px, py), pr, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter oldDelegate) => oldDelegate.t != t || oldDelegate.scheme != scheme;
}

class _NeptunePainter extends CustomPainter {
  final double progress; // 0..1
  final ColorScheme scheme;
  _NeptunePainter({required this.progress, required this.scheme});
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final planetR = size.shortestSide * .33;

    // Planet body with layered radial gradients
    final planetRect = Rect.fromCircle(center: center, radius: planetR);
    final grad1 = RadialGradient(
      colors: [
        scheme.primaryContainer.withValues(alpha: .95),
        scheme.primary.withValues(alpha: .85),
        scheme.primary.withValues(alpha: .55),
      ],
      stops: const [0, .6, 1],
    );
    canvas.drawCircle(center, planetR, Paint()..shader = grad1.createShader(planetRect));

    // Subtle dark overlay at bottom
    final shadow = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.transparent, Colors.black.withValues(alpha: .25)],
    );
    canvas.drawCircle(center, planetR, Paint()..shader = shadow.createShader(planetRect) ..blendMode = BlendMode.darken);

    // Animated band waves across planet surface
    final bands = 4;
    for (var i = 0; i < bands; i++) {
      final bandT = (progress * 1.4 + i * .22) % 1.0;
      final y = center.dy + (bandT - .5) * planetR * 2;
      final bandPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              scheme.secondary.withValues(alpha: 0),
              scheme.secondary.withValues(alpha: .35),
              scheme.secondary.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromLTWH(center.dx - planetR, y - 6, planetR * 2, 12));
      canvas.save();
      final clipPath = Path()..addOval(planetRect);
      canvas.clipPath(clipPath);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(center.dx, y), width: planetR * 2, height: 12), const Radius.circular(12)),
        bandPaint,
      );
      canvas.restore();
    }

    // Rings
    final ringBaseR = planetR * 1.25;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..shader = SweepGradient(colors: [scheme.secondary, scheme.primary, scheme.secondary]).createShader(Rect.fromCircle(center: center, radius: ringBaseR));
    final rotation = progress * math.pi * 2;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(.6); // tilt
    canvas.rotate(rotation * .5);
    final ringPath = Path();
    ringPath.addOval(Rect.fromCircle(center: Offset.zero, radius: ringBaseR));
    canvas.drawPath(ringPath, ringPaint..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    // Inner faint ring
    canvas.drawOval(Rect.fromCircle(center: Offset.zero, radius: ringBaseR * .82), ringPaint..strokeWidth = 1.2..color = scheme.secondary.withValues(alpha: .3));
    canvas.restore();

    // Outgoing energy pulses (expanding circles)
    final pulses = 3;
    for (var i = 0; i < pulses; i++) {
      final localT = ((progress + i / pulses) % 1.0);
      final pulseR = planetR + localT * planetR * 2.0;
      final opacity = (1 - localT).clamp(0.0, 1.0) * .4;
      final pulsePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * (1 - localT)
        ..color = scheme.primary.withValues(alpha: opacity);
      canvas.drawCircle(center, pulseR, pulsePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NeptunePainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.scheme != scheme;
}

class _ProgressBar extends StatelessWidget {
  final double value; // 0..1
  const _ProgressBar({required this.value});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 12,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              fit: StackFit.expand,
              children: [
                Container(color: scheme.surfaceContainerHighest.withValues(alpha: .4)),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value.clamp(0, 1),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [scheme.primary, scheme.secondary],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
