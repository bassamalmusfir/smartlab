import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/test_provider.dart';
import '../widgets/ui.dart';

// ---------------------------------------------------------------- Personal info

Future<void> showPersonalInfoSheet(BuildContext context) {
  return showAppSheet(
    context,
    title: 'Personal Information',
    subtitle: 'Update your profile details',
    builder: (_) => const _PersonalInfoForm(),
  );
}

class _PersonalInfoForm extends StatefulWidget {
  const _PersonalInfoForm();

  @override
  State<_PersonalInfoForm> createState() => _PersonalInfoFormState();
}

class _PersonalInfoFormState extends State<_PersonalInfoForm> {
  late final UserModel _user = context.read<AuthProvider>().currentUser!;
  late final _first = TextEditingController(text: _user.firstName.isEmpty ? _user.username : _user.firstName);
  late final _last = TextEditingController(text: _user.lastName);
  late final _phone = TextEditingController(text: _user.phone);
  late final _age = TextEditingController(text: '${_user.age}');
  late final _city = TextEditingController(text: _user.city);
  late final _country = TextEditingController(text: _user.country);
  bool _saved = false;

  @override
  void dispose() {
    for (final c in [_first, _last, _phone, _age, _city, _country]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _phoneInvalid => _phone.text.isNotEmpty && _phone.text.length != 10;

  Future<void> _save() async {
    final age = int.tryParse(_age.text);
    if (_phoneInvalid || age == null || age <= 0 || age > 120) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.updateUserData(_user.copyWith(
      firstName: _first.text.trim(),
      lastName: _last.text.trim(),
      phone: _phone.text,
      age: age,
      city: _city.text.trim(),
      country: _country.text.trim(),
    ));
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.error ?? 'Could not save')));
      return;
    }
    setState(() => _saved = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) Navigator.of(context).pop();
  }

  Widget _input(String label, TextEditingController c, IconData icon,
      {bool enabled = true, TextInputType? type, List<TextInputFormatter>? formatters, String? hint, Widget? labelExtra}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label, small: true, trailing: labelExtra),
        TextField(
          controller: c,
          enabled: enabled,
          keyboardType: type,
          inputFormatters: formatters,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: c == _phone && _phoneInvalid ? Tw.red400 : Tw.gray200),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Tw.gray200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: c == _phone && _phoneInvalid ? Tw.red400 : Tw.blue500, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final saving = context.watch<AuthProvider>().isLoading;
    final initial = _first.text.isNotEmpty ? _first.text[0].toUpperCase() : _user.initial;
    const gap = SizedBox(height: 16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 80,
            height: 80,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Tw.blue500, Tw.indigo600]),
            ),
            child: Text(initial, style: const TextStyle(fontSize: 24, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: _input('First Name', _first, Icons.person_outline)),
            const SizedBox(width: 12),
            Expanded(child: _input('Last Name', _last, Icons.person_outline)),
          ],
        ),
        gap,
        _input('Email Address', TextEditingController(text: _user.email), Icons.mail_outline, enabled: false),
        gap,
        _input(
          'Phone Number',
          _phone,
          Icons.phone_outlined,
          type: TextInputType.phone,
          formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
          hint: '0000000000',
          labelExtra: _phoneInvalid
              ? const Text('— must be exactly 10 digits', style: TextStyle(fontSize: 12, color: Tw.red500))
              : null,
        ),
        gap,
        _input('Age', _age, Icons.tag,
            type: TextInputType.number, formatters: [FilteringTextInputFormatter.digitsOnly], hint: 'e.g. 25'),
        gap,
        Row(
          children: [
            Expanded(child: _input('City', _city, Icons.place_outlined)),
            const SizedBox(width: 12),
            Expanded(child: _input('Country', _country, Icons.place_outlined)),
          ],
        ),
        const SizedBox(height: 24),
        BigButton(
          label: _saved ? 'Saved!' : 'Save Changes',
          icon: _saved ? Icons.check : null,
          loading: saving && !_saved,
          onPressed: _phoneInvalid ? null : _save,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Notifications

Future<void> showNotificationsSheet(BuildContext context) {
  return showAppSheet(
    context,
    title: 'Notifications',
    subtitle: 'Manage your alert preferences',
    builder: (_) => const _NotificationsForm(),
  );
}

class _NotificationsForm extends StatefulWidget {
  const _NotificationsForm();

  @override
  State<_NotificationsForm> createState() => _NotificationsFormState();
}

class _NotificationsFormState extends State<_NotificationsForm> {
  late final Map<String, bool> _prefs = {...context.read<AuthProvider>().currentUser!.notificationPrefs};

  static const _groups = [
    ('General', [
      ('pushNotifications', Icons.smartphone, 'Push Notifications', 'Enable all push notifications'),
    ]),
    ('Health & Results', [
      ('labResults', Icons.description_outlined, 'Lab Results Ready', 'When your analysis is complete'),
      ('healthTips', Icons.trending_up, 'Health Insights', 'Personalized health tips'),
      ('testReminders', Icons.notifications_none, 'Test Reminders', 'Reminders for upcoming tests'),
      ('weeklyReport', Icons.trending_up, 'Weekly Report', 'Weekly health summary'),
    ]),
    ('Lifestyle', [
      ('dietaryReminders', Icons.restaurant, 'Dietary Reminders', 'Meal and nutrition reminders'),
    ]),
    ('Other', [
      ('promotions', Icons.local_offer_outlined, 'Offers & Promotions', 'Deals and special offers'),
      ('appUpdates', Icons.smartphone, 'App Updates', 'New features and improvements'),
    ]),
  ];

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.updateUserData(auth.currentUser!.copyWith(notificationPrefs: _prefs));
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.error ?? 'Could not save')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (title, items) in _groups) ...[
          SectionLabel(title),
          GroupBox(
            children: [
              for (final (key, icon, label, desc) in items)
                SettingRow(
                  icon: icon,
                  label: label,
                  description: desc,
                  active: _prefs[key] ?? false,
                  trailing: Switch(
                    value: _prefs[key] ?? false,
                    onChanged: (v) => setState(() => _prefs[key] = v),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
        ],
        BigButton(
          label: 'Save Preferences',
          loading: context.watch<AuthProvider>().isLoading,
          onPressed: _save,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Privacy

Future<void> showPrivacySheet(BuildContext context) {
  return showAppSheet(
    context,
    title: 'Privacy & Security',
    subtitle: 'Manage your account security',
    builder: (_) => const _PrivacyForm(),
  );
}

class _PrivacyForm extends StatefulWidget {
  const _PrivacyForm();

  @override
  State<_PrivacyForm> createState() => _PrivacyFormState();
}

class _PrivacyFormState extends State<_PrivacyForm> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  final _show = [false, false, false];
  bool _updated = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _ready => _current.text.isNotEmpty && _new.text.isNotEmpty && _confirm.text.isNotEmpty;

  Future<void> _updatePassword() async {
    setState(() => _error = null);
    if (_new.text != _confirm.text) {
      setState(() => _error = 'New passwords do not match');
      return;
    }
    if (_new.text.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.changePassword(currentPassword: _current.text, newPassword: _new.text);
    if (!mounted) return;
    if (!ok) {
      setState(() => _error = auth.error);
      return;
    }
    _current.clear();
    _new.clear();
    _confirm.clear();
    setState(() => _updated = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _updated = false);
  }

  Future<void> _deleteAccount() async {
    final password = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This permanently deletes your profile and all your test results. This cannot be undone.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Enter your password to confirm'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: Tw.red600)),
          ),
        ],
      ),
    );
    final pass = password.text;
    password.dispose();
    if (confirmed != true || pass.isEmpty || !mounted) return;

    final auth = context.read<AuthProvider>();
    final tests = context.read<TestProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await auth.deleteAccount(pass);
    if (ok) {
      tests.clear();
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Your account has been deleted')));
    } else {
      messenger.showSnackBar(SnackBar(content: Text(auth.error ?? 'Could not delete account')));
    }
  }

  Widget _passwordField(int i, TextEditingController c, String hint) {
    return TextField(
      controller: c,
      obscureText: !_show[i],
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.lock_outline, size: 16),
        suffixIcon: IconButton(
          icon: Icon(_show[i] ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 16),
          onPressed: () => setState(() => _show[i] = !_show[i]),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Tw.gray200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Tw.blue500, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strength = _new.text.isEmpty
        ? null
        : _new.text.length < 6
            ? ('Weak', Tw.red400, 0.25)
            : _new.text.length < 10
                ? ('Fair', const Color(0xFFFACC15), 0.5)
                : ('Strong', const Color(0xFF22C55E), 1.0);
    final loading = context.watch<AuthProvider>().isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Change Password'),
        _passwordField(0, _current, 'Current password'),
        const SizedBox(height: 12),
        _passwordField(1, _new, 'New password'),
        if (strength != null) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: strength.$3,
              minHeight: 6,
              backgroundColor: Tw.gray200,
              valueColor: AlwaysStoppedAnimation(strength.$2),
            ),
          ),
          const SizedBox(height: 4),
          Text('Password strength: ${strength.$1}', style: const TextStyle(fontSize: 12, color: Tw.muted)),
        ],
        const SizedBox(height: 12),
        _passwordField(2, _confirm, 'Confirm new password'),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(fontSize: 13, color: Tw.red600)),
        ],
        const SizedBox(height: 12),
        BigButton(
          label: _updated ? 'Password Updated!' : 'Update Password',
          icon: _updated ? Icons.check : null,
          color: _ready ? Tw.blue600 : Tw.gray100,
          textColor: _ready ? Colors.white : Tw.gray400,
          loading: loading && !_updated,
          onPressed: _ready ? _updatePassword : null,
        ),
        const SizedBox(height: 24),
        const SectionLabel('Data & Privacy'),
        GroupBox(
          children: [
            SettingRow(
              icon: Icons.delete_outline,
              label: 'Delete Account',
              description: 'Permanently remove your data',
              iconBackground: Tw.red100,
              iconColor: Tw.red500,
              labelColor: Tw.red600,
              trailing: const Icon(Icons.chevron_right, size: 16, color: Tw.gray400),
              onTap: loading ? null : _deleteAccount,
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Payment

Future<void> showPaymentSheet(BuildContext context) {
  return showAppSheet(
    context,
    title: 'Payment Methods',
    subtitle: 'Manage your payment cards',
    builder: (_) => const Column(
      children: [
        SizedBox(height: 16),
        IconBox(icon: Icons.credit_card, background: Tw.blue100, color: Tw.blue600, size: 28, padding: 16),
        SizedBox(height: 16),
        Text('No payment methods yet', style: TextStyle(fontSize: 16, color: Tw.gray900)),
        SizedBox(height: 8),
        Text(
          'Paid plans are coming soon. You\'ll be able to pay securely through the App Store or Google Play.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Tw.muted),
        ),
        SizedBox(height: 16),
      ],
    ),
  );
}

// ---------------------------------------------------------------- Help

const _faqs = [
  (
    'How does SmartLAB analyze my lab results?',
    'SmartLAB sends your report or the values you enter to an AI model, which reads each value, compares it with '
        'the reference range, and explains what it means in plain language.',
  ),
  (
    'Is my health data safe and private?',
    'Your data is sent over an encrypted connection and stored in your own account. Security rules ensure only '
        'you can read your results. We do not sell your data.',
  ),
  (
    'Can SmartLAB replace a doctor?',
    'No. SmartLAB is an informational tool to help you understand your results. Always consult a qualified '
        'healthcare professional for medical advice, diagnosis, or treatment.',
  ),
  (
    'Which types of tests can I analyze?',
    'Blood panels (CBC, lipids, glucose), hormone tests, organ function tests (liver, kidney), urinalysis, and '
        'medical images such as X-rays.',
  ),
  (
    'How do I upload a report or medical image?',
    'Tap New Test on the home screen, then tap the upload box and choose a photo or PDF of your report. You can '
        'also type values in by hand.',
  ),
  (
    'How do I delete my account?',
    'Open Profile, then Privacy & Security, then Delete Account. This removes your profile and all your results.',
  ),
];

Future<void> showHelpSheet(BuildContext context) {
  return showAppSheet(
    context,
    title: 'Help & Support',
    subtitle: 'We\'re here to help you',
    builder: (_) => const _HelpContent(),
  );
}

class _HelpContent extends StatefulWidget {
  const _HelpContent();

  @override
  State<_HelpContent> createState() => _HelpContentState();
}

class _HelpContentState extends State<_HelpContent> {
  bool _faqTab = true;
  int? _open;

  Widget _tab(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: active ? Tw.blue600 : Tw.gray100,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: active ? Colors.white : Tw.gray600),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _tab('FAQs', _faqTab, () => setState(() => _faqTab = true)),
            const SizedBox(width: 8),
            _tab('Contact Us', !_faqTab, () => setState(() => _faqTab = false)),
          ],
        ),
        const SizedBox(height: 16),
        if (_faqTab)
          for (var i = 0; i < _faqs.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Tw.gray50, borderRadius: BorderRadius.circular(16)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    onTap: () => setState(() => _open = _open == i ? null : i),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(color: Tw.blue100, shape: BoxShape.circle),
                            child: const Icon(Icons.menu_book_outlined, size: 12, color: Tw.blue600),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(_faqs[i].$1, style: const TextStyle(fontSize: 14, color: Tw.gray900))),
                          Icon(_open == i ? Icons.expand_less : Icons.expand_more, size: 16, color: Tw.gray400),
                        ],
                      ),
                    ),
                  ),
                  if (_open == i)
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Tw.gray100))),
                      child: Text(_faqs[i].$2, style: const TextStyle(fontSize: 14, height: 1.6, color: Tw.muted)),
                    ),
                ],
              ),
            )
        else ...[
          GroupBox(
            children: [
              SettingRow(
                icon: Icons.mail_outline,
                label: 'Email Support',
                description: 'support@smartlab.app',
                trailing: IconButton(
                  icon: const Icon(Icons.copy, size: 16, color: Tw.gray400),
                  tooltip: 'Copy email',
                  onPressed: () {
                    Clipboard.setData(const ClipboardData(text: 'support@smartlab.app'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Email address copied')),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Tw.amber50,
              border: Border.all(color: Tw.amber100),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'For medical emergencies, call your local emergency number immediately (997 in Saudi Arabia).',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Tw.amber700),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------- Subscription

Future<void> showSubscriptionSheet(BuildContext context) {
  final limit = context.read<AuthProvider>().currentUser?.analysisLimit ?? UserModel.defaultAnalysisLimit;
  return showAppSheet(
    context,
    title: 'Choose Your Plan',
    subtitle: 'Upgrade or change anytime',
    builder: (_) => _SubscriptionContent(basicLimit: limit),
  );
}

class _Plan {
  final String id;
  final String name;
  final String price;
  final String period;
  final IconData icon;
  final Color color;
  final Color background;
  final Color border;
  final bool popular;
  final List<String> features;

  const _Plan(this.id, this.name, this.price, this.period, this.icon, this.color, this.background, this.border,
      this.popular, this.features);
}

class _SubscriptionContent extends StatefulWidget {
  final int basicLimit;

  const _SubscriptionContent({required this.basicLimit});

  @override
  State<_SubscriptionContent> createState() => _SubscriptionContentState();
}

class _SubscriptionContentState extends State<_SubscriptionContent> {
  String _selected = 'basic';

  List<_Plan> get _plans => [
        _Plan('basic', 'Basic', 'Free', '', Icons.bolt, Tw.gray600, Tw.gray100, Tw.gray200, false, [
          '${widget.basicLimit} lab analyses',
          'AI result interpretation',
          'Dietary recommendations',
          'Full test history',
        ]),
        const _Plan('pro', 'Pro', '\$9.99', '/month', Icons.star_border, Tw.blue600, Tw.blue100, Tw.blue300, true, [
          '50 lab analyses per month',
          'Medical image analysis',
          'Personalized dietary plans',
          'Priority support',
        ]),
        const _Plan('premium', 'Premium', '\$19.99', '/month', Icons.workspace_premium_outlined, Tw.indigo600,
            Tw.indigo100, Tw.indigo500, false, [
          'Unlimited lab analyses',
          'Unlimited medical image analysis',
          'Personalized dietary plans',
          'Family profiles (up to 5)',
        ]),
      ];

  @override
  Widget build(BuildContext context) {
    final changed = _selected != 'basic';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final plan in _plans) ...[
          InkWell(
            onTap: () => setState(() => _selected = plan.id),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _selected == plan.id ? plan.border : Tw.gray100, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: plan.background, borderRadius: BorderRadius.circular(12)),
                        child: Icon(plan.icon, size: 20, color: plan.color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(plan.name, style: const TextStyle(fontSize: 16, color: Tw.gray900)),
                                if (plan.popular)
                                  const Pill(text: 'Popular', background: Tw.blue600, color: Colors.white),
                                if (plan.id == 'basic')
                                  const Pill(text: 'Current', background: Tw.gray100, color: Tw.gray700),
                              ],
                            ),
                            Text.rich(
                              TextSpan(
                                text: plan.price,
                                style: TextStyle(fontSize: 20, color: plan.color),
                                children: [
                                  TextSpan(text: plan.period, style: const TextStyle(fontSize: 14, color: Tw.muted)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _selected == plan.id ? Tw.blue600 : Colors.transparent,
                          border: Border.all(color: _selected == plan.id ? Tw.blue600 : Tw.gray300, width: 2),
                        ),
                        child: _selected == plan.id ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (final f in plan.features)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(color: Tw.green100, shape: BoxShape.circle),
                            child: const Icon(Icons.check, size: 10, color: Tw.green600),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(f, style: const TextStyle(fontSize: 14, color: Tw.gray700))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        const SizedBox(height: 8),
        BigButton(
          label: changed ? 'Coming soon' : 'Current Plan Selected',
          color: Tw.gray100,
          textColor: Tw.gray400,
          onPressed: null,
        ),
        const SizedBox(height: 12),
        Text(
          changed
              ? 'Paid plans are not available yet. We\'ll let you know when they launch.'
              : 'Cancel anytime. No hidden fees.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Tw.muted),
        ),
      ],
    );
  }
}
