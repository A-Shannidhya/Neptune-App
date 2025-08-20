import 'package:flutter/material.dart';
import 'dart:math' as math; // added for rotation math
import 'theme.dart'; // added theme import
import 'welcome.dart'; // import welcome page

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Neptune Bank',
      theme: NeptuneTheme.light(),
      darkTheme: NeptuneTheme.dark(),
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}

// Splash Screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _loopController; // continuous animation
  late final AnimationController _introController; // one-off entrance
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _ringRotation;
  late final Animation<double> _gradientShift;

  @override
  void initState() {
    super.initState();
    _loopController = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _introController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _logoScale = CurvedAnimation(parent: _introController, curve: Curves.easeOutBack);
    _logoOpacity = CurvedAnimation(parent: _introController, curve: Curves.easeIn);
    _ringRotation = CurvedAnimation(parent: _loopController, curve: Curves.linear);
    _gradientShift = CurvedAnimation(parent: _loopController, curve: Curves.easeInOutSine);
    _introController.forward();
    // Keep 5s splash then navigate
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WelcomePage()),
        );
      }
    });
  }

  @override
  void dispose() {
    _loopController.dispose();
    _introController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _loopController,
      builder: (context, _) {
        final t = _gradientShift.value; // 0..1
        // Two themed gradient sets we blend between for a subtle pulse
        final gradA = [
          scheme.primaryContainer.withValues(alpha: 0.85),
          scheme.surface,
          scheme.primary.withValues(alpha: 0.10),
        ];
        final gradB = [
          scheme.primary.withValues(alpha: 0.35),
            scheme.surface,
          scheme.primaryContainer.withValues(alpha: 0.15),
        ];
        List<Color> lerpGradient() => List.generate(gradA.length, (i) => Color.lerp(gradA[i], gradB[i], 0.5 * (1 - ( (t - 0.5).abs() * 2)))!);
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: lerpGradient(),
              ),
            ),
            child: Center(
              child: Semantics(
                label: 'Neptune Bank splash screen',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: _logoScale,
                      child: FadeTransition(
                        opacity: _logoOpacity,
                        child: _BrandMark(rotation: _ringRotation, colorScheme: scheme),
                      ),
                    ),
                    const SizedBox(height: 28),
                    FadeTransition(
                      opacity: _logoOpacity,
                      child: Text(
                        'Neptune Bank',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: scheme.primary,
                            ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: _logoOpacity,
                      child: Text(
                        'Banking reimagined. Secure. Seamless. Smart.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.70),
                              letterSpacing: 0.3,
                            ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Minimal progress indicator referencing theme
                    SizedBox(
                      width: 54,
                      child: AnimatedOpacity(
                        opacity: _introController.isCompleted ? 1 : 0,
                        duration: const Duration(milliseconds: 400),
                        child: LinearProgressIndicator(
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BrandMark extends StatelessWidget {
  final Animation<double> rotation;
  final ColorScheme colorScheme;
  const _BrandMark({required this.rotation, required this.colorScheme});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: AnimatedBuilder(
        animation: rotation,
        builder: (context, _) {
          return CustomPaint(
            painter: _BrandMarkPainter(
              spin: rotation.value,
              primary: colorScheme.primary,
              secondary: colorScheme.primaryContainer,
              outline: colorScheme.primary.withValues(alpha: 0.15),
            ),
          );
        },
      ),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  final double spin;
  final Color primary;
  final Color secondary;
  final Color outline;
  _BrandMarkPainter({required this.spin, required this.primary, required this.secondary, required this.outline});
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * 0.30;
    final ringRadius = size.width * 0.48;
    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [primary, secondary, primary],
        stops: const [0.0, 0.55, 1.0],
        startAngle: 0,
        endAngle: 6.28318,
        transform: GradientRotation(spin * 6.28318),
      ).createShader(Rect.fromCircle(center: center, radius: ringRadius));

    // Outer subtle outline
    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = outline;

    // Core filled circle
    final corePaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [secondary.withValues(alpha: 0.90), primary.withValues(alpha: 0.90)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    // Draw outline
    canvas.drawCircle(center, ringRadius, outlinePaint);

    // Draw animated wave ring arc segments (4 arcs)
    final arcRect = Rect.fromCircle(center: center, radius: ringRadius);
    const segments = 4;
    const gap = 12 * 3.14159 / 180; // 12 degrees gap
    final sweepBase = (6.28318 - gap * segments) / segments;
    for (int i = 0; i < segments; i++) {
      final start = spin * 6.28318 + i * (sweepBase + gap);
      canvas.drawArc(arcRect, start, sweepBase, false, wavePaint);
    }

    // Core circle
    canvas.drawCircle(center, radius, corePaint);

    // Inner orbiting dot
    final orbitAngle = spin * 6.28318 * 1.5;
    final dotOffset = Offset(center.dx + (radius + 10) * math.cos(orbitAngle), center.dy + (radius + 10) * math.sin(orbitAngle));
    final dotPaint = Paint()
      ..color = primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(dotOffset, 6, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _BrandMarkPainter oldDelegate) => oldDelegate.spin != spin || oldDelegate.primary != primary || oldDelegate.secondary != secondary;
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
