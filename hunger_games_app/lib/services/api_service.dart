import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/tribute.dart';
import '../models/advance_response.dart';
import '../models/status_response.dart';

// Backend address — change if needed.
// Physical device / desktop: http://127.0.0.1:8000
// Android emulator: http://10.0.2.2:8000
const String kBaseUrl = 'http://127.0.0.1:8000';

class TributeInput {
  final String name;
  final String gender;
  final int district;

  TributeInput({
    required this.name,
    required this.gender,
    required this.district,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'gender': gender,
        'district': district,
      };
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  static final ApiService instance = ApiService._internal();
  ApiService._internal();

  final _client = http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  void _checkStatus(http.Response response) {
    if (response.statusCode != 200) {
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException(
          body['detail']?.toString() ?? 'Server error (${response.statusCode})',
          statusCode: response.statusCode,
        );
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException(
          'Server error (${response.statusCode})',
          statusCode: response.statusCode,
        );
      }
    }
  }

  Future<void> startSimulation({
    List<TributeInput>? tributes,
    String language = 'English',
    bool useDefaultTributes = false,
  }) async {
    final body = <String, dynamic>{
      'language': language,
      'use_default_tributes': useDefaultTributes,
    };
    if (!useDefaultTributes && tributes != null) {
      body['tributes'] = tributes.map((t) => t.toJson()).toList();
    }

    final response = await _client.post(
      Uri.parse('$kBaseUrl/simulation/start'),
      headers: _headers,
      body: jsonEncode(body),
    );
    _checkStatus(response);
  }

  Future<AdvanceResponseModel> advanceSimulation() async {
    final response = await _client.post(
      Uri.parse('$kBaseUrl/simulation/advance'),
      headers: _headers,
    );
    _checkStatus(response);
    return AdvanceResponseModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<StatusResponseModel> getStatus() async {
    final response = await _client.get(
      Uri.parse('$kBaseUrl/simulation/status'),
      headers: _headers,
    );
    _checkStatus(response);
    return StatusResponseModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<TributeModel?> getWinner() async {
    final response = await _client.get(
      Uri.parse('$kBaseUrl/simulation/winner'),
      headers: _headers,
    );
    _checkStatus(response);
    final body = jsonDecode(response.body);
    if (body == null) return null;
    return TributeModel.fromJson(body as Map<String, dynamic>);
  }

  Future<void> resetSimulation() async {
    final response = await _client.post(
      Uri.parse('$kBaseUrl/simulation/reset'),
      headers: _headers,
    );
    _checkStatus(response);
  }

  void dispose() {
    _client.close();
  }
}
