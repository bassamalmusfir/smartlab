import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/test_entry.dart';
import '../models/test_result.dart';
import '../providers/auth_provider.dart';
import '../providers/test_provider.dart';
import '../widgets/ui.dart';

class DietaryRecommendationsScreen extends StatefulWidget {
  // The test to base recommendations on; defaults to the latest analyzed test.
  final TestEntry? entry;

  const DietaryRecommendationsScreen({Key? key, this.entry}) : super(key: key);

  @override
  State<DietaryRecommendationsScreen> createState() => _DietaryRecommendationsScreenState();
}

class _DietaryRecommendationsScreenState extends State<DietaryRecommendationsScreen> {
  int? _expanded = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tests = context.read<TestProvider>();
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (widget.entry == null && tests.testEntries.isEmpty && userId != null) {
        tests.loadTestEntries(userId);
      }
    });
  }

  static (IconData, Color, Color) _style(String kind) => switch (kind) {
        'iron' => (Icons.apple, Tw.red100, Tw.red600),
        'omega3' => (Icons.set_meal_outlined, Tw.blue100, Tw.blue600),
        'fiber' => (Icons.eco_outlined, Tw.orange100, Tw.orange600),
        'hydration' => (Icons.water_drop_outlined, Tw.cyan100, Tw.cyan600),
        'protein' => (Icons.egg_outlined, Tw.indigo100, Tw.indigo600),
        'calcium' => (Icons.local_drink_outlined, Tw.blue100, Tw.blue600),
        'vitamins' => (Icons.spa_outlined, Tw.green100, Tw.green600),
        'limit' => (Icons.cookie_outlined, Tw.gray100, Tw.gray600),
        _ => (Icons.restaurant_outlined, Tw.gray100, Tw.gray600),
      };

  @override
  Widget build(BuildContext context) {
    final tests = context.watch<TestProvider>();
    final source = widget.entry ??
        tests.testEntries.where((e) => e.analysis?.dietary?.categories.isNotEmpty ?? false).firstOrNull;
    final plan = source?.analysis?.dietary;

    return AppShell(
      body: Column(
        children: [
          const PageHeader(title: 'Dietary Recommendations'),
          Expanded(
            child: tests.isLoading && plan == null
                ? const Center(child: CircularProgressIndicator())
                : plan == null || plan.categories.isEmpty
                    ? const _EmptyState()
                    : _PlanView(
                        plan: plan,
                        testName: source!.testName,
                        expanded: _expanded,
                        onToggle: (i) => setState(() => _expanded = _expanded == i ? null : i),
                        styleFor: _style,
                      ),
          ),
        ],
      ),
    );
  }
}

class _PlanView extends StatelessWidget {
  final DietaryPlan plan;
  final String testName;
  final int? expanded;
  final ValueChanged<int> onToggle;
  final (IconData, Color, Color) Function(String) styleFor;

  const _PlanView({
    required this.plan,
    required this.testName,
    required this.expanded,
    required this.onToggle,
    required this.styleFor,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Tw.green600, Tw.emerald600],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Personalized Nutrition Plan', style: TextStyle(fontSize: 18, color: Colors.white)),
              const SizedBox(height: 8),
              Text(
                'Based on your $testName results, here are dietary recommendations to help optimize your health.',
                style: const TextStyle(fontSize: 14, color: Tw.green100),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        for (var i = 0; i < plan.categories.length; i++) ...[
          _CategoryCard(
            category: plan.categories[i],
            style: styleFor(plan.categories[i].kind),
            open: expanded == i,
            onTap: () => onToggle(i),
          ),
          const SizedBox(height: 12),
        ],
        if (plan.proTip.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Tw.blue50,
              border: Border.all(color: Tw.blue200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pro Tip', style: TextStyle(fontSize: 16, color: Tw.blue900)),
                const SizedBox(height: 8),
                Text(plan.proTip, style: const TextStyle(fontSize: 14, color: Tw.blue700)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        const Text(
          'General guidance, not a medical prescription. Check with your doctor before major diet changes.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Tw.muted),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final DietaryCategory category;
  final (IconData, Color, Color) style;
  final bool open;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.style, required this.open, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (icon, bg, fg) = style;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Tw.gray200),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconBox(icon: icon, background: bg, color: fg),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(category.title, style: const TextStyle(fontSize: 16, color: Tw.gray900)),
                        Text(category.reason, style: const TextStyle(fontSize: 14, color: Tw.muted)),
                      ],
                    ),
                  ),
                  Icon(open ? Icons.expand_less : Icons.expand_more, color: Tw.gray400),
                ],
              ),
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  for (final food in category.foods)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Tw.gray50, borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(food.name, style: const TextStyle(fontSize: 16, color: Tw.gray900)),
                          const SizedBox(height: 4),
                          Text(food.benefit, style: const TextStyle(fontSize: 14, color: Tw.muted)),
                        ],
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const IconBox(icon: Icons.apple, background: Tw.green100, color: Tw.green600, size: 32, padding: 16),
            const SizedBox(height: 16),
            const Text('No recommendations yet', style: TextStyle(fontSize: 18, color: Tw.gray900)),
            const SizedBox(height: 8),
            const Text(
              'Analyze a lab test and we\'ll create a nutrition plan based on your results.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Tw.muted),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.push('/home/new-test'),
              child: const Text('New Test'),
            ),
          ],
        ),
      ),
    );
  }
}
