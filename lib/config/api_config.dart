class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';

  static const String tasks = '/tasks';

  static String taskById(String id) => '/tasks/$id';
  static String toggleTask(String id) => '/tasks/$id/toggle';
}
