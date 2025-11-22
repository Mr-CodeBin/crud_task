import 'dart:convert';
import '../config/api_config.dart';
import '../models/auth_response_model.dart';
import 'api_service.dart';

class AuthService {
  static Future<AuthResponseModel> register({
    required String email,
    required String password,
  }) async {
    final response = await ApiService.post(
      ApiConfig.register,
      body: {
        'email': email,
        'password': password,
      },
      requiresAuth: false,
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return AuthResponseModel.fromJson(data['data']);
      }
    }

    throw Exception(_getErrorMessage(response));
  }

  static Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiService.post(
        ApiConfig.login,
        body: {
          'email': email,
          'password': password,
        },
        requiresAuth: false,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return AuthResponseModel.fromJson(data['data']);
        }
      }

      throw Exception(_getErrorMessage(response));
    } catch (e) {
      if (e.toString().contains('Connection refused') || 
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('SocketException')) {
        throw Exception('Cannot connect to server. Please check if the backend is running.');
      }
      rethrow;
    }
  }

  static Future<void> logout() async {
    try {
      await ApiService.post(ApiConfig.logout);
    } catch (e) {
    }
  }

  static String _getErrorMessage(response) {
    try {
      final data = jsonDecode(response.body);
      return data['message'] ?? 'An error occurred';
    } catch (e) {
      return 'An error occurred';
    }
  }
}

