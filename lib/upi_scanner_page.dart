import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
  import 'package:mobile_scanner/mobile_scanner.dart'; // switched from qr_code_scanner
import 'package:permission_handler/permission_handler.dart'; // added for runtime camera permission

/// A modern UPI QR code scanner page with animated overlay.
class UpiQrScannerPage extends StatefulWidget {
  const UpiQrScannerPage({super.key});

  @override
  State<UpiQrScannerPage> createState() => _UpiQrScannerPageState();
}

class _UpiQrScannerPageState extends State<UpiQrScannerPage> with SingleTickerProviderStateMixin {
  // Removed QRView key/controller; use MobileScannerController
  final MobileScannerController _msController = MobileScannerController(formats: [BarcodeFormat.qrCode]);
  bool _handlingResult = false;
  late final AnimationController _anim = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  bool _hasFlash = true; // mobile_scanner exposes torch state; assume available then verify
  bool _flashOn = false;
  PermissionStatus? _camStatus;
  bool _permissionTimedOut = false;
  Timer? _permissionTimer;

  @override
  void initState() {
    super.initState();
    _initPermission();
    // Fallback: if nothing returned in 3 seconds, allow user to retry
    _permissionTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _camStatus == null) {
        setState(() => _permissionTimedOut = true);
      }
    });
  }

  Future<void> _initPermission() async {
    try {
      if (!_isPlatformSupported) {
        // Still set a status so UI can move on (page itself will show unsupported placeholder earlier)
        setState(() => _camStatus = PermissionStatus.denied);
        return;
      }
      var status = await Permission.camera.status;
      if (!status.isGranted) {
        status = await Permission.camera.request();
      }
      if (!mounted) return;
      setState(() => _camStatus = status);
    } catch (e) {
      if (!mounted) return;
      setState(() => _camStatus = PermissionStatus.denied);
      debugPrint('Camera permission error: $e');
    } finally {
      _permissionTimer?.cancel();
    }
  }

  Future<void> _requestPermissionAgain() async {
    setState(() {
      _permissionTimedOut = false;
      _camStatus = null; // reset to show loading while re-requesting
    });
    await _initPermission();
    if (_camStatus?.isGranted ?? false) {
      await Future.delayed(const Duration(milliseconds: 120));
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _permissionTimer?.cancel();
    _anim.dispose();
    _msController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (kIsWeb || !_isPlatformSupported) {
      return const Scaffold(body: _UnsupportedPlaceholder(scheme: null));
    }

    // Permission flow states
    if (_camStatus == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black.withValues(alpha: .4), title: const Text('Scan UPI QR')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              if (!_permissionTimedOut)
                const Text('Requesting camera permission...', style: TextStyle(color: Colors.white70))
              else ...[
                const Text('Taking longer than expected.', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _requestPermissionAgain,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try Again'),
                ),
                const SizedBox(height: 8),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
              ]
            ],
          ),
        ),
      );
    }
    if (!_camStatus!.isGranted) {
      final permanentlyDenied = _camStatus!.isPermanentlyDenied;
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black.withValues(alpha: .4), title: const Text('Camera Permission')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.camera_alt_rounded, size: 84, color: scheme.primary),
                const SizedBox(height: 24),
                Text('Camera access needed', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Text(
                  'We need the camera to scan UPI QR codes. ${permanentlyDenied ? 'Please enable camera access in system settings.' : 'Grant permission to continue.'}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 32),
                if (!permanentlyDenied)
                  FilledButton.icon(
                    icon: const Icon(Icons.check_circle_rounded),
                    onPressed: _requestPermissionAgain,
                    label: const Text('Grant Access'),
                  ),
                if (permanentlyDenied) ...[
                  FilledButton.icon(
                    icon: const Icon(Icons.settings_rounded),
                    onPressed: () async {
                      final opened = await openAppSettings();
                      if (!mounted) return;
                      if (!opened) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open settings.')));
                      }
                    },
                    label: const Text('Open Settings'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: _requestPermissionAgain, child: const Text('Check Again')),
                ],
                const SizedBox(height: 20),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
              ],
            ),
          ),
        ),
      );
    }

    // Permission granted -> show scanner
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: .4),
        title: const Text('Scan UPI QR'),
        actions: [
          ValueListenableBuilder<TorchState>(
            valueListenable: _msController.torchState,
            builder: (context, state, _) {
              final enabled = state == TorchState.on;
              return IconButton(
                tooltip: enabled ? 'Flash Off' : 'Flash On',
                icon: Icon(enabled ? Icons.flash_on_rounded : Icons.flash_off_rounded),
                onPressed: () async {
                  try { await _msController.toggleTorch(); } catch (_) {}
                },
              );
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            key: const Key('mobile_scanner'),
            controller: _msController,
            onDetect: (capture) async {
              if (_handlingResult) return;
              for (final barcode in capture.barcodes) {
                final raw = barcode.rawValue;
                if (raw == null || raw.isEmpty) continue;
                if (!raw.toLowerCase().contains('upi')) continue; // basic filter
                _handlingResult = true;
                try { await _msController.stop(); } catch (_) {}
                if (!mounted) return;
                Navigator.of(context).pop(raw);
                break;
              }
            },
          ),
          // Animated overlay line
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _anim,
              builder: (ctx, _) {
                final t = Curves.easeInOut.transform((_anim.value * 2) % 1);
                final cut = _calcCutOut(context);
                final top = (MediaQuery.of(context).size.height - cut) / 2;
                final left = (MediaQuery.of(context).size.width - cut) / 2;
                return Stack(children: [
                  // dim outside area
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _CutoutPainter(rect: Rect.fromLTWH(left, top, cut, cut)),
                    ),
                  ),
                  Positioned(
                    left: left,
                    top: top + cut * t - 2,
                    width: cut,
                    height: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            scheme.primary.withValues(alpha: 0.0),
                            scheme.primaryContainer.withValues(alpha: 0.85),
                            scheme.secondary.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: .55),
                            blurRadius: 16,
                            spreadRadius: -2,
                          )
                        ],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  // corner borders
                  Positioned(
                    left: left,
                    top: top,
                    width: cut,
                    height: cut,
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _FramePainter(color: scheme.primary),
                      ),
                    ),
                  ),
                ]);
              },
            ),
          ),
          // Bottom instructions
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withValues(alpha: .75), Colors.black.withValues(alpha: 0.0)],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Align the UPI QR inside the frame',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'We will automatically detect & process the code',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: scheme.primaryContainer.withValues(alpha: .9),
                            foregroundColor: scheme.onPrimaryContainer,
                          ),
                          onPressed: () async {
                            try { await _msController.stop(); await _msController.start(); } catch (_) {}
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Reload'),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withValues(alpha: .4)),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  double _calcCutOut(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final shortest = size.shortestSide;
    return (shortest * 0.70).clamp(240, 360); // dynamic sizing
  }

  bool get _isPlatformSupported {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return true;
      default:
        return false; // desktop/web unsupported for camera scanning in this config
    }
  }
}

class _UnsupportedPlaceholder extends StatelessWidget {
  final ColorScheme? scheme;
  const _UnsupportedPlaceholder({required this.scheme});
  @override
  Widget build(BuildContext context) {
    final colors = scheme ?? Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_scanner_rounded, size: 72, color: colors.primary),
            const SizedBox(height: 16),
            Text('Scanner not supported on this platform', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Please run on an Android or iOS device/emulator to scan UPI QR codes.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
            const SizedBox(height: 24),
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      ),
    );
  }
}

// New painters for cutout/frame
class _CutoutPainter extends CustomPainter {
  final Rect rect;
  _CutoutPainter({required this.rect});
  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Path()..addRect(Offset.zero & size);
    final cut = Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(20)));
    final diff = Path.combine(PathOperation.difference, overlay, cut);
    canvas.drawPath(diff, Paint()..color = Colors.black.withValues(alpha: 0.55));
  }
  @override
  bool shouldRepaint(covariant _CutoutPainter old) => old.rect != rect;
}

class _FramePainter extends CustomPainter {
  final Color color;
  _FramePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final rect = Offset.zero & size;
    const len = 36.0;
    // Corners
    void corner(double x, double y, bool right, bool bottom) {
      final p = Path();
      final dx = right ? -len : len;
      final dy = bottom ? -len : len;
      p.moveTo(x, y + dy);
      p.lineTo(x, y);
      p.lineTo(x + dx, y);
      canvas.drawPath(p, paint);
    }
    corner(rect.left, rect.top, false, false);
    corner(rect.right, rect.top, true, false);
    corner(rect.left, rect.bottom, false, true);
    corner(rect.right, rect.bottom, true, true);
  }
  @override
  bool shouldRepaint(covariant _FramePainter oldDelegate) => oldDelegate.color != color;
}
