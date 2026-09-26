import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user_profile.dart';
import '../providers/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('No profile found'));
          }
          return _ProfileBody(profile: profile);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body — separated so it rebuilds only when profile data changes
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileBody extends ConsumerWidget {
  final UserProfile profile;

  const _ProfileBody({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      children: [
        // ── Avatar + Name ──────────────────────────────────────────────────
        Center(
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                child: Text(
                  profile.name.isNotEmpty
                      ? profile.name[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await context.push('/profile/edit', extra: profile);
                  ref.invalidate(profileProvider);
                },
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primary,
                  child: const Icon(
                    Icons.edit,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            profile.name,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Center(
          child: Text(
            '${profile.currencyCode} · ${profile.currencySymbol}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ),

        const SizedBox(height: 32),

        // ── Account Settings card ──────────────────────────────────────────
        _SectionLabel(label: 'Account'),
        Card(
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.person_outline,
                title: 'Edit Name',
                subtitle: profile.name,
                onTap: () async {
                  await context.push('/profile/edit', extra: profile);
                  ref.invalidate(profileProvider);
                },
              ),
              const _Divider(),
              _SettingsTile(
                icon: Icons.currency_exchange,
                title: 'Currency',
                subtitle: '${profile.currencyCode}  ${profile.currencySymbol}',
                onTap: () async {
                  await _showCurrencySheet(context, ref, profile);
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Security card ──────────────────────────────────────────────────
        _SectionLabel(label: 'Security'),
        Card(
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.lock_outline,
                title: 'App Lock (PIN)',
                subtitle: profile.isPinEnabled ? 'Enabled' : 'Disabled',
                subtitleColor: profile.isPinEnabled
                    ? AppTheme.income
                    : Colors.grey.shade500,
                trailing: Switch.adaptive(
                  value: profile.isPinEnabled,
                  activeColor: AppTheme.primary,
                  onChanged: (val) async {
                    final repo = ref.read(profileRepositoryProvider);
                    await repo.updateProfile(
                      profile.copyWith(
                        isPinEnabled: val,
                        updatedAt: DateTime.now(),
                      ),
                    );
                    ref.invalidate(profileProvider);
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── About card ────────────────────────────────────────────────────
        _SectionLabel(label: 'About'),
        Card(
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.info_outline,
                title: AppConstants.appName,
                subtitle: 'Version ${AppConstants.appVersion}',
                showChevron: false,
              ),
              const _Divider(),
              _SettingsTile(
                icon: Icons.shield_outlined,
                title: 'Privacy',
                subtitle: 'All data stays on your device — always.',
                showChevron: false,
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Future<void> _showCurrencySheet(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CurrencySheet(profile: profile, ref: ref),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Currency bottom sheet — inline so it can call ref directly
// ─────────────────────────────────────────────────────────────────────────────
class _CurrencySheet extends ConsumerWidget {
  final UserProfile profile;
  final WidgetRef ref;

  const _CurrencySheet({required this.profile, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (ctx, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Currency',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: kSupportedCurrencies.length,
                itemBuilder: (_, i) {
                  final c = kSupportedCurrencies[i];
                  final isSelected = c['code'] == profile.currencyCode;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSelected
                          ? AppTheme.primary.withValues(alpha: 0.12)
                          : Colors.grey.shade100,
                      child: Text(
                        c['symbol']!,
                        style: TextStyle(
                          color: isSelected
                              ? AppTheme.primary
                              : Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(c['name']!),
                    subtitle: Text(c['code']!),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: AppTheme.primary)
                        : null,
                    onTap: () async {
                      Navigator.pop(ctx);
                      final repo = ref.read(profileRepositoryProvider);
                      await repo.updateCurrency(
                        profile,
                        code: c['code']!,
                        symbol: c['symbol']!,
                      );
                      ref.invalidate(profileProvider);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small reusable widgets
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? subtitleColor;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showChevron;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.subtitleColor,
    this.onTap,
    this.trailing,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                color: subtitleColor ?? Colors.grey.shade600,
                fontSize: 13,
              ),
            )
          : null,
      trailing: trailing ??
          (showChevron && onTap != null
              ? const Icon(Icons.chevron_right, color: Colors.grey)
              : null),
      onTap: onTap,
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 56, endIndent: 0);
}
