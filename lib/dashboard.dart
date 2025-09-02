import 'dart:ui' show ImageFilter; // added for blur effect
import 'package:flutter/material.dart';
import 'package:neptune/profile.dart';
import 'package:neptune/upi_scanner_page.dart'; // Import the UPI scanner page
import 'package:neptune/payment_page.dart'; // added for payment flow
import 'package:neptune/api/config.dart'; // added
import 'package:neptune/api/client.dart'; // added
import 'package:neptune/session.dart'; // added

class DashboardPage extends StatelessWidget {
  final String userName;
  final void Function(BuildContext context)? onLogout;
  final bool animateScanFab; // new flag to disable infinite animation in tests
  const DashboardPage({super.key, required this.userName, this.onLogout, this.animateScanFab = true});

  Future<void> _showBackendSettings(BuildContext context) async {
    final currentBase = await ApiConfig.getBaseUrl();
    final currentToken = await ApiConfig.getAuthToken() ?? '';
    final baseCtrl = TextEditingController(text: currentBase);
    final tokenCtrl = TextEditingController(text: currentToken);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backend Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: baseCtrl,
              decoration: const InputDecoration(
                labelText: 'Spring Boot Base URL',
                hintText: 'e.g. https://api.example.com or http://10.0.2.2:8080',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tokenCtrl,
              decoration: const InputDecoration(
                labelText: 'Auth token (optional)',
                hintText: 'Paste JWT token if required',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ApiConfig.setBaseUrl(baseCtrl.text.trim());
              await ApiConfig.setAuthToken(tokenCtrl.text.trim().isEmpty ? null : tokenCtrl.text.trim());
              if (context.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Saved. Tap refresh on balances to sync.')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: InkWell(
            key: const Key('dashboard_profile_button'),
            borderRadius: BorderRadius.circular(40),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ProfilePage(fullName: userName)),
              );
            },
            child: CircleAvatar(
              backgroundColor: scheme.primary.withValues(alpha: 0.15),
              child: Icon(Icons.person, color: scheme.primary),
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(userName, key: const Key('dashboard_username'), style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            key: const Key('dashboard_notifications'),
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No new notifications')));
            },
          ),
          IconButton(
            key: const Key('dashboard_settings'),
            tooltip: 'Backend Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showBackendSettings(context),
          ),
          IconButton(
            key: const Key('dashboard_logout'),
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () {
              if (onLogout != null) {
                onLogout!(context);
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Full-bleed balances card (extends beyond horizontal padding slightly)
            LayoutBuilder(
              builder: (ctx, constraints) {
                return Transform.translate(
                  offset: const Offset(-8, 0), // extend a bit left
                  child: SizedBox(
                    width: constraints.maxWidth + 16, // extend both sides
                    child: const _BalancesCard(),
                  ),
                );
              },
            ),
            const SizedBox(height: 28),
            const _PayTransferSection(),
            const SizedBox(height: 28),
            const _UpiSection(),
            const SizedBox(height: 28),
            const _DepositsSection(),
            const SizedBox(height: 28),
            const _LoansSection(),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _UpiScanFab(onTap: () async {
        final result = await Navigator.of(context).push<String>(
          MaterialPageRoute(builder: (_) => const UpiQrScannerPage()),
        );
        if (result != null && context.mounted) {
          // Navigate to payment page instead of simple snackbar
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => UpiPaymentPage(rawData: result)),
          );
        }
      }, animate: animateScanFab),
    );
  }
}

class _BalancesCard extends StatefulWidget {
  const _BalancesCard();
  @override
  State<_BalancesCard> createState() => _BalancesCardState();
}

class _BalancesCardState extends State<_BalancesCard> {
  bool _hidden = false;

  final Map<String, double> _fallback = const {
    'Savings': 25430.75,
    'Overdraft': -1200.00,
    'Deposits': 8400.00,
    'Loans': 15000.00,
  };

  Map<String, double> _balances = const {
    'Savings': 25430.75,
    'Overdraft': -1200.00,
    'Deposits': 8400.00,
    'Loans': 15000.00,
  };

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBalances();
  }

  Future<String> _safeGetBaseUrl() async {
    try { return await ApiConfig.getBaseUrl(); } catch (_) { return ''; }
  }
  Future<String?> _safeGetToken() async {
    try { return await ApiConfig.getAuthToken(); } catch (_) { return null; }
  }

  Future<void> _loadBalances() async {
    final baseUrl = await _safeGetBaseUrl();
    if (baseUrl.isEmpty) {
      setState(() { _error = null; _loading = false; _balances = _fallback; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final userId = await SessionStore.getUser();
      if (userId == null || userId.isEmpty) {
        setState(() { _loading = false; });
        return;
      }
      final token = await _safeGetToken();
      final api = ApiClient(baseUrl: baseUrl, authToken: token);
      final result = await api.fetchBalancesForUser(userId);
      if (!mounted) return;
      setState(() {
        _balances = result.isNotEmpty ? result : _fallback;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); _balances = _fallback; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Balance sync failed')));
    }
  }

  String _fmt(double v) {
    if (_hidden) return '•••••';
    return (v < 0 ? '-₹' : '₹') + v.abs().toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entries = _balances.entries.toList();
    final total = _balances.values.fold<double>(0, (a, b) => a + b);
    final positives = _balances.values.where((v) => v >= 0).fold<double>(0, (a, b) => a + b);
    final negatives = _balances.values.where((v) => v < 0).fold<double>(0, (a, b) => a + b).abs();
    final totalAbs = positives + negatives == 0 ? 1 : positives + negatives;
    final posRatio = positives / totalAbs;

    return Card(
      key: const Key('dashboard_balances_card'),
      elevation: 6,
      color: Colors.transparent,
      surfaceTintColor: scheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primaryContainer.withValues(alpha: 0.90),
              scheme.primary.withValues(alpha: 0.35),
              scheme.secondaryContainer.withValues(alpha: 0.25),
            ],
          ),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.15), width: 1),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.18),
              blurRadius: 22,
              offset: const Offset(0, 10),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Portfolio Overview',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: .4,
                                color: scheme.onPrimaryContainer.withValues(alpha: 0.9),
                              ),
                        ),
                        const SizedBox(height: 6),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 320),
                          transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: SizeTransition(sizeFactor: anim, axisAlignment: -1, child: child)),
                          child: Text(
                            _hidden ? '••••••••' : _fmt(total),
                            key: ValueKey(_hidden.toString() + '_total'),
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: scheme.onPrimaryContainer,
                                  letterSpacing: -0.5,
                                ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Compact positive vs negative bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: SizedBox(
                            height: 10,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: (posRatio * 1000).round().clamp(1, 999),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [scheme.tertiary, scheme.primary]),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: ((1 - posRatio) * 1000).round().clamp(1, 999),
                                  child: Container(color: scheme.error.withValues(alpha: 0.65)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tooltip(
                        message: _hidden ? 'Show amounts' : 'Hide amounts',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(32),
                          onTap: () => setState(() => _hidden = !_hidden),
                          child: ClipOval(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                              child: Container(
                                color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.10),
                                padding: const EdgeInsets.all(10),
                                child: Icon(
                                  _hidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  size: 22,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  key: const Key('balances_toggle_button'),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_loading)
                        SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.2))
                      else
                        Tooltip(
                          message: 'Refresh balances',
                          child: InkWell(
                            onTap: _loadBalances,
                            borderRadius: BorderRadius.circular(32),
                            child: ClipOval(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                                child: Container(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.10),
                                  padding: const EdgeInsets.all(10),
                                  child: const Icon(Icons.refresh_rounded, size: 20, key: Key('balances_refresh_button')),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 22),
              ...List.generate(entries.length, (i) {
                final e = entries[i];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            e.key,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: scheme.onPrimaryContainer.withValues(alpha: 0.80),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: SlideTransition(position: Tween(begin: const Offset(0, .25), end: Offset.zero).animate(anim), child: child)),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              key: ValueKey(_hidden.toString() + e.key),
                              child: Text(
                                _fmt(e.value),
                                key: Key('balance_${e.key.toLowerCase()}'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (i < entries.length - 1) ...[
                      const SizedBox(height: 12),
                      Divider(
                        height: 1,
                        thickness: 1,
                        endIndent: 4,
                        indent: 4,
                        color: scheme.onPrimaryContainer.withValues(alpha: 0.14),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _PayTransferSection extends StatelessWidget {
  const _PayTransferSection();

  static final List<_ActionItem> _quickActions = [
    _ActionItem('Scan QR', Icons.qr_code_scanner_rounded), // added scanner shortcut
    _ActionItem('Send Money', Icons.send_rounded),
    _ActionItem('Direct Pay', Icons.payments_rounded),
    _ActionItem('My Beneficiary', Icons.group_rounded),
    _ActionItem('ePassbook', Icons.menu_book_rounded),
    _ActionItem('BillPay', Icons.receipt_long_rounded),
    _ActionItem('Cardless Cash', Icons.smartphone_rounded),
    _ActionItem('Other Bank', Icons.account_balance_rounded),
  ];

  // Manage Accounts moved here per request; Donation removed previously
  static final List<_ActionItem> _extraActions = [
    _ActionItem('Manage Accounts', Icons.manage_accounts_rounded),
    _ActionItem('My Finance Management', Icons.pie_chart_rounded),
    _ActionItem('History', Icons.history_rounded),
  ];

  void _showAll(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Pay & Transfer',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Quick Actions', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: .4)),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _quickActions.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (c, i) => _ActionTile(item: _quickActions[i]),
                ),
                const SizedBox(height: 18),
                Text('More Services', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: .4)),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _extraActions.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (c, i) => _ActionTile(item: _extraActions[i]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Pay & Transfer',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
              ),
            ),
            if (_extraActions.isNotEmpty)
              TextButton(
                key: const Key('pay_transfer_more_button'),
                onPressed: () => _showAll(context),
                child: const Text('More'),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Common payment & transfer shortcuts',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.65),
              ),
        ),
        const SizedBox(height: 16),
        // Non-scrollable grid (two rows, 4 columns)
        LayoutBuilder(
          builder: (ctx, constraints) {
            const columns = 4;
            final childAspect = 0.8; // more vertical height to avoid overflow (was 0.95)
            return GridView.builder(
              key: const Key('pay_transfer_quick_grid'),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _quickActions.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: childAspect,
              ),
              itemBuilder: (c, i) => _GridActionChip(item: _quickActions[i], color: scheme.primary),
            );
          },
        ),
      ],
    );
  }
}

class _UpiSection extends StatelessWidget {
  const _UpiSection();

  static final List<_ActionItem> _quickActions = [
    _ActionItem('Registers', Icons.app_registration_rounded),
    _ActionItem('Scan QR', Icons.qr_code_scanner_rounded),
    _ActionItem('Pay to Mobile', Icons.phone_android_rounded),
    _ActionItem('Approve Payment', Icons.task_alt_rounded),
    _ActionItem('Tap & Pay', Icons.nfc_rounded),
    _ActionItem('Send Money (UPI)', Icons.send_rounded),
    _ActionItem('Request Money', Icons.request_page_rounded),
    _ActionItem('Mandate', Icons.assignment_turned_in_rounded),
  ];

  static final List<_ActionItem> _extraActions = [
    _ActionItem('My UPI Account', Icons.account_circle_rounded),
  ];

  void _showAll(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'UPI',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Quick UPI Actions', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: .4)),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _quickActions.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (c, i) => _ActionTile(item: _quickActions[i]),
                ),
                if (_extraActions.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text('More UPI Services', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: .4)),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _extraActions.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.95,
                    ),
                    itemBuilder: (c, i) => _ActionTile(item: _extraActions[i]),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'UPI',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
              ),
            ),
            if (_extraActions.isNotEmpty)
              TextButton(
                key: const Key('upi_more_button'),
                onPressed: () => _showAll(context),
                child: const Text('More'),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Unified Payments Interface shortcuts',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.65),
              ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (ctx, constraints) {
            const columns = 4;
            const childAspect = 0.8;
            return GridView.builder(
              key: const Key('upi_quick_grid'),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _quickActions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: childAspect,
              ),
              itemBuilder: (c, i) => _GridActionChip(item: _quickActions[i], color: scheme.primary),
            );
          },
        ),
      ],
    );
  }
}

class _DepositsSection extends StatelessWidget {
  const _DepositsSection();

  static final List<_ActionItem> _quickActions = [
    _ActionItem('Fixed Deposit', Icons.savings_rounded),
    _ActionItem('Recurring Deposit', Icons.autorenew_rounded),
    _ActionItem('Certificates/Forms', Icons.description_rounded),
    _ActionItem('Other Services', Icons.miscellaneous_services_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deposits',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Deposit products & services',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.65),
              ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (ctx, constraints) {
            const columns = 4; // exactly four options
            const childAspect = 0.8;
            return GridView.builder(
              key: const Key('deposits_quick_grid'),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _quickActions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: childAspect,
              ),
              itemBuilder: (c, i) => _GridActionChip(item: _quickActions[i], color: scheme.primary),
            );
          },
        ),
      ],
    );
  }
}

class _LoansSection extends StatelessWidget {
  const _LoansSection();

  // Quick grid now only first 8 options
  static final List<_ActionItem> _quickActions = [
    _ActionItem('Instant Overdraft', Icons.flash_on_rounded),
    _ActionItem('Loan details', Icons.info_rounded),
    _ActionItem('Loan Repayment', Icons.payments_rounded),
    _ActionItem('Loan Account Statement', Icons.description_rounded),
    _ActionItem('Loan Calculator', Icons.calculate_rounded),
    _ActionItem('Pre-Close Loan against Deposit', Icons.lock_clock_rounded),
    _ActionItem('Apply edu-loan', Icons.school_rounded),
    _ActionItem('personal loan', Icons.person_rounded),
  ];

  // Extra sheet: moved car loan & gold loan here + existing extra
  static final List<_ActionItem> _extraActions = [
    _ActionItem('car loan', Icons.directions_car_rounded),
    _ActionItem('gold loan', Icons.workspace_premium_rounded),
    _ActionItem('Track Loan Application', Icons.track_changes_rounded),
  ];

  void _showAll(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Loans',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Loan Services', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: .4)),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _quickActions.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (c, i) => _ActionTile(item: _quickActions[i]),
                ),
                if (_extraActions.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text('More Loan Tools', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: .4)),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _extraActions.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.95,
                    ),
                    itemBuilder: (c, i) => _ActionTile(item: _extraActions[i]),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Loans',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
              ),
            ),
            if (_extraActions.isNotEmpty)
              TextButton(
                key: const Key('loans_more_button'),
                onPressed: () => _showAll(context),
                child: const Text('More'),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Loan accounts & tools',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.65),
              ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (ctx, constraints) {
            const columns = 4; // grid for 10 items
            const childAspect = 0.8;
            return GridView.builder(
              key: const Key('loans_quick_grid'),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _quickActions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: childAspect,
              ),
              itemBuilder: (c, i) => _GridActionChip(item: _quickActions[i], color: scheme.primary),
            );
          },
        ),
      ],
    );
  }
}

class _ActionItem {
  final String label;
  final IconData icon;
  const _ActionItem(this.label, this.icon);
}

class _ActionTile extends StatelessWidget {
  final _ActionItem item;
  const _ActionTile({required this.item});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      key: Key('sheet_action_${item.label.replaceAll(' ', '_').toLowerCase()}'),
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.label} (coming soon)')),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.25), // updated from deprecated surfaceVariant.withOpacity
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.12)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: scheme.primary, size: 26), // slightly smaller icon
            const SizedBox(height: 6),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11, // reduced to avoid overflow
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _GridActionChip extends StatelessWidget {
  final _ActionItem item;
  final Color color;
  const _GridActionChip({required this.item, required this.color});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      key: Key('grid_action_${item.label.replaceAll(' ', '_').toLowerCase()}'),
      borderRadius: BorderRadius.circular(16),
      onTap: () => _handleTap(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10), // tighter padding
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 18, color: color), // smaller icon
            const SizedBox(height: 6),
            Tooltip(
              message: item.label,
              waitDuration: const Duration(milliseconds: 400),
              child: Text(
                item.label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 10, // further reduced to avoid overflow
                      height: 1.1,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _handleTap(BuildContext context) async {
    // Open scanner directly for Scan QR actions
    if (item.label == 'Scan QR') {
      final result = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const UpiQrScannerPage()),
      );
      if (result != null && context.mounted) {
        // Navigate to payment page instead of snackbar
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => UpiPaymentPage(rawData: result)),
        );
      }
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.label} (coming soon)')),
    );
  }
}

// Insert new animated FAB widget for UPI scanning
class _UpiScanFab extends StatefulWidget {
  final VoidCallback onTap;
  final bool animate;
  const _UpiScanFab({required this.onTap, this.animate = true});
  @override
  State<_UpiScanFab> createState() => _UpiScanFabState();
}

class _UpiScanFabState extends State<_UpiScanFab> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Scan UPI QR',
      button: true,
      child: GestureDetector(
        key: const Key('upi_scan_fab'),
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (ctx, _) {
            final t = _controller.isAnimating ? _controller.value : 0.0;
            return _ScanFabVisual(t: t, scheme: scheme);
          },
        ),
      ),
    );
  }
}

class _ScanFabVisual extends StatelessWidget {
  final double t;
  final ColorScheme scheme;
  const _ScanFabVisual({required this.t, required this.scheme});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 86,
      height: 86,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                startAngle: 0,
                endAngle: 6.28318,
                colors: [
                  scheme.primary.withValues(alpha: 0.05),
                  scheme.primary.withValues(alpha: 0.20),
                  scheme.secondary.withValues(alpha: 0.25),
                  scheme.primary.withValues(alpha: 0.05),
                ],
                stops: [0, (t * 0.5 + 0.2) % 1, (t * 0.5 + 0.4) % 1, 1],
                transform: GradientRotation(t * 6.28318),
              ),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.35),
                  blurRadius: 22,
                  spreadRadius: -4,
                )
              ],
            ),
          ),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primaryContainer.withValues(alpha: 0.85),
                  scheme.secondaryContainer.withValues(alpha: 0.70),
                ],
              ),
              border: Border.all(color: scheme.primary.withValues(alpha: 0.25), width: 1.2),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.qr_code_scanner_rounded, size: 34, color: scheme.onPrimaryContainer),
                Positioned.fill(
                  child: ClipOval(
                    child: CustomPaint(
                      painter: _ScanPulsePainter(progress: t, color: scheme.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanPulsePainter extends CustomPainter {
  final double progress;
  final Color color;
  const _ScanPulsePainter({required this.progress, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0), color.withValues(alpha: 0.15), color.withValues(alpha: 0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const [0, 0.5, 1],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final lineY = (size.height) * progress;
    canvas.drawRect(Rect.fromLTWH(0, lineY - 4, size.width, 8), paint);
  }
  @override
  bool shouldRepaint(covariant _ScanPulsePainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.color != color;
}
