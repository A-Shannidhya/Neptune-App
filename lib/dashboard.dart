import 'dart:ui' show ImageFilter; // added for blur effect
import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  final String userName;
  final void Function(BuildContext context)? onLogout;
  const DashboardPage({super.key, required this.userName, this.onLogout});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: CircleAvatar(
            backgroundColor: scheme.primary.withValues(alpha: 0.15),
            child: Text('N', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold)),
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
          ],
        ),
      ),
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

  final Map<String, double> _balances = const {
    'Savings': 25430.75,
    'Overdraft': -1200.00,
    'Deposits': 8400.00,
    'Loans': 15000.00,
  };

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
                  Tooltip(
                    message: _hidden ? 'Show amounts' : 'Hide amounts',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(32),
                      onTap: () => setState(() => _hidden = !_hidden),
                      child: ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                          child: Container(
                            color: scheme.onPrimaryContainer.withValues(alpha: 0.10),
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              _hidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              size: 22,
                              color: scheme.onPrimaryContainer,
                              key: const Key('balances_toggle_button'),
                            ),
                          ),
                        ),
                      ),
                    ),
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
    _ActionItem('Send Money', Icons.send_rounded),
    _ActionItem('Direct Pay', Icons.payments_rounded),
    _ActionItem('My Beneficiary', Icons.group_rounded),
    _ActionItem('ePassbook', Icons.menu_book_rounded),
    _ActionItem('BillPay', Icons.receipt_long_rounded),
    _ActionItem('Cardless Cash', Icons.smartphone_rounded),
    _ActionItem('Other Bank', Icons.account_balance_rounded),
    _ActionItem('History', Icons.history_rounded),
  ];

  // Manage Accounts moved here per request; Donation removed previously
  static final List<_ActionItem> _extraActions = [
    _ActionItem('Manage Accounts', Icons.manage_accounts_rounded),
    _ActionItem('My Finance Management', Icons.pie_chart_rounded),
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
  void _handleTap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.label} (coming soon)')),
    );
  }
}
