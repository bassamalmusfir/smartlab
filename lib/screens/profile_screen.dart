import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/test_provider.dart';
import '../widgets/ui.dart';
import 'profile_sheets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    context.read<TestProvider>().clear();
    await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return const AppShell(body: Center(child: CircularProgressIndicator()));

    final menu = [
      (Icons.person_outline, 'Personal Information', () => showPersonalInfoSheet(context)),
      (Icons.notifications_none, 'Notifications', () => showNotificationsSheet(context)),
      (Icons.shield_outlined, 'Privacy & Security', () => showPrivacySheet(context)),
      (Icons.credit_card, 'Payment Methods', () => showPaymentSheet(context)),
      (Icons.help_outline, 'Help & Support', () => showHelpSheet(context)),
    ];

    return AppShell(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
            padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 48, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => goBack(context),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                      child: Text(user.initial, style: const TextStyle(fontSize: 24, color: Colors.white)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.displayName, style: const TextStyle(fontSize: 20, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text(user.email, style: const TextStyle(fontSize: 16, color: Tw.blue100)),
                          if (auth.isAdmin) ...[
                            const SizedBox(height: 8),
                            Pill(
                              text: 'Admin',
                              icon: Icons.admin_panel_settings_outlined,
                              background: Colors.white.withOpacity(0.2),
                              color: Colors.white,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WhiteCard(
                  radius: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Account Details', style: TextStyle(fontSize: 16, color: Tw.gray900)),
                      const SizedBox(height: 16),
                      _DetailRow(icon: Icons.mail_outline, label: 'Email', value: user.email),
                      _DetailRow(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: user.phone.isEmpty ? 'Not set' : user.phone,
                      ),
                      _DetailRow(icon: Icons.tag, label: 'Age', value: '${user.age} years old', last: true),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (var i = 0; i < menu.length; i++) ...[
                        if (i > 0) const Divider(height: 1, color: Tw.gray100),
                        InkWell(
                          onTap: menu[i].$3,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(menu[i].$1, size: 20, color: Tw.gray400),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(menu[i].$2, style: const TextStyle(fontSize: 16, color: Tw.gray900)),
                                ),
                                const Icon(Icons.chevron_right, color: Tw.gray400),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                WhiteCard(
                  radius: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Subscription', style: TextStyle(fontSize: 16, color: Tw.gray900)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Basic Plan', style: TextStyle(fontSize: 16, color: Tw.gray900)),
                                Text(
                                  '${user.remainingAnalyses} of ${user.analysisLimit} analyses left',
                                  style: const TextStyle(fontSize: 14, color: Tw.muted),
                                ),
                              ],
                            ),
                          ),
                          const Pill(text: 'Active', background: Tw.green100, color: Tw.green700),
                        ],
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => showSubscriptionSheet(context),
                        child: const Text('Manage Subscription', style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Material(
                  color: Tw.red50,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => _logout(context),
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, color: Tw.red600, size: 20),
                          SizedBox(width: 8),
                          Text('Logout', style: TextStyle(fontSize: 16, color: Tw.red600)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Version 1.0.0', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Tw.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool last;

  const _DetailRow({required this.icon, required this.label, required this.value, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: last ? 0 : 16),
      margin: EdgeInsets.only(bottom: last ? 0 : 16),
      decoration: last ? null : const BoxDecoration(border: Border(bottom: BorderSide(color: Tw.gray100))),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Tw.gray400),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, color: Tw.muted)),
                Text(value, style: const TextStyle(fontSize: 16, color: Tw.gray900)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
