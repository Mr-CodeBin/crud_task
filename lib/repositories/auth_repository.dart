import '../services/auth_service.dart';
import '../services/token_service.dart';
import '../models/auth_response_model.dart';

class AuthRepository {
  Future<AuthResponseModel> register({
    required String email,
    required String password,
  }) async {
    try {
      final response = await AuthService.register(
        email: email,
        password: password,
      );

      await TokenService.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
      await TokenService.saveUserEmail(response.user.email);
      
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await AuthService.login(
        email: email,
        password: password,
      );

      await TokenService.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
      await TokenService.saveUserEmail(response.user.email);
      
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await AuthService.logout();
    } finally {
      await TokenService.clearTokens();
    }
  }

  Future<bool> isAuthenticated() async {
    return await TokenService.isAuthenticated();
  }
}

