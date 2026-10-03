import 'package:flutter/material.dart';

class TestResultAnalysis {
  final String id;
  final String testEntryId;
  final String summary;
  final String interpretation;
  final List<String> insights;
  final List<String> recommendations;
  final String riskLevel; // 'low', 'normal', 'moderate', 'high'
  final DateTime createdAt;

  TestResultAnalysis({
    required this.id,
    required this.testEntryId,
    required this.summary,
    required this.interpretation,
    required this.insights,
    required this.recommendations,
    required this.riskLevel,
    required this.createdAt,
  });

  factory TestResultAnalysis.fromJson(Map<String, dynamic> json) {
    return TestResultAnalysis(
      id: json['id'] as String,
      testEntryId: json['testEntryId'] as String,
      summary: json['summary'] as String,
      interpretation: json['interpretation'] as String,
      insights: List<String>.from(json['insights'] as List? ?? []),
      recommendations: List<String>.from(json['recommendations'] as List? ?? []),
      riskLevel: json['riskLevel'] as String? ?? 'normal',
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
    'createdAt': createdAt.toIso8601String(),
  };

  TestResultAnalysis copyWith({
    String? id,
    String? testEntryId,
    String? summary,
    String? interpretation,
    List<String>? insights,
    List<String>? recommendations,
    String? riskLevel,
    DateTime? createdAt,
  }) {
    return TestResultAnalysis(
      id: id ?? this.id,
      testEntryId: testEntryId ?? this.testEntryId,
      summary: summary ?? this.summary,
      interpretation: interpretation ?? this.interpretation,
      insights: insights ?? this.insights,
      recommendations: recommendations ?? this.recommendations,
      riskLevel: riskLevel ?? this.riskLevel,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Color getRiskColor() {
    switch (riskLevel) {
      case 'low':
        return const Color(0xFF16A34A); // green
      case 'normal':
        return const Color(0xFF0EA5E9); // blue
      case 'moderate':
        return const Color(0xFFEA580C); // orange
      case 'high':
        return const Color(0xFFDC2626); // red
      default:
        return const Color(0xFF6B7280); // gray
    }
  }
}
