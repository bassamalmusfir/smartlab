import 'package:flutter/material.dart';
import '../models/test_entry.dart';
import '../services/firebase_service.dart';
import '../services/api_service.dart';

class TestProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final ApiService _apiService = ApiService();

  List<TestEntry> _testEntries = [];
  bool _isLoading = false;
  String? _error;

  List<TestEntry> get testEntries => _testEntries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Most recent analyzed test, used for dietary tips and health insights.
  TestEntry? get latestAnalyzed => _testEntries.where((e) => e.analysis != null).firstOrNull;

  Future<void> loadTestEntries(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _testEntries = await _firebaseService.getTestEntries(userId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  void clear() {
    _testEntries = [];
    _error = null;
    notifyListeners();
  }

  // Has the AI analyze the report and/or typed values, then saves the test.
  // Returns the saved entry's id, or null on failure (see [error]).
  Future<String?> analyzeAndSave({
    required String userId,
    required String testName,
    required String description,
    required List<AnalysisFile> files,
    required List<TypedValue> typedValues,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final entryId = DateTime.now().millisecondsSinceEpoch.toString();
    try {
      final result = await _apiService.analyze(
        testEntryId: entryId,
        testName: testName,
        description: description,
        files: files,
        typedValues: typedValues,
      );

      final entry = TestEntry(
        id: entryId,
        userId: userId,
        testName: testName,
        description: description.isNotEmpty ? description : null,
        values: result.values,
        attachmentUrls: const [],
        createdAt: DateTime.now(),
        isAnalyzed: true,
        analysis: result.analysis,
      );
      await _firebaseService.saveTestEntry(entry);

      _testEntries.insert(0, entry);
      _isLoading = false;
      notifyListeners();
      return entryId;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
}
