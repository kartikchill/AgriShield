import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Central API service that maps every feature to a backend endpoint.
/// Base URL points to local FastAPI server (10.0.2.2 = Android emulator loopback, localhost = Web)
class ApiService {
  static String currentLanguageCode = 'en';

  static Future<void> saveLanguage(String code) async {
    currentLanguageCode = code;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/language.txt');
      await file.writeAsString(code);
    } catch (_) {}
  }

  static Future<void> loadLanguage() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/language.txt');
      if (await file.exists()) {
        currentLanguageCode = await file.readAsString();
      }
    } catch (_) {}
  }

  static String _activeBaseUrl = '';
  static String _activeAdminBaseUrl = '';

  static List<String> get _candidateHosts {
    if (kIsWeb) return ['http://localhost:8000', 'http://127.0.0.1:8000'];
    return [
      'http://127.0.0.1:8000',
      'http://10.0.2.2:8000',
      'http://192.168.29.101:8000',
      'http://localhost:8000',
    ];
  }

  static String get baseUrl {
    if (_activeBaseUrl.isNotEmpty) return _activeBaseUrl;
    if (kIsWeb) return 'http://localhost:8000';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://127.0.0.1:8000';
  }

  static String get adminBaseUrl {
    if (_activeAdminBaseUrl.isNotEmpty) return _activeAdminBaseUrl;
    if (kIsWeb) return 'http://localhost:8002';
    return 'http://127.0.0.1:8002';
  }

  static const Duration _timeout = Duration(seconds: 30);

  static final ApiService instance = ApiService._internal();
  ApiService._internal();

  // Generic GET helper
  Future<Map<String, dynamic>?> get(String path, {String? customBaseUrl}) async {
    final base = customBaseUrl ?? baseUrl;
    try {
      final response = await http.get(
        Uri.parse('$base$path'),
        headers: {'Content-Type': 'application/json', 'Accept-Language': ApiService.currentLanguageCode},
      ).timeout(_timeout);
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      if (kDebugMode) print('[ApiService.get] Error on $base$path: $e');
    }
    return null;
  }

  // ──────────────────────────────────────────────────────────────────────
  //  CONNECTIVITY CHECK (Probes working hosts dynamically)
  // ──────────────────────────────────────────────────────────────────────

  Future<bool> isOnline() async {
    // 1. Check current active URL
    if (_activeBaseUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse('$_activeBaseUrl/')).timeout(const Duration(seconds: 3));
        if (response.statusCode < 500) return true;
      } catch (_) {
        _activeBaseUrl = '';
        _activeAdminBaseUrl = '';
      }
    }

    // 2. Probe candidate hosts in order
    for (final host in _candidateHosts) {
      try {
        final response = await http.get(Uri.parse('$host/')).timeout(const Duration(seconds: 3));
        if (response.statusCode < 500) {
          _activeBaseUrl = host;
          _activeAdminBaseUrl = host.replaceAll('8000', '8002');
          if (kDebugMode) print('[ApiService] Resolved active backend host: $_activeBaseUrl');
          return true;
        }
      } catch (_) {}
    }

    return false;
  }

  // ──────────────────────────────────────────────────────────────────────
  //  MODEL A – DISEASE RISK ASSESSMENT
  //  POST /api/assess-risk
  // ──────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> assessRisk({
    required String cropType,
    required String cropVariety,
    required String growthStage,
    required String soilType,
    required double latitude,
    required double longitude,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/assess-risk'),
      headers: {'Content-Type': 'application/json', 'Accept-Language': ApiService.currentLanguageCode},
      body: jsonEncode({
        'crop_type': cropType,
        'crop_variety': cropVariety,
        'growth_stage': growthStage,
        'soil_type': soilType,
        'latitude': latitude,
        'longitude': longitude,
      }),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException('Risk assessment failed: ${response.statusCode}', response.body);
  }

  // ──────────────────────────────────────────────────────────────────────
  //  MODEL B VISION – IMAGE CLASSIFICATION
  //  POST /api/v1/vision/analyze-image (multipart form-data)
  //  Returns: disease_class, display_name, confidence, top3, requires_expert_review
  // ──────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> classifyImage({
    required File imageFile,
    String fieldId = 'FIELD-001',
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/v1/vision/analyze-image'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final streamedResponse = await request.send().timeout(_timeout);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException('Image classification failed: ${response.statusCode}', response.body);
  }

  // ──────────────────────────────────────────────────────────────────────
  //  PEST SURVEILLANCE – LOG TRAP DATA
  //  POST /api/v1/pest-surveillance/log
  // ──────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> logPestTrap({
    required String fieldId,
    required String cropName,
    required String pestName,
    required String metricType,
    required double observedValue,
    double? latitude,
    double? longitude,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/pest-surveillance/log'),
      headers: {'Content-Type': 'application/json', 'Accept-Language': ApiService.currentLanguageCode},
      body: jsonEncode({
        'field_id': fieldId,
        'farmer_id': 'FARMER-001',
        'crop_name': cropName,
        'pest_name': pestName,
        'metric_type': metricType,
        'observed_value': observedValue,
        'latitude': ?latitude,
        'longitude': ?longitude,
      }),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException('Pest log failed: ${response.statusCode}', response.body);
  }

  // ──────────────────────────────────────────────────────────────────────
  //  PEST SURVEILLANCE – GET HISTORY
  //  GET /api/v1/pest-surveillance/history/{field_id}
  // ──────────────────────────────────────────────────────────────────────

  Future<List<dynamic>> getPestHistory(String fieldId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/pest-surveillance/history/$fieldId'),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw ApiException('History fetch failed: ${response.statusCode}', response.body);
  }

  // ──────────────────────────────────────────────────────────────────────
  //  PEST SURVEILLANCE – GET ETL THRESHOLDS
  //  GET /api/v1/pest-surveillance/thresholds
  // ──────────────────────────────────────────────────────────────────────

  Future<List<dynamic>> getEtlThresholds() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/pest-surveillance/thresholds'),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw ApiException('Thresholds fetch failed: ${response.statusCode}', response.body);
  }

  // ──────────────────────────────────────────────────────────────────────
  //  EXPERT REFERRAL – CREATE TICKET
  //  POST /api/v1/referral/create-ticket
  // ──────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createReferralTicket({
    required String farmerName,
    required String phoneNumber,
    required String fieldId,
    required String cropName,
    required String symptoms,
    required String aiPrediction,
    required double aiConfidence,
    required double latitude,
    required double longitude,
    String? imageUrl,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/referral/create-ticket'),
      headers: {'Content-Type': 'application/json', 'Accept-Language': ApiService.currentLanguageCode},
      body: jsonEncode({
        'farmer_name': farmerName,
        'phone_number': phoneNumber,
        'field_id': fieldId,
        'crop_name': cropName,
        'reported_symptoms': symptoms,
        'ai_prediction': aiPrediction,
        'ai_confidence': aiConfidence,
        'latitude': latitude,
        'longitude': longitude,
        'image_url': ?imageUrl,
      }),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException('Ticket creation failed: ${response.statusCode}', response.body);
  }

  // ──────────────────────────────────────────────────────────────────────
  //  EXPERT REFERRAL – GET TICKET STATUS
  //  GET /api/v1/referral/ticket-status/{ticket_code}
  // ──────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getTicketStatus(String ticketCode) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/referral/ticket-status/$ticketCode'),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException('Ticket status failed: ${response.statusCode}', response.body);
  }

  // ──────────────────────────────────────────────────────────────────────
  //  GEOSPATIAL HOTSPOTS – DISTRICT SUMMARY
  //  GET /api/v1/hotspots/district-summary
  // ──────────────────────────────────────────────────────────────────────

  Future<List<dynamic>> getDistrictSummary() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/hotspots/district-summary'),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw ApiException('Hotspot fetch failed: ${response.statusCode}', response.body);
  }

  // ──────────────────────────────────────────────────────────────────────
  //  ACTIVE LEARNING – SUBMIT FEEDBACK
  //  POST /api/v1/learning/submit-feedback
  // ──────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> submitFeedback({
    required String originalTicketId,
    required String farmerId,
    required String treatmentApplied,
    required String treatmentEfficacy, // SUCCESS, PARTIAL, FAILED
    required String currentStatus,     // RESOLVED, ESCALATED
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/learning/submit-feedback'),
      headers: {'Content-Type': 'application/json', 'Accept-Language': ApiService.currentLanguageCode},
      body: jsonEncode({
        'original_ticket_id': originalTicketId,
        'farmer_id': farmerId,
        'treatment_applied': treatmentApplied,
        'treatment_efficacy': treatmentEfficacy,
        'current_status': currentStatus,
      }),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException('Feedback submit failed: ${response.statusCode}', response.body);
  }

  // ──────────────────────────────────────────────────────────────────────
  //  LEGACY – Predict Risk (original main.py)
  //  POST /predict-risk (port 8000)
  // ──────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> predictRiskLegacy({
    required int fieldId,
    required double temperature,
    required double humidity,
    required double rainfall,
    required String cropStage,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/predict-risk'),
      headers: {'Content-Type': 'application/json', 'Accept-Language': ApiService.currentLanguageCode},
      body: jsonEncode({
        'field_id': fieldId,
        'temperature': temperature,
        'humidity': humidity,
        'rainfall': rainfall,
        'crop_stage': cropStage,
      }),
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException('Legacy risk failed: ${response.statusCode}', response.body);
  }

  // ──────────────────────────────────────────────────────────────────────
  //  INTEGRATION – SHC (Soil Health Card)
  //  GET /api/v1/integration/shc?lat={lat}&lng={lng}
  // ──────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getSoilHealth(double lat, double lng) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/integration/shc?lat=$lat&lng=$lng'),
      headers: {'Accept-Language': ApiService.currentLanguageCode},
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 404) {
      return null;
    }
    throw ApiException('Soil Health fetch failed: ${response.statusCode}', response.body);
  }

}

/// Structured exception for API errors
class ApiException implements Exception {
  final String message;
  final String? body;
  ApiException(this.message, [this.body]);

  @override
  String toString() => 'ApiException: $message\n$body';
}
