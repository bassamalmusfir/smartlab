import 'test_result.dart';

class TestValue {
  final String id;
  final String name;
  final String value;
  final String unit;
  final String? referenceRange;
  final String status; // 'low', 'normal', 'high', 'unknown'

  TestValue({
    required this.id,
    required this.name,
    required this.value,
    required this.unit,
    this.referenceRange,
    this.status = 'unknown',
  });

  factory TestValue.fromJson(Map<String, dynamic> json) {
    return TestValue(
      id: json['id'] as String,
      name: json['name'] as String,
      value: json['value'] as String,
      unit: json['unit'] as String,
      referenceRange: json['referenceRange'] as String?,
      status: json['status'] as String? ?? 'unknown',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'value': value,
    'unit': unit,
    'referenceRange': referenceRange,
    'status': status,
  };

  TestValue copyWith({
    String? id,
    String? name,
    String? value,
    String? unit,
    String? referenceRange,
    String? status,
  }) {
    return TestValue(
      id: id ?? this.id,
      name: name ?? this.name,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      referenceRange: referenceRange ?? this.referenceRange,
      status: status ?? this.status,
    );
  }
}

class TestEntry {
  final String id;
  final String userId;
  final String testName;
  final String? description;
  final List<TestValue> values;
  final List<String> attachmentUrls;
  final DateTime createdAt;
  final bool isAnalyzed;
  final TestResultAnalysis? analysis;

  TestEntry({
    required this.id,
    required this.userId,
    required this.testName,
    this.description,
    required this.values,
    required this.attachmentUrls,
    required this.createdAt,
    this.isAnalyzed = false,
    this.analysis,
  });

  factory TestEntry.fromJson(Map<String, dynamic> json) {
    return TestEntry(
      id: json['id'] as String,
      userId: json['userId'] as String,
      testName: json['testName'] as String,
      description: json['description'] as String?,
      values: (json['values'] as List?)
          ?.map((v) => TestValue.fromJson(v as Map<String, dynamic>))
          .toList() ?? [],
      attachmentUrls: List<String>.from(json['attachmentUrls'] as List? ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isAnalyzed: json['isAnalyzed'] as bool? ?? false,
      analysis: json['analysis'] == null
          ? null
          : TestResultAnalysis.fromJson(json['analysis'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'testName': testName,
    'description': description,
    'values': values.map((v) => v.toJson()).toList(),
    'attachmentUrls': attachmentUrls,
    'createdAt': createdAt.toIso8601String(),
    'isAnalyzed': isAnalyzed,
    'analysis': analysis?.toJson(),
  };

  TestEntry copyWith({
    String? id,
    String? userId,
    String? testName,
    String? description,
    List<TestValue>? values,
    List<String>? attachmentUrls,
    DateTime? createdAt,
    bool? isAnalyzed,
    TestResultAnalysis? analysis,
  }) {
    return TestEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      testName: testName ?? this.testName,
      description: description ?? this.description,
      values: values ?? this.values,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      createdAt: createdAt ?? this.createdAt,
      isAnalyzed: isAnalyzed ?? this.isAnalyzed,
      analysis: analysis ?? this.analysis,
    );
  }
}
