import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../models/test_entry.dart';
import '../models/test_result.dart';

class AnalysisFile {
  final String name;
  final Uint8List bytes;

  AnalysisFile(this.name, this.bytes);
}

class FileAnalysisResult {
  final TestResultAnalysis analysis;
  final List<TestValue> values;

  FileAnalysisResult(this.analysis, this.values);
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
        contentType: 'application/json',
      ),
    );

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token if available
        // options.headers['Authorization'] = 'Bearer $token';
        return handler.next(options);
      },
      onError: (error, handler) {
        // Handle errors
        return handler.next(error);
      },
    ));
  }

  // Sends lab report PDFs/images to the server, which has Claude read and explain them.
  Future<FileAnalysisResult> analyzeFiles({
    required String testEntryId,
    required String testName,
    required List<AnalysisFile> files,
  }) async {
    final formData = FormData.fromMap({
      'testEntryId': testEntryId,
      'testName': testName,
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
      return FileAnalysisResult(TestResultAnalysis.fromJson(data), values);
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

  // Analysis endpoint
  Future<TestResultAnalysis> analyzeTest({
    required String testName,
    required List<TestValue> values,
  }) async {
    try {
      final response = await _dio.post(
        '/api/analysis/analyze',
        data: {
          'testName': testName,
          'values': values.map((v) => {
            'name': v.name,
            'value': v.value,
            'unit': v.unit,
          }).toList(),
        },
      );

      final data = response.data as Map<String, dynamic>;
      return TestResultAnalysis.fromJson(data);
    } catch (e) {
      throw Exception('Failed to analyze test: $e');
    }
  }

  // Image analysis endpoint
  Future<TestResultAnalysis> analyzeImage({
    required String imageUrl,
    required String testName,
  }) async {
    try {
      final response = await _dio.post(
        '/api/analysis/image-analysis',
        data: {
          'imageUrl': imageUrl,
          'testName': testName,
        },
      );

      final data = response.data as Map<String, dynamic>;
      return TestResultAnalysis.fromJson(data);
    } catch (e) {
      throw Exception('Failed to analyze image: $e');
    }
  }

  // Dietary recommendations
  Future<List<String>> getDietaryRecommendations({
    required List<TestValue> testValues,
  }) async {
    try {
      final response = await _dio.post(
        '/api/recommendations/dietary',
        data: {
          'values': testValues.map((v) => {
            'name': v.name,
            'value': v.value,
            'unit': v.unit,
          }).toList(),
        },
      );

      final data = response.data as Map<String, dynamic>;
      return List<String>.from(data['recommendations'] as List? ?? []);
    } catch (e) {
      throw Exception('Failed to get dietary recommendations: $e');
    }
  }

  // Health insights
  Future<Map<String, dynamic>> getHealthInsights({
    required String userId,
  }) async {
    try {
      final response = await _dio.get(
        '/api/insights/$userId',
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to get health insights: $e');
    }
  }

  // Set authorization token
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Clear authorization token
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
}
