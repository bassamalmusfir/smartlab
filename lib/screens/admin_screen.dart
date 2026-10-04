import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/test_entry.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _firebaseService = FirebaseService();

  List<UserModel> _users = [];
  List<TestEntry> _entries = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _firebaseService.getAllUsers(),
        _firebaseService.getAllTestEntries(),
      ]);
      _users = (results[0] as List<UserModel>)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _entries = (results[1] as List<TestEntry>)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      _error = 'Could not load admin data: $e';
    }
    if (mounted) setState(() => _isLoading = false);
  }

  String _usernameFor(String userId) {
    return _users.where((u) => u.id == userId).firstOrNull?.username ?? 'Unknown user';
  }

  Future<void> _editLimit(UserModel user) async {
    final controller = TextEditingController(text: user.analysisLimit.toString());
    final newLimit = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Analysis limit for ${user.username}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Used so far: ${user.analysesUsed}'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Total analyses allowed'),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, int.tryParse(controller.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newLimit == null || newLimit == user.analysisLimit) return;

    try {
      await _firebaseService.setAnalysisLimit(user.id, newLimit);
      setState(() {
        _users = [
          for (final u in _users) u.id == user.id ? u.copyWith(analysisLimit: newLimit) : u,
        ];
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update the limit: $e')),
      );
    }
  }

  void _openEntry(TestEntry entry) {
    if (entry.analysis == null) return;
    context.push('/home/results/${entry.id}', extra: entry);
  }

  @override
  Widget build(BuildContext context) {
    if (!context.watch<AuthProvider>().isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Panel')),
        body: const Center(child: Text('This page is only available to admins.')),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isLoading ? null : _load,
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Statistics'),
              Tab(text: 'Users'),
              Tab(text: 'Tests'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_error!, textAlign: TextAlign.center),
                    ),
                  )
                : TabBarView(
                    children: [
                      _StatsTab(users: _users, entries: _entries),
                      _UsersTab(users: _users, entries: _entries, onEditLimit: _editLimit, onOpenEntry: _openEntry),
                      _TestsTab(entries: _entries, usernameFor: _usernameFor, onOpenEntry: _openEntry),
                    ],
                  ),
      ),
    );
  }
}

class _StatsTab extends StatelessWidget {
  final List<UserModel> users;
  final List<TestEntry> entries;

  const _StatsTab({required this.users, required this.entries});

  @override
  Widget build(BuildContext context) {
    final analyzed = entries.where((e) => e.analysis != null).toList();
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final riskCounts = {
      for (final level in ['low', 'normal', 'moderate', 'high'])
        level: analyzed.where((e) => e.analysis!.riskLevel == level).length,
    };

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _StatCard(label: 'Users', value: users.length),
            _StatCard(label: 'New users (7 days)', value: users.where((u) => u.createdAt.isAfter(weekAgo)).length),
            _StatCard(label: 'Analyses', value: analyzed.length),
            _StatCard(label: 'Analyses (7 days)', value: analyzed.where((e) => e.createdAt.isAfter(weekAgo)).length),
          ],
        ),
        const SizedBox(height: 32),
        Text('Results by risk level', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        for (final entry in riskCounts.entries)
          _RiskBar(
            label: entry.key,
            count: entry.value,
            total: analyzed.length,
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        border: Border.all(color: AppTheme.cardBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$value', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _RiskBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;

  const _RiskBar({required this.label, required this.count, required this.total});

  Color get _color {
    switch (label) {
      case 'low':
        return AppTheme.successGreen;
      case 'normal':
        return const Color(0xFF0EA5E9);
      case 'moderate':
        return AppTheme.warningOrange;
      default:
        return AppTheme.destructiveRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text('${label[0].toUpperCase()}${label.substring(1)}'),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : count / total,
                minHeight: 10,
                backgroundColor: AppTheme.divider,
                valueColor: AlwaysStoppedAnimation<Color>(_color),
              ),
            ),
          ),
          SizedBox(width: 40, child: Text('$count', textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

class _UsersTab extends StatelessWidget {
  final List<UserModel> users;
  final List<TestEntry> entries;
  final void Function(UserModel) onEditLimit;
  final void Function(TestEntry) onOpenEntry;

  const _UsersTab({
    required this.users,
    required this.entries,
    required this.onEditLimit,
    required this.onOpenEntry,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) return const Center(child: Text('No users yet.'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final userEntries = entries.where((e) => e.userId == user.id).toList();
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Text(user.username),
            subtitle: Text('${user.email} · age ${user.age}'),
            trailing: TextButton(
              onPressed: () => onEditLimit(user),
              child: Text('${user.analysesUsed} / ${user.analysisLimit}'),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Joined ${_formatDate(user.createdAt)} · ${userEntries.length} tests',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              if (userEntries.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text('No tests yet.'),
                ),
              for (final entry in userEntries)
                _EntryTile(entry: entry, onTap: () => onOpenEntry(entry)),
            ],
          ),
        );
      },
    );
  }
}

class _TestsTab extends StatelessWidget {
  final List<TestEntry> entries;
  final String Function(String userId) usernameFor;
  final void Function(TestEntry) onOpenEntry;

  const _TestsTab({required this.entries, required this.usernameFor, required this.onOpenEntry});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const Center(child: Text('No tests yet.'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: _EntryTile(
            entry: entry,
            subtitlePrefix: usernameFor(entry.userId),
            onTap: () => onOpenEntry(entry),
          ),
        );
      },
    );
  }
}

class _EntryTile extends StatelessWidget {
  final TestEntry entry;
  final String? subtitlePrefix;
  final VoidCallback onTap;

  const _EntryTile({required this.entry, this.subtitlePrefix, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final analysis = entry.analysis;
    final date = _formatDate(entry.createdAt);
    return ListTile(
      title: Text(entry.testName),
      subtitle: Text(subtitlePrefix == null ? date : '$subtitlePrefix · $date'),
      trailing: analysis == null
          ? const Text('Not analyzed')
          : Text(
              analysis.riskLevel,
              style: TextStyle(color: analysis.getRiskColor(), fontWeight: FontWeight.w600),
            ),
      onTap: analysis == null ? null : onTap,
    );
  }
}

String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
