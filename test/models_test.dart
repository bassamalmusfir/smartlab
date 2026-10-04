import 'package:flutter_test/flutter_test.dart';
import 'package:smartlab/models/test_entry.dart';
import 'package:smartlab/models/test_result.dart';
import 'package:smartlab/models/user.dart';

void main() {
  test('UserModel gives accounts created before quotas the default limit', () {
    final user = UserModel.fromJson({
      'id': 'u1',
      'email': 'a@b.com',
      'username': 'a',
      'age': 30,
      'createdAt': '2026-10-01T00:00:00.000Z',
    });

    expect(user.analysisLimit, UserModel.defaultAnalysisLimit);
    expect(user.analysesUsed, 0);
    expect(user.remainingAnalyses, UserModel.defaultAnalysisLimit);
  });

  test('UserModel remaining analyses never goes below zero', () {
    final user = UserModel(
      id: 'u1',
      email: 'a@b.com',
      username: 'a',
      age: 30,
      createdAt: DateTime.utc(2026),
      analysisLimit: 5,
      analysesUsed: 7,
    );

    expect(user.remainingAnalyses, 0);
  });

  final analysisJson = {
    'id': 'a1',
    'testEntryId': 'e1',
    'summary': 'Mild anemia.',
    'interpretation': 'Hemoglobin is slightly below the reference range.',
    'insights': ['Hemoglobin is low'],
    'recommendations': ['Discuss iron levels with your doctor'],
    'riskLevel': 'moderate',
    'createdAt': '2026-10-01T10:00:00.000Z',
  };

  test('TestResultAnalysis parses the analysis server response', () {
    final analysis = TestResultAnalysis.fromJson(analysisJson);

    expect(analysis.riskLevel, 'moderate');
    expect(analysis.insights, ['Hemoglobin is low']);
    expect(analysis.createdAt, DateTime.utc(2026, 10, 1, 10));
  });

  test('TestValue defaults status to unknown when missing', () {
    final value = TestValue.fromJson({'id': 'v1', 'name': 'Glucose', 'value': '90', 'unit': 'mg/dL'});

    expect(value.status, 'unknown');
    expect(value.referenceRange, isNull);
  });

  test('TestEntry survives a Firestore JSON round trip with its analysis', () {
    final entry = TestEntry(
      id: 'e1',
      userId: 'u1',
      testName: 'CBC',
      values: [
        TestValue(
          id: 'e1_0',
          name: 'Hemoglobin',
          value: '11.2',
          unit: 'g/dL',
          referenceRange: '12.0-15.5',
          status: 'low',
        ),
      ],
      attachmentUrls: const [],
      createdAt: DateTime.utc(2026, 10, 1),
      isAnalyzed: true,
      analysis: TestResultAnalysis.fromJson(analysisJson),
    );

    final restored = TestEntry.fromJson(entry.toJson());

    expect(restored.testName, 'CBC');
    expect(restored.values.single.status, 'low');
    expect(restored.values.single.referenceRange, '12.0-15.5');
    expect(restored.analysis?.summary, 'Mild anemia.');
    expect(restored.isAnalyzed, isTrue);
  });

  test('TestResultAnalysis keeps the dietary plan through a round trip', () {
    final analysis = TestResultAnalysis.fromJson({
      ...analysisJson,
      'category': 'blood',
      'dietary': {
        'categories': [
          {
            'title': 'Iron-Rich Foods',
            'kind': 'iron',
            'reason': 'Based on your low hemoglobin',
            'foods': [
              {'name': 'Spinach', 'benefit': 'Rich in iron'},
            ],
          },
        ],
        'proTip': 'Pair iron with vitamin C.',
      },
    });

    final restored = TestResultAnalysis.fromJson(analysis.toJson());

    expect(restored.category, 'blood');
    expect(restored.needsAttention, isTrue);
    expect(restored.dietary!.categories.single.foods.single.name, 'Spinach');
    expect(restored.dietary!.proTip, 'Pair iron with vitamin C.');
  });

  test('UserModel fills in default notification preferences', () {
    final user = UserModel.fromJson({
      'id': 'u1',
      'email': 'a@b.com',
      'username': 'sam',
      'age': 30,
      'createdAt': '2026-10-01T00:00:00.000Z',
      'notificationPrefs': {'promotions': true},
      'firstName': 'Sara',
    });

    expect(user.notificationPrefs['promotions'], isTrue);
    expect(user.notificationPrefs['labResults'], isTrue);
    expect(user.displayName, 'Sara');
  });

  test('TestEntry without an analysis parses with a null analysis', () {
    final json = {
      'id': 'e2',
      'userId': 'u1',
      'testName': 'Lipid panel',
      'values': [],
      'attachmentUrls': [],
      'createdAt': '2026-10-01T00:00:00.000Z',
    };

    expect(TestEntry.fromJson(json).analysis, isNull);
  });
}
