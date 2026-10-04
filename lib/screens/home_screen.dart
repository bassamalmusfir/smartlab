import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/test_entry.dart';
import '../providers/auth_provider.dart';
import '../providers/test_provider.dart';
import '../widgets/ui.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) context.read<TestProvider>().loadTestEntries(user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tests = context.watch<TestProvider>();
    final user = auth.currentUser;
    final remaining = user?.remainingAnalyses ?? 0;
    final limit = user?.analysisLimit ?? 0;
    final insight = tests.latestAnalyzed?.analysis;

    return AppShell(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.headerGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 48, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Welcome back,', style: TextStyle(fontSize: 24, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text(user?.displayName ?? '', style: const TextStyle(fontSize: 16, color: Tw.blue100)),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => context.go('/home/profile'),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                        child: Text(user?.initial ?? '?', style: const TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.bolt, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Remaining Analyses', style: TextStyle(fontSize: 12, color: Tw.blue100)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      value: limit == 0 ? 0 : remaining / limit,
                                      minHeight: 8,
                                      backgroundColor: Colors.white.withOpacity(0.2),
                                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('$remaining / $limit', style: const TextStyle(fontSize: 14, color: Colors.white)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                WhiteCard(
                  radius: 16,
                  onTap: () => context.push('/home/new-test'),
                  child: const Row(
                    children: [
                      IconBox(icon: Icons.science_outlined, background: Tw.blue100, color: Tw.blue600, size: 28),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('New Test', style: TextStyle(fontSize: 16, color: Tw.gray900)),
                            Text(
                              'Enter lab values or scan medical images',
                              style: TextStyle(fontSize: 12, color: Tw.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _QuickButton(
                        icon: Icons.apple,
                        label: 'Dietary Tips',
                        background: Tw.green100,
                        color: Tw.green600,
                        onTap: () => context.push('/home/dietary'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickButton(
                        icon: Icons.schedule,
                        label: 'History',
                        background: Tw.orange100,
                        color: Tw.orange600,
                        onTap: () => context.go('/home/history'),
                      ),
                    ),
                  ],
                ),
                if (auth.isAdmin) ...[
                  const SizedBox(height: 12),
                  WhiteCard(
                    radius: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    onTap: () => context.push('/home/admin'),
                    child: const Row(
                      children: [
                        Icon(Icons.admin_panel_settings_outlined, color: Tw.indigo600),
                        SizedBox(width: 12),
                        Expanded(child: Text('Admin Panel', style: TextStyle(color: Tw.gray900))),
                        Icon(Icons.chevron_right, color: Tw.gray400),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Recent Tests', style: TextStyle(fontSize: 18, color: Tw.gray900)),
                    ),
                    TextButton(
                      onPressed: () => context.go('/home/history'),
                      child: const Text('View All', style: TextStyle(fontSize: 14, color: Tw.blue600)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (tests.isLoading && tests.testEntries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (tests.testEntries.isEmpty)
                  const WhiteCard(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No tests yet. Tap New Test to analyze your first lab report.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Tw.muted),
                    ),
                  )
                else
                  for (final entry in tests.testEntries.take(3)) ...[
                    TestTile(entry: entry),
                    const SizedBox(height: 12),
                  ],
                if (insight != null && insight.insights.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: AppTheme.actionGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.trending_up, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Health Insights', style: TextStyle(fontSize: 16, color: Colors.white)),
                              const SizedBox(height: 4),
                              Text(
                                insight.insights.first,
                                style: const TextStyle(fontSize: 14, color: Tw.blue100),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final Color color;
  final VoidCallback onTap;

  const _QuickButton({
    required this.icon,
    required this.label,
    required this.background,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return WhiteCard(
      radius: 16,
      onTap: onTap,
      child: Column(
        children: [
          IconBox(icon: icon, background: background, color: color, size: 24),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 14, color: Tw.gray900)),
        ],
      ),
    );
  }
}

/// A test row as shown in Recent Tests.
class TestTile extends StatelessWidget {
  final TestEntry entry;

  const TestTile({Key? key, required this.entry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final analyzed = entry.analysis != null;
    return WhiteCard(
      onTap: analyzed ? () => context.push('/home/results/${entry.id}', extra: entry) : null,
      child: Row(
        children: [
          const IconBox(icon: Icons.description_outlined, background: Tw.blue100, color: Tw.blue600),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.testName, style: const TextStyle(fontSize: 16, color: Tw.gray900)),
                Text(formatDate(entry.createdAt), style: const TextStyle(fontSize: 14, color: Tw.muted)),
              ],
            ),
          ),
          Pill(
            text: analyzed ? 'Completed' : 'Pending',
            background: analyzed ? Tw.green100 : Tw.gray100,
            color: analyzed ? Tw.green700 : Tw.gray700,
          ),
        ],
      ),
    );
  }
}
