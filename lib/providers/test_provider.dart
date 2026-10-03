import 'package:flutter/material.dart';
import '../models/test_entry.dart';
import '../models/test_result.dart';
import '../services/firebase_service.dart';
import '../services/api_service.dart';

class TestProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final ApiService _apiService = ApiService();

  List<TestEntry> _testEntries = [];
  TestResultAnalysis? _currentResult;
  bool _isLoading = false;
  String? _error;
  int _remainingAnalyses = 10;
  int _totalAnalyses = 10;

  // Getters
  List<TestEntry> get testEntries => _testEntries;
  TestResultAnalysis? get currentResult => _currentResult;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get remainingAnalyses => _remainingAnalyses;
  int get totalAnalyses => _totalAnalyses;

  // Load test entries
  Future<void> loadTestEntries(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final entries = await _firebaseService.getTestEntries(userId);
      _testEntries = entries;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save test entry
  Future<bool> saveTestEntry({
    required String userId,
    required String testName,
    required String description,
    required List<TestValue> values,
    required List<String> attachmentUrls,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final entry = TestEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        testName: testName,
        description: description.isNotEmpty ? description : null,
        values: values,
        attachmentUrls: attachmentUrls,
        createdAt: DateTime.now(),
      );

      await _firebaseService.saveTestEntry(entry);
      _testEntries.insert(0, entry);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Has the AI read the report files, then saves the test with its analysis.
  // Returns the saved entry's id, or null on failure (see [error]).
  Future<String?> analyzeAndSaveFiles({
    required String userId,
    required String testName,
    required String description,
    required List<AnalysisFile> files,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final entryId = DateTime.now().millisecondsSinceEpoch.toString();
    try {
      final result = await _apiService.analyzeFiles(
        testEntryId: entryId,
        testName: testName,
        files: files,
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
      _currentResult = result.analysis;
      if (_remainingAnalyses > 0) _remainingAnalyses--;
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

  // Analyze test
  Future<bool> analyzeTest({
    required String testName,
    required List<TestValue> values,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.analyzeTest(
        testName: testName,
        values: values,
      );

      _currentResult = result;

      // Decrement remaining analyses
      if (_remainingAnalyses > 0) {
        _remainingAnalyses--;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Analyze image
  Future<bool> analyzeImage({
    required String imageUrl,
    required String testName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.analyzeImage(
        imageUrl: imageUrl,
        testName: testName,
      );

      _currentResult = result;

      // Decrement remaining analyses
      if (_remainingAnalyses > 0) {
        _remainingAnalyses--;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get dietary recommendations
  Future<List<String>> getDietaryRecommendations(List<TestValue> values) async {
    try {
      return await _apiService.getDietaryRecommendations(testValues: values);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Clear current result
  void clearCurrentResult() {
    _currentResult = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Reset remaining analyses (mock - normally from server)
  void resetRemainingAnalyses() {
    _remainingAnalyses = _totalAnalyses;
    notifyListeners();
  }

  // Set remaining analyses
  void setRemainingAnalyses(int count) {
    _remainingAnalyses = count;
    notifyListeners();
  }
}
