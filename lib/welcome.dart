import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async'; // added for Timer
import 'dart:math'; // for Random.secure
import 'package:flutter/foundation.dart'; // kDebugMode
import 'dashboard.dart'; // added for dashboard navigation

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [scheme.primary.withValues(alpha: 0.10), scheme.primary.withValues(alpha: 0.02)],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                'Neptune Bank',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                      letterSpacing: 0.5,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Welcoming you to a smarter, safer,\nmodern digital banking experience.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.75),
                      height: 1.3,
                    ),
              ),
              const Spacer(),
              _TaglineCard(),
              const SizedBox(height: 32),
              const _PrimaryActionButtons(),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  'Secure • Fast • Trusted',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        letterSpacing: 1.1,
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaglineCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: scheme.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_graph_rounded, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                'Welcome',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.primary,
                    ),
              )
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Empowering your financial journey with \nclarity, control, and confidence.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.35,
                  color: scheme.onSurface.withValues(alpha: 0.75),
                ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionButtons extends StatelessWidget {
  const _PrimaryActionButtons();
  Future<void> _openAccountSite(BuildContext context) async {
    final uri = Uri.parse('https://www.neptunebank.online');
    try {
      // Try external application first if resolvable
      if (await canLaunchUrl(uri)) {
        final okExternal = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (okExternal) return;
      }
      // Fallback to in-app browser view
      final okInApp = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      if (okInApp) return;
      // Final fallback: platform default
      final okDefault = await launchUrl(uri, mode: LaunchMode.platformDefault);
      if (!okDefault && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open browser for account site.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Open failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            key: const Key('login_button'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LoginPage()),
            ),
            child: const Text('Log In'),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            key: const Key('create_account_button'),
            onPressed: () => _openAccountSite(context),
            child: const Text('Create Account'),
          ),
        ),
      ],
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _userIdCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _securityAnsCtrl = TextEditingController();
  final _captchaCtrl = TextEditingController();
  final _otpInputCtrl = TextEditingController(); // new OTP input controller

  // Security question
  final List<String> _questions = const [
    'What is your mother\'s maiden name?',
    'What was the name of your first pet?',
    'What city were you born in?',
  ];
  String? _selectedQuestion;

  late String _captchaCode;
  String? _otpCode;
  DateTime? _resendAvailableAt;
  Timer? _otpTimer;
  ValueNotifier<Duration> _remainingNotifier = ValueNotifier(Duration.zero);
  final String _maskedDestination = 'us****@mail.com'; // demo variable representing where OTP sent

  @override
  void initState() {
    super.initState();
    _generateCaptcha();
  }

  void _generateCaptcha() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random.secure();
    _captchaCode = List.generate(7, (_) => chars[rand.nextInt(chars.length)]).join();
    setState(() {});
  }

  Future<void> _sendOtp(String userId) async {
    // Placeholder for backend call. Simulate network delay.
    await Future.delayed(const Duration(milliseconds: 400));
    final r = Random.secure();
    _otpCode = List.generate(6, (_) => r.nextInt(10).toString()).join();
  }

  void _startResendCountdown() {
    _resendAvailableAt = DateTime.now().add(const Duration(minutes: 2));
    _remainingNotifier.value = _resendAvailableAt!.difference(DateTime.now());
    _otpTimer?.cancel();
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      final now = DateTime.now();
      if (_resendAvailableAt != null && now.isBefore(_resendAvailableAt!)) {
        _remainingNotifier.value = _resendAvailableAt!.difference(now);
      } else {
        _remainingNotifier.value = Duration.zero;
        t.cancel();
      }
    });
  }

  Future<void> _generateOtp() async {
    await _sendOtp(_userIdCtrl.text.trim());
    _startResendCountdown();
  }

  @override
  void dispose() {
    _userIdCtrl.dispose();
    _passwordCtrl.dispose();
    _securityAnsCtrl.dispose();
    _captchaCtrl.dispose();
    _otpInputCtrl.dispose();
    _otpTimer?.cancel();
    _remainingNotifier.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      _generateOtp().then((_) => _showOtpDialog());
    }
  }

  void _showOtpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          key: const Key('otp_dialog'),
          title: const Text('OTP Verification'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('An OTP has been sent to $_maskedDestination'),
              const SizedBox(height: 12),
              if (kDebugMode) // display only in debug/test builds
                Row(
                  children: [
                    Text(
                      _otpCode ?? '------',
                      key: const Key('otp_code_text'),
                      style: const TextStyle(
                        fontSize: 20,
                        letterSpacing: 4,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Tooltip(
                      message: 'Shown only in debug for testing.',
                      child: Icon(Icons.info_outline, size: 18),
                    )
                  ],
                )
              else
                const Text('Enter the 6-digit code you received.'),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('otp_input'),
                controller: _otpInputCtrl,
                maxLength: 6,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Enter OTP'),
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<Duration>(
                valueListenable: _remainingNotifier,
                builder: (context, remaining, _) {
                  if (remaining.inSeconds == 0) {
                    return const SizedBox.shrink();
                  }
                  final mm = (remaining.inSeconds ~/ 60).toString().padLeft(2, '0');
                  final ss = (remaining.inSeconds % 60).toString().padLeft(2, '0');
                  return Text('Resend in $mm:$ss', key: const Key('otp_countdown_text'));
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              key: const Key('otp_cancel_button'),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ValueListenableBuilder<Duration>(
              valueListenable: _remainingNotifier,
              builder: (context, remaining, _) {
                final canResend = remaining.inSeconds == 0;
                return TextButton(
                  key: const Key('otp_resend_button'),
                  onPressed: canResend
                      ? () async {
                          await _generateOtp();
                          if (mounted) setState(() {});
                        }
                      : null,
                  child: const Text('Resend OTP'),
                );
              },
            ),
            ElevatedButton(
              key: const Key('otp_verify_button'),
              onPressed: () {
                if (_otpInputCtrl.text == _otpCode) {
                  Navigator.of(ctx).pop();
                  // Navigate to dashboard replacing login page
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => DashboardPage(
                        userName: _userIdCtrl.text.trim().isEmpty ? 'User' : _userIdCtrl.text.trim(),
                        onLogout: (c) {
                          Navigator.of(c).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const WelcomePage()),
                            (route) => false,
                          );
                        },
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Invalid OTP')),
                  );
                }
              },
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Log In')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label: 'User ID input field',
                child: TextFormField(
                  key: const Key('login_user_id'),
                  controller: _userIdCtrl,
                  decoration: const InputDecoration(labelText: 'User ID'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter User ID' : null,
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                label: 'Password input field',
                child: TextFormField(
                  key: const Key('login_password'),
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter Password' : null,
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                label: 'Security question selector',
                child: DropdownButtonFormField<String>(
                  key: const Key('login_security_question'),
                  decoration: const InputDecoration(labelText: 'Security Question'),
                  initialValue: _selectedQuestion,
                  items: _questions
                      .map((q) => DropdownMenuItem<String>(value: q, child: Text(q)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedQuestion = v),
                  validator: (v) => v == null ? 'Select a question' : null,
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                label: 'Security question answer field',
                child: TextFormField(
                  key: const Key('login_security_answer'),
                  controller: _securityAnsCtrl,
                  decoration: const InputDecoration(labelText: 'Security Question Answer'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter answer' : null,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Semantics(
                    label: 'Captcha code image',
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        _captchaCode,
                        key: const Key('login_captcha_code'),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 18,
                          letterSpacing: 2,
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('login_captcha_refresh'),
                    tooltip: 'Refresh Captcha',
                    onPressed: _generateCaptcha,
                    icon: const Icon(Icons.refresh),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Semantics(
                      label: 'Captcha entry field',
                      child: TextFormField(
                        key: const Key('login_captcha_input'),
                        controller: _captchaCtrl,
                        decoration: const InputDecoration(labelText: 'Enter Captcha'),
                        validator: (v) => (v == null || v.trim() != _captchaCode) ? 'Captcha mismatch' : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Semantics(
                label: 'Login button',
                button: true,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: const Key('login_submit'),
                    onPressed: _submit,
                    child: const Text('Login'),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _OptionLink(label: 'Create / Reset Login Password', keyName: 'option_reset_password'),
                  _OptionLink(label: 'Unlock User ID', keyName: 'option_unlock_user'),
                  _OptionLink(label: 'Activate User ID', keyName: 'option_activate_user'),
                  _OptionLink(label: 'Forgot User ID', keyName: 'option_forgot_user'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionLink extends StatelessWidget {
  final String label;
  final String keyName;
  const _OptionLink({required this.label, required this.keyName});
  @override
  Widget build(BuildContext context) {
    return TextButton(
      key: Key(keyName),
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label (not implemented)')),
        );
      },
      child: Text(label, textAlign: TextAlign.center),
    );
  }
}
