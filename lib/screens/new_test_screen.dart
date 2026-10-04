import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/test_provider.dart';
import '../services/api_service.dart';
import '../widgets/ui.dart';

class _PickedFile {
  final String name;
  final Uint8List bytes;

  _PickedFile(this.name, this.bytes);

  bool get isImage {
    final lower = name.toLowerCase();
    return lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg');
  }
}

class _ValueRow {
  final name = TextEditingController();
  final value = TextEditingController();
  final unit = TextEditingController();

  bool get isFilled => name.text.trim().isNotEmpty && value.text.trim().isNotEmpty;

  void dispose() {
    name.dispose();
    value.dispose();
    unit.dispose();
  }
}

class NewTestScreen extends StatefulWidget {
  const NewTestScreen({Key? key}) : super(key: key);

  @override
  State<NewTestScreen> createState() => _NewTestScreenState();
}

class _NewTestScreenState extends State<NewTestScreen> {
  static const _commonTests = [
    'Complete Blood Count',
    'Lipid Panel',
    'Thyroid Function',
    'Blood Glucose',
    'Liver Function',
    'Kidney Function',
  ];

  final _testNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<_PickedFile> _files = [];
  final List<_ValueRow> _values = [_ValueRow()];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _testNameController.dispose();
    _descriptionController.dispose();
    for (final v in _values) {
      v.dispose();
    }
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    final added = <_PickedFile>[];
    for (final f in picked) {
      if (_files.any((existing) => existing.name == f.name)) continue;
      added.add(_PickedFile(f.name, await f.readAsBytes()));
    }
    if (mounted && added.isNotEmpty) setState(() => _files.addAll(added));
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _analyze() async {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    final typedValues = [
      for (final v in _values.where((v) => v.isFilled))
        TypedValue(name: v.name.text.trim(), value: v.value.text.trim(), unit: v.unit.text.trim()),
    ];
    if (_files.isEmpty && typedValues.isEmpty) {
      _toast('Upload your report or enter at least one test value');
      return;
    }
    if (user.remainingAnalyses <= 0) {
      _toast('You have used all your analyses.');
      return;
    }

    setState(() => _isSubmitting = true);
    final tests = context.read<TestProvider>();
    final name = _testNameController.text.trim();

    final entryId = await tests.analyzeAndSave(
      userId: user.id,
      testName: name.isEmpty ? 'Lab Test' : name,
      description: _descriptionController.text.trim(),
      files: [for (final f in _files) AnalysisFile(f.name, f.bytes)],
      typedValues: typedValues,
    );

    if (entryId != null) {
      try {
        await auth.recordAnalysisUsed();
      } catch (e) {
        // The analysis is already saved; a failed count shouldn't hide it.
        debugPrint('Could not record analysis usage: $e');
      }
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (entryId != null) {
      context.go('/home/results/$entryId');
    } else {
      _toast(tests.error ?? 'Analysis failed');
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      body: Column(
        children: [
          const PageHeader(title: 'New Test Entry'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const FieldLabel('Test Name'),
                TextField(
                  controller: _testNameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g., Complete Blood Count',
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final test in _commonTests)
                      InkWell(
                        onTap: () => setState(() => _testNameController.text = test),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(color: Tw.blue50, borderRadius: BorderRadius.circular(999)),
                          child: Text(test, style: const TextStyle(fontSize: 14, color: Tw.blue700)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                const FieldLabel('Description', trailing: OptionalTag()),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Add any notes or context about this test (symptoms, concerns, etc.)',
                    fillColor: Colors.white,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Icon(Icons.notes, size: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const FieldLabel('Upload Files', trailing: OptionalTag()),
                _DashedBox(
                  onTap: _isSubmitting ? null : _pickFiles,
                  child: const Column(
                    children: [
                      IconBox(icon: Icons.upload_outlined, background: Tw.blue100, color: Tw.blue600, size: 24),
                      SizedBox(height: 12),
                      Text('Tap to upload your report', style: TextStyle(fontSize: 14, color: Tw.gray900)),
                      SizedBox(height: 4),
                      Text('Images (JPG, PNG) or PDF', style: TextStyle(fontSize: 12, color: Tw.muted)),
                    ],
                  ),
                ),
                for (final file in _files) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Tw.gray200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: file.isImage
                              ? Image.memory(file.bytes, width: 48, height: 48, fit: BoxFit.cover)
                              : Container(
                                  width: 48,
                                  height: 48,
                                  color: Tw.indigo50,
                                  child: const Icon(Icons.description_outlined, color: Tw.indigo500),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(file.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                              Text(_formatSize(file.bytes.length), style: const TextStyle(fontSize: 12, color: Tw.muted)),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: _isSubmitting ? null : () => setState(() => _files.remove(file)),
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(color: Tw.gray100, shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 16, color: Tw.gray500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: Text('Test Values', style: TextStyle(fontSize: 16, color: Tw.gray900))),
                    TextButton.icon(
                      onPressed: () => setState(() => _values.add(_ValueRow())),
                      icon: const Icon(Icons.add, size: 16, color: Tw.blue600),
                      label: const Text('Add Value', style: TextStyle(fontSize: 14, color: Tw.blue600)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                for (var i = 0; i < _values.length; i++) ...[
                  _ValueCard(
                    index: i,
                    row: _values[i],
                    onRemove: _values.length > 1
                        ? () => setState(() => _values.removeAt(i).dispose())
                        : null,
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 4),
                BigButton(
                  label: _isSubmitting ? 'Analyzing… this can take a minute' : 'Analyze with AI',
                  icon: Icons.auto_awesome,
                  gradient: AppTheme.actionGradient,
                  loading: _isSubmitting,
                  onPressed: _analyze,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Our AI will provide detailed analysis and explanations of your results',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Tw.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ValueCard extends StatelessWidget {
  final int index;
  final _ValueRow row;
  final VoidCallback? onRemove;

  const _ValueCard({required this.index, required this.row, this.onRemove});

  @override
  Widget build(BuildContext context) {
    const dense = InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Tw.gray200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text('Value ${index + 1}', style: const TextStyle(fontSize: 14, color: Tw.muted))),
              if (onRemove != null)
                InkWell(onTap: onRemove, child: const Icon(Icons.delete_outline, size: 16, color: Tw.red500)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: row.name,
            decoration: dense.copyWith(hintText: 'Parameter name (e.g., Hemoglobin)'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: TextField(controller: row.value, decoration: dense.copyWith(hintText: 'Value'))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: row.unit, decoration: dense.copyWith(hintText: 'Unit'))),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashedBox extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _DashedBox({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: Tw.blue50,
        child: CustomPaint(
          painter: _DashedBorderPainter(),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Tw.gray200
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)));
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
