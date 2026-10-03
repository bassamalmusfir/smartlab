import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/test_provider.dart';
import '../services/api_service.dart';

class NewTestScreen extends StatefulWidget {
  const NewTestScreen({Key? key}) : super(key: key);

  @override
  State<NewTestScreen> createState() => _NewTestScreenState();
}

class _NewTestScreenState extends State<NewTestScreen> {
  final _testNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<PlatformFile> _attachments = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _testNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachments() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    setState(() {
      _attachments.addAll(picked.where(
        (f) => !_attachments.any((existing) => existing.name == f.name),
      ));
    });
  }

  void _removeAttachment(PlatformFile file) {
    setState(() => _attachments.remove(file));
  }

  Future<void> _handleSubmit() async {
    if (_testNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a test name')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first')),
      );
      return;
    }

    if (_attachments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attach your lab report (PDF or image) to analyze it')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final testProvider = context.read<TestProvider>();

    final files = <AnalysisFile>[
      for (final file in _attachments) AnalysisFile(file.name, await file.readAsBytes()),
    ];

    final entryId = await testProvider.analyzeAndSaveFiles(
      userId: userId,
      testName: _testNameController.text.trim(),
      description: _descriptionController.text.trim(),
      files: files,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (entryId != null) {
      context.go('/home/results/$entryId');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(testProvider.error ?? 'Analysis failed')),
      );
    }
  }

  IconData _iconFor(String fileName) {
    return fileName.toLowerCase().endsWith('.pdf') ? Icons.picture_as_pdf : Icons.image;
  }

  String? _formatSize(int? bytes) {
    if (bytes == null) return null;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Test Entry'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Name',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _testNameController,
              decoration: InputDecoration(
                hintText: 'e.g., Complete Blood Count',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Optional notes',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Attach Test Report (PDF or Image)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickAttachments,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.cardBorder),
                  borderRadius: BorderRadius.circular(8),
                  color: AppTheme.backgroundWhite,
                ),
                child: Column(
                  children: [
                    Icon(Icons.cloud_upload_outlined, size: 32, color: AppTheme.textSecondary),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to upload PDF or image',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            if (_attachments.isNotEmpty) ...[
              const SizedBox(height: 16),
              ..._attachments.map(
                (file) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.cardBorder),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(_iconFor(file.name), color: AppTheme.primaryBlue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(file.name, overflow: TextOverflow.ellipsis),
                            if (_formatSize(file.lengthSync()) case final size?)
                              Text(
                                size,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: _isSubmitting ? null : () => _removeAttachment(file),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                child: _isSubmitting
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Analyzing… this can take a minute'),
                        ],
                      )
                    : const Text('Analyze Test'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
