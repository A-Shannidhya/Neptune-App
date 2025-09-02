import 'package:flutter/material.dart';
import 'pin_entry_page.dart';

/// Payment page shown after scanning a UPI QR code.
/// Expects the raw UPI intent/deep link string (e.g. upi://pay?pa=abc@upi&pn=John%20Doe&am=150)
class UpiPaymentPage extends StatefulWidget {
  final String rawData;
  const UpiPaymentPage({super.key, required this.rawData});

  @override
  State<UpiPaymentPage> createState() => _UpiPaymentPageState();
}

class _UpiPaymentPageState extends State<UpiPaymentPage> {
  late final _parsed = _parse(widget.rawData);
  final TextEditingController _amountCtrl = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    // Pre-fill amount if provided and valid
    final am = _parsed.amount;
    if (am != null && am > 0) {
      _amountCtrl.text = _formatAmount(am);
    }
    _amountCtrl.addListener(_validate);
    _validate();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _validate() {
    final txt = _amountCtrl.text.trim();
    String? err;
    if (txt.isEmpty) {
      err = 'Enter amount';
    } else {
      final v = double.tryParse(txt);
      if (v == null) {
        err = 'Invalid number';
      } else if (v <= 0) {
        err = 'Must be > 0';
      }
    }
    if (err != _error) {
      setState(() => _error = err);
    }
  }

  String _formatAmount(double v) {
    if (v % 1 == 0) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2);
  }

  Future<void> _submit() async {
    _validate();
    if (_error != null) return;
    final amountText = _amountCtrl.text.trim();
    final name = _parsed.name ?? 'Recipient';
    final success = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PinEntryPage(amount: amountText, recipient: name),
      ),
    );
    if (!mounted) return;
    if (success == true) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('UPI Payment'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Enhanced layered gradient background
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.primaryContainer.withValues(alpha: 0.55),
                    scheme.secondaryContainer.withValues(alpha: 0.45),
                    scheme.tertiaryContainer.withValues(alpha: 0.40),
                  ],
                  stops: const [0, .55, 1],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _SoftAuraPainter(
                  colorA: scheme.primary.withValues(alpha: .22),
                  colorB: scheme.secondary.withValues(alpha: .18),
                  colorC: scheme.tertiary.withValues(alpha: .16),
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recipient summary card
                  _RecipientCard(name: _parsed.name, upiId: _parsed.upiId),
                  const SizedBox(height: 28),
                  Text('Amount', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: .3)),
                  const SizedBox(height: 8),
                  _AmountField(
                    controller: _amountCtrl,
                    error: _error,
                    onSubmit: _submit,
                  ),
                  const SizedBox(height: 40),
                  _GradientButton(
                    key: const Key('payment_transfer_button'),
                    enabled: _error == null,
                    onTap: _error == null ? _submit : null,
                    label: 'Transfer',
                    icon: Icons.rocket_launch_rounded,
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

class _RecipientCard extends StatelessWidget {
  final String? name;
  final String? upiId;
  const _RecipientCard({this.name, this.upiId});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer.withValues(alpha: .65),
            scheme.secondaryContainer.withValues(alpha: .50),
          ],
        ),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.20)),
        boxShadow: [
          BoxShadow(color: scheme.primary.withValues(alpha: .18), blurRadius: 24, spreadRadius: -4, offset: const Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(colors: [scheme.primary, scheme.secondary, scheme.primary]),
            ),
            child: const Icon(Icons.account_circle, size: 40, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name ?? 'Unknown Recipient',
                  key: const Key('payment_recipient_name'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.qr_code_2_rounded, size: 16, color: scheme.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        upiId ?? 'Unknown UPI ID',
                        key: const Key('payment_upi_id'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final String? error;
  final VoidCallback onSubmit;
  const _AmountField({required this.controller, required this.error, required this.onSubmit});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        scheme.primary.withValues(alpha: 0.80),
        scheme.secondary.withValues(alpha: 0.70),
        scheme.tertiary.withValues(alpha: 0.70),
      ],
    );
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: gradient,
        boxShadow: [
          BoxShadow(color: scheme.primary.withValues(alpha: .35), blurRadius: 24, spreadRadius: -8, offset: const Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.all(1.2),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: scheme.surface.withValues(alpha: 0.90),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: TextField(
          key: const Key('payment_amount_field'),
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: .5, color: scheme.onSurface),
          decoration: InputDecoration(
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 18, right: 6, top: 2),
              child: Text('₹', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            hintText: '0.00',
            hintStyle: TextStyle(color: scheme.onSurface.withValues(alpha: .35), fontWeight: FontWeight.w600),
            errorText: error,
            border: InputBorder.none,
          ),
          onSubmitted: (_) => onSubmit(),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool enabled;
  final String label;
  final IconData icon;
  const _GradientButton({super.key, required this.onTap, required this.enabled, required this.label, required this.icon});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: enabled
          ? [
              scheme.primary,
              scheme.secondary,
              scheme.tertiary,
            ]
          : [scheme.surfaceContainerHighest, scheme.surfaceContainerHighest],
    );
    return Opacity(
      opacity: enabled ? 1 : .55,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: enabled
                ? [
                    BoxShadow(color: scheme.primary.withValues(alpha: .30), blurRadius: 28, spreadRadius: -6, offset: const Offset(0, 10)),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: .5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoftAuraPainter extends CustomPainter {
  final Color colorA; final Color colorB; final Color colorC;
  _SoftAuraPainter({required this.colorA, required this.colorB, required this.colorC});
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 90);
    paint.color = colorA; canvas.drawCircle(center + const Offset(-60, -100), size.shortestSide * .45, paint);
    paint.color = colorB; canvas.drawCircle(center + const Offset(120, -40), size.shortestSide * .38, paint);
    paint.color = colorC; canvas.drawCircle(center + const Offset(-30, 140), size.shortestSide * .42, paint);
  }
  @override
  bool shouldRepaint(covariant _SoftAuraPainter old) => old.colorA != colorA || old.colorB != colorB || old.colorC != colorC;
}

class _UpiParsedData {
  final String? upiId;
  final String? name;
  final double? amount;
  const _UpiParsedData({this.upiId, this.name, this.amount});
}

_UpiParsedData _parse(String raw) {
  try {
    // Some scanners may return raw with whitespace/newlines
    final trimmed = raw.trim();
    Uri? uri;
    if (trimmed.startsWith('upi://')) {
      uri = Uri.parse(trimmed);
    } else if (trimmed.contains('upi://')) {
      final idx = trimmed.indexOf('upi://');
      uri = Uri.parse(trimmed.substring(idx));
    }
    if (uri == null) return const _UpiParsedData();
    final q = uri.queryParameters.map((k, v) => MapEntry(k.toLowerCase(), v));
    final upiId = q['pa'];
    final name = q['pn'];
    final amountStr = q['am'];
    final amount = amountStr == null ? null : double.tryParse(amountStr);
    return _UpiParsedData(upiId: upiId, name: name, amount: amount);
  } catch (_) {
    return const _UpiParsedData();
  }
}
