import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'transfer_animation_page.dart';
import 'success_tick_page.dart';

/// PIN entry page: collects 6-digit PIN (digits visible while typing),
/// once 6 digits entered it auto-obscures and proceeds to success animation.
class PinEntryPage extends StatefulWidget {
  final String amount;
  final String recipient;
  const PinEntryPage({super.key, required this.amount, required this.recipient});
  @override
  State<PinEntryPage> createState() => _PinEntryPageState();
}

class _PinEntryPageState extends State<PinEntryPage> {
  static const int _pinLength = 6;
  final TextEditingController _pinCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _obscure = false; // will obscure only after successful submission
  bool _navigating = false;
  bool _forceShowPending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showKeyboard(immediate: true));
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _forceShowPending) {
        _forceShowPending = false;
        SystemChannels.textInput.invokeMethod('TextInput.show');
      }
    });
    _pinCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_navigating) return;
    if (_pinCtrl.text.length != _pinLength) return;
    setState(() {
      _navigating = true;
      _obscure = true; // hide digits after pressing Transfer
    });
    // First show transfer animation (which internally shows success tick page afterwards)
    final success = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TransferAnimationPage(amount: widget.amount, recipient: widget.recipient),
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(success == true);
  }

  void _showKeyboard({bool immediate = false}) {
    if (_navigating) return;
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
      _forceShowPending = true; // will trigger in focus listener
    } else {
      // Microtask to nudge IME without full re-focus
      Future.microtask(() => SystemChannels.textInput.invokeMethod('TextInput.show'));
    }
    if (immediate) {
      Future.microtask(() => SystemChannels.textInput.invokeMethod('TextInput.show'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pin = _pinCtrl.text;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter UPI PIN'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.primaryContainer.withValues(alpha: .20),
                    scheme.surface,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Confirm Transfer', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('₹${widget.amount} to ${widget.recipient}', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 40),
                  // PIN input stack: visible boxes + invisible full-width TextField handling input
                  SizedBox(
                    height: 70,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0,
                            child: TextField(
                              focusNode: _focusNode,
                              controller: _pinCtrl,
                              autofocus: true,
                              enableInteractiveSelection: false,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              maxLength: _pinLength,
                              decoration: const InputDecoration(
                                counterText: '',
                                border: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(_pinLength)],
                              onTap: () => _showKeyboard(immediate: true),
                              onEditingComplete: () {},
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _showKeyboard(immediate: true),
                          ),
                        ),
                        _PinBoxes(pin: pin, obscure: _obscure, pinLength: _pinLength, onTapBox: ({int delayMs = 0}) => _showKeyboard(immediate: true)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: (pin.length == _pinLength && !_navigating) ? _submit : null,
                    icon: const Icon(Icons.send_rounded),
                    label: Text(_navigating ? 'Transferring...' : 'Transfer'),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
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

class _PinBoxes extends StatelessWidget {
  final String pin;
  final bool obscure;
  final int pinLength;
  final void Function({int delayMs})? onTapBox;
  const _PinBoxes({required this.pin, required this.obscure, required this.pinLength, this.onTapBox});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(pinLength, (i) {
        final has = i < pin.length;
        final char = has ? pin[i] : '';
        final isCursor = !has && i == pin.length; // show cursor bar at current position
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          width: 48,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: has
                ? LinearGradient(
                    colors: [
                      scheme.primary.withValues(alpha: .65),
                      scheme.secondary.withValues(alpha: .55),
                    ],
                  )
                : LinearGradient(
                    colors: [
                      scheme.surfaceContainerHigh,
                      scheme.surfaceContainerHighest,
                    ],
                  ),
            border: Border.all(color: has ? scheme.primary.withValues(alpha: .35) : scheme.outlineVariant.withValues(alpha: .4), width: 1.2),
            boxShadow: has
                ? [
                    BoxShadow(color: scheme.primary.withValues(alpha: .25), blurRadius: 14, spreadRadius: -4, offset: const Offset(0, 6)),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          // Tap each box also ensures focus
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            splashColor: Colors.transparent,
            focusColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            onTap: () => onTapBox?.call(delayMs: 0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
              child: has
                  ? Text(
                      obscure ? '•' : char,
                      key: ValueKey(obscure ? 'dot$i' : 'char$i'),
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white),
                    )
                  : Text(
                      isCursor ? '|' : '',
                      key: ValueKey(isCursor ? 'cursor$i' : 'empty$i'),
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400, color: scheme.onSurfaceVariant),
                    ),
            ),
          ),
        );
      }),
    );
  }
}
