import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/test_entry.dart';
import '../providers/auth_provider.dart';
import '../providers/test_provider.dart';
import '../widgets/ui.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId != null) await context.read<TestProvider>().loadTestEntries(userId);
  }

  @override
  Widget build(BuildContext context) {
    final tests = context.watch<TestProvider>();
    final all = tests.testEntries;
    final filtered = all.where((t) => t.testName.toLowerCase().contains(_query.toLowerCase())).toList();
    final analyzed = all.where((t) => t.analysis != null);
    final normal = analyzed.where((t) => !t.analysis!.needsAttention).length;
    final attention = analyzed.where((t) => t.analysis!.needsAttention).length;

    return AppShell(
      body: Column(
        children: [
          PageHeader(
            title: 'Test History',
            bottom: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Search tests...',
                prefixIcon: Icon(Icons.search, size: 20),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Row(
                    children: [
                      Expanded(child: _Stat(value: all.length, label: 'Total Tests')),
                      const SizedBox(width: 16),
                      Expanded(child: _Stat(value: normal, label: 'Normal', color: Tw.green600)),
                      const SizedBox(width: 16),
                      Expanded(child: _Stat(value: attention, label: 'Needs Attention', color: Tw.orange600)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (tests.isLoading && all.isEmpty)
                    const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()))
                  else if (filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        children: [
                          Icon(Icons.description_outlined, size: 48, color: Tw.gray400),
                          SizedBox(height: 12),
                          Text('No tests found', style: TextStyle(color: Tw.muted)),
                        ],
                      ),
                    )
                  else
                    for (final entry in filtered) ...[
                      _HistoryCard(entry: entry),
                      const SizedBox(height: 12),
                    ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _Stat({required this.value, required this.label, this.color = Tw.gray900});

  @override
  Widget build(BuildContext context) {
    return WhiteCard(
      child: Column(
        children: [
          Text('$value', style: TextStyle(fontSize: 24, color: color)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Tw.muted)),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final TestEntry entry;

  const _HistoryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final analysis = entry.analysis;
    final (riskBg, riskFg) = switch (analysis?.riskLevel) {
      'high' => (Tw.red100, Tw.red700),
      'moderate' => (Tw.orange100, Tw.orange600),
      'low' || 'normal' => (Tw.green100, Tw.green700),
      _ => (Tw.gray100, Tw.gray700),
    };

    return WhiteCard(
      onTap: analysis == null ? null : () => context.push('/home/results/${entry.id}', extra: entry),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconBox(icon: Icons.description_outlined, background: Tw.blue100, color: Tw.blue600),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(entry.testName, style: const TextStyle(fontSize: 16, color: Tw.gray900))),
                    if (analysis != null)
                      Pill(text: capitalize(analysis.riskLevel), background: riskBg, color: riskFg),
                  ],
                ),
                const SizedBox(height: 4),
                Text(formatDate(entry.createdAt), style: const TextStyle(fontSize: 14, color: Tw.muted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _Tag(
                      text: analysis != null ? 'completed' : 'pending',
                      background: analysis != null ? Tw.green100 : Tw.gray100,
                      color: analysis != null ? Tw.green700 : Tw.gray700,
                    ),
                    if (analysis != null)
                      _Tag(text: capitalize(analysis.category), background: Tw.gray100, color: Tw.gray700),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color background;
  final Color color;

  const _Tag({required this.text, required this.background, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(fontSize: 12, color: color)),
    );
  }
}
