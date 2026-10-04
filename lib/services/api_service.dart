import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../models/test_entry.dart';
import '../models/test_result.dart';

class AnalysisFile {
  final String name;
  final Uint8List bytes;

  AnalysisFile(this.name, this.bytes);
}

class TypedValue {
  final String name;
  final String value;
  final String unit;

  TypedValue({required this.name, required this.value, required this.unit});

  Map<String, String> toJson() => {'name': name, 'value': value, 'unit': unit};
}

class AnalysisResult {
  final TestResultAnalysis analysis;
  final List<TestValue> values;

  AnalysisResult(this.analysis, this.values);
}

class ApiService {
  static final ApiService _instance = ApiService._internal();

  late Dio _dio;

  // The SmartLAB analysis server in /server. Change when it is deployed.
  static const String _baseUrl = 'http://localhost:3000';

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
  }

  // Sends report files and/or typed-in values to the server, which has the AI
  // read and explain them.
  Future<AnalysisResult> analyze({
    required String testEntryId,
    required String testName,
    required String description,
    required List<AnalysisFile> files,
    required List<TypedValue> typedValues,
  }) async {
    final formData = FormData.fromMap({
      'testEntryId': testEntryId,
      'testName': testName,
      'description': description,
      'values': jsonEncode(typedValues.map((v) => v.toJson()).toList()),
      'files': [
        for (final file in files)
          MultipartFile.fromBytes(
            file.bytes,
            filename: file.name,
            contentType: DioMediaType.parse(_mimeTypeFor(file.name)),
          ),
      ],
    });

    try {
      final response = await _dio.post(
        '/api/analysis/analyze-files',
        data: formData,
        // Reading a report takes the model well over the default 30s.
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(minutes: 2),
          receiveTimeout: const Duration(minutes: 4),
        ),
      );

      final data = response.data as Map<String, dynamic>;
      final values = (data['values'] as List? ?? [])
          .asMap()
          .entries
          .map((e) => TestValue.fromJson({
                ...(e.value as Map<String, dynamic>),
                'id': '${testEntryId}_${e.key}',
              }))
          .toList();
      return AnalysisResult(TestResultAnalysis.fromJson(data), values);
    } on DioException catch (e) {
      final body = e.response?.data;
      if (body is Map && body['error'] is String) {
        throw Exception(body['error']);
      }
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Cannot reach the analysis server. Is it running?');
      }
      throw Exception('Analysis failed: ${e.message}');
    }
  }

  static String _mimeTypeFor(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    return 'image/jpeg';
  }
}
