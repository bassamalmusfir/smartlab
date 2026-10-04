import 'package:flutter/material.dart';

class Food {
  final String name;
  final String benefit;

  Food({required this.name, required this.benefit});

  factory Food.fromJson(Map<String, dynamic> json) =>
      Food(name: json['name'] as String? ?? '', benefit: json['benefit'] as String? ?? '');

  Map<String, dynamic> toJson() => {'name': name, 'benefit': benefit};
}

class DietaryCategory {
  final String title;
  // One of: iron, protein, omega3, fiber, hydration, calcium, vitamins, limit, other.
  final String kind;
  final String reason;
  final List<Food> foods;

  DietaryCategory({required this.title, required this.kind, required this.reason, required this.foods});

  factory DietaryCategory.fromJson(Map<String, dynamic> json) => DietaryCategory(
        title: json['title'] as String? ?? '',
        kind: json['kind'] as String? ?? 'other',
        reason: json['reason'] as String? ?? '',
        foods: (json['foods'] as List? ?? [])
            .map((f) => Food.fromJson(f as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'kind': kind,
        'reason': reason,
        'foods': foods.map((f) => f.toJson()).toList(),
      };
}

class DietaryPlan {
  final List<DietaryCategory> categories;
  final String proTip;

  DietaryPlan({required this.categories, required this.proTip});

  factory DietaryPlan.fromJson(Map<String, dynamic> json) => DietaryPlan(
        categories: (json['categories'] as List? ?? [])
            .map((c) => DietaryCategory.fromJson(c as Map<String, dynamic>))
            .toList(),
        proTip: json['proTip'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'categories': categories.map((c) => c.toJson()).toList(),
        'proTip': proTip,
      };
}

class TestResultAnalysis {
  final String id;
  final String testEntryId;
  final String summary;
  final String interpretation;
  final List<String> insights;
  final List<String> recommendations;
  final String riskLevel; // 'low', 'normal', 'moderate', 'high'
  // One of: blood, hormone, organ, urine, imaging, other.
  final String category;
  final DietaryPlan? dietary;
  final DateTime createdAt;

  TestResultAnalysis({
    required this.id,
    required this.testEntryId,
    required this.summary,
    required this.interpretation,
    required this.insights,
    required this.recommendations,
    required this.riskLevel,
    this.category = 'other',
    this.dietary,
    required this.createdAt,
  });

  bool get needsAttention => riskLevel == 'moderate' || riskLevel == 'high';

  factory TestResultAnalysis.fromJson(Map<String, dynamic> json) {
    return TestResultAnalysis(
      id: json['id'] as String,
      testEntryId: json['testEntryId'] as String,
      summary: json['summary'] as String,
      interpretation: json['interpretation'] as String,
      insights: List<String>.from(json['insights'] as List? ?? []),
      recommendations: List<String>.from(json['recommendations'] as List? ?? []),
      riskLevel: json['riskLevel'] as String? ?? 'normal',
      category: json['category'] as String? ?? 'other',
      dietary: json['dietary'] == null
          ? null
          : DietaryPlan.fromJson(json['dietary'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'testEntryId': testEntryId,
    'summary': summary,
    'interpretation': interpretation,
    'insights': insights,
    'recommendations': recommendations,
    'riskLevel': riskLevel,
    'category': category,
    'dietary': dietary?.toJson(),
    'createdAt': createdAt.toIso8601String(),
  };

  Color getRiskColor() {
    switch (riskLevel) {
      case 'low':
        return const Color(0xFF16A34A);
      case 'normal':
        return const Color(0xFF0EA5E9);
      case 'moderate':
        return const Color(0xFFEA580C);
      case 'high':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
    }
  }
}
