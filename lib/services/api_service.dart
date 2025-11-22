import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/token_service.dart';

class _ApiException implements Exception {
  final String message;
  final int statusCode;

  _ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}

class ApiService {
  static Future<http.Response> _request({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    // Default headers
    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      ...?headers,
    };

    // Add auth token if required
    if (requiresAuth) {
      final token = await TokenService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        requestHeaders['Authorization'] = 'Bearer $token';
      } else {
        throw Exception('No authentication token found. Please login again.');
      }
    }

    http.Response response;

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: requestHeaders);
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PATCH':
          response = await http.patch(
            url,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(url, headers: requestHeaders);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      if (response.statusCode == 401 && requiresAuth) {
        final refreshToken = await TokenService.getRefreshToken();
        if (refreshToken == null || refreshToken.isEmpty) {
          throw Exception('Session expired. Please login again.');
        }

        final refreshed = await _refreshToken();
        if (refreshed) {
          return await _request(
            method: method,
            endpoint: endpoint,
            body: body,
            headers: headers,
            requiresAuth: requiresAuth,
          );
        } else {
          throw Exception('Session expired. Please login again.');
        }
      }

      if (response.statusCode >= 400) {
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['message'] ?? 'An error occurred';
          // Store status code in exception for better error handling
          throw _ApiException(errorMessage, response.statusCode);
        } catch (e) {
          if (e is _ApiException) {
            rethrow;
          }
          // If JSON parsing fails, try to extract message from response body
          final body = response.body;
          if (body.isNotEmpty && body.contains('message')) {
            try {
              final errorMessage =
                  jsonDecode(body)['message'] ?? 'An error occurred';
              throw _ApiException(errorMessage, response.statusCode);
            } catch (_) {
              throw _ApiException(
                'Request failed with status ${response.statusCode}',
                response.statusCode,
              );
            }
          }
          throw _ApiException(
            'Request failed with status ${response.statusCode}',
            response.statusCode,
          );
        }
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  static Future<bool> _refreshToken() async {
    try {
      final refreshToken = await TokenService.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.refresh}');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final newAccessToken = data['data']['accessToken'] as String;
          // Keep the same refresh token (it doesn't change on refresh)
          await TokenService.saveTokens(
            accessToken: newAccessToken,
            refreshToken: refreshToken,
          );
          return true;
        }
      }
      return false;
    } catch (e) {
      log('Token refresh error: $e');
      return false;
    }
  }

  // Public methods
  static Future<http.Response> get(
    String endpoint, {
    bool requiresAuth = true,
  }) {
    return _request(
      method: 'GET',
      endpoint: endpoint,
      requiresAuth: requiresAuth,
    );
  }

  static Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) {
    return _request(
      method: 'POST',
      endpoint: endpoint,
      body: body,
      requiresAuth: requiresAuth,
    );
  }

  static Future<http.Response> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) {
    return _request(
      method: 'PATCH',
      endpoint: endpoint,
      body: body,
      requiresAuth: requiresAuth,
    );
  }

  static Future<http.Response> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) {
    return _request(
      method: 'DELETE',
      endpoint: endpoint,
      requiresAuth: requiresAuth,
    );
  }
}
