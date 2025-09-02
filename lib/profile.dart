import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  final String fullName;
  const ProfilePage({super.key, required this.fullName});

  double _computeNameSize(String name, double maxWidth) {
    // Base logic: start large, shrink mildly as name grows; ensure readable.
    const double maxSize = 40;
    const double minSize = 22;
    // Estimate characters that comfortably fit at max size within width.
    final estPerLine = (maxWidth / (maxSize * 0.55)).floor();
    if (name.length <= estPerLine) return maxSize;
    final overflow = name.length - estPerLine;
    final shrink = overflow * 0.9; // shrink 0.9px per extra char
    return (maxSize - shrink).clamp(minSize, maxSize);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final options = <_ProfileOption>[
      _ProfileOption('Profile Details', Icons.badge_rounded),
      _ProfileOption('Accounts', Icons.account_balance_wallet_rounded),
      _ProfileOption('Settings and Limits', Icons.tune_rounded),
      _ProfileOption('Service Request', Icons.miscellaneous_services_rounded),
      _ProfileOption('Get in Touch', Icons.support_agent_rounded),
      _ProfileOption('Refer and Earn', Icons.card_giftcard_rounded),
      _ProfileOption('Privacy and Security', Icons.lock_rounded),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final nameFontSize = _computeNameSize(fullName, constraints.maxWidth - 32); // 16px horizontal padding each side
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: scheme.primary.withValues(alpha: 0.12),
                      child: Icon(Icons.person, size: 40, color: scheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        fullName,
                        key: const Key('profile_full_name'),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontSize: nameFontSize,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: scheme.onSurface,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                ...List.generate(options.length, (i) {
                  final opt = options[i];
                  return Column(
                    children: [
                      _OptionTile(option: opt),
                      if (i < options.length - 1)
                        Divider(
                          height: 0,
                          indent: 56, // align under text after icon
                          color: scheme.onSurface.withValues(alpha: 0.08),
                        ),
                    ],
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileOption {
  final String label;
  final IconData icon;
  const _ProfileOption(this.label, this.icon);
}

class _OptionTile extends StatelessWidget {
  final _ProfileOption option;
  const _OptionTile({required this.option});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      key: Key('profile_option_${option.label.replaceAll(' ', '_').toLowerCase()}'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: scheme.primary.withValues(alpha: 0.10),
        child: Icon(option.icon, size: 20, color: scheme.primary),
      ),
      title: Text(
        option.label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: scheme.onSurface.withValues(alpha: 0.55)),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${option.label} (coming soon)')),
        );
      },
    );
  }
}
