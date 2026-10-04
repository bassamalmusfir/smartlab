import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/test_entry.dart';
import '../providers/test_provider.dart';
import '../widgets/ui.dart';

class TestResultsScreen extends StatelessWidget {
  final String? testId;
  // Passed directly when the test isn't one of the current user's own,
  // e.g. an admin opening another user's analysis.
  final TestEntry? entry;

  const TestResultsScreen({Key? key, this.testId, this.entry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final entry = this.entry ??
        context.watch<TestProvider>().testEntries.where((e) => e.id == testId).firstOrNull;
    final analysis = entry?.analysis;

    if (entry == null || analysis == null) {
      return const AppShell(
        body: Column(
          children: [
            PageHeader(title: 'Test Results'),
            Expanded(child: Center(child: Text('No analysis found for this test.'))),
          ],
        ),
      );
    }

    return AppShell(
      body: Column(
        children: [
          PageHeader(title: entry.testName, subtitle: formatDate(entry.createdAt)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Tw.blue600, Tw.indigo600],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text('AI Analysis Summary', style: TextStyle(fontSize: 16, color: Colors.white)),
                          ),
                          Pill(
                            text: 'Risk: ${capitalize(analysis.riskLevel)}',
                            background: Colors.white.withOpacity(0.2),
                            color: Colors.white,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${analysis.summary}\n\n${analysis.interpretation}',
                        style: const TextStyle(fontSize: 14, height: 1.6, color: Tw.blue100),
                      ),
                    ],
                  ),
                ),
                if (entry.values.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text('Test Parameters', style: TextStyle(fontSize: 18, color: Tw.gray900)),
                  const SizedBox(height: 16),
                  for (final value in entry.values) ...[
                    _ParameterCard(value: value),
                    const SizedBox(height: 16),
                  ],
                ],
                if (analysis.recommendations.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  WhiteCard(
                    border: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Recommendations', style: TextStyle(fontSize: 16, color: Tw.gray900)),
                        const SizedBox(height: 12),
                        for (final r in analysis.recommendations)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(Icons.check_circle_outline, size: 16, color: Tw.blue600),
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(r, style: const TextStyle(fontSize: 14, color: Tw.gray700))),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                if (analysis.dietary != null && analysis.dietary!.categories.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  BigButton(
                    label: 'View Dietary Recommendations',
                    color: Tw.green600,
                    onPressed: () => context.push('/home/dietary', extra: entry),
                  ),
                ],
                const SizedBox(height: 24),
                const Text(
                  'This analysis is generated by AI for information only and is not a medical diagnosis. '
                  'Please discuss your results with a doctor.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Tw.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParameterCard extends StatelessWidget {
  final TestValue value;

  const _ParameterCard({required this.value});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = switch (value.status) {
      'normal' => (Tw.green100, Tw.green700, Icons.check_circle_outline),
      'low' => (Tw.yellow100, Tw.yellow700, Icons.error_outline),
      'high' => (Tw.red100, Tw.red700, Icons.error_outline),
      _ => (Tw.gray100, Tw.gray700, Icons.info_outline),
    };
    final range = value.referenceRange ?? '';

    return WhiteCard(
      border: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value.name, style: const TextStyle(fontSize: 16, color: Tw.gray900)),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        text: value.value,
                        style: const TextStyle(fontSize: 24, color: Tw.gray900),
                        children: [
                          TextSpan(text: '  ${value.unit}', style: const TextStyle(fontSize: 14, color: Tw.muted)),
                        ],
                      ),
                    ),
                    if (range.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Normal: $range ${value.unit}'.trim(), style: const TextStyle(fontSize: 14, color: Tw.muted)),
                      ),
                  ],
                ),
              ),
              Pill(text: capitalize(value.status), background: bg, color: fg, icon: icon),
            ],
          ),
          if (value.explanation != null && value.explanation!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Tw.gray50, borderRadius: BorderRadius.circular(8)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.info_outline, size: 16, color: Tw.blue600),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(value.explanation!, style: const TextStyle(fontSize: 14, color: Tw.gray700)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
