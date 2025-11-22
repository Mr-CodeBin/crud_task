import 'dart:convert';
import '../config/api_config.dart';
import '../models/task_model.dart';
import 'api_service.dart';

class TaskService {
  static Future<Map<String, dynamic>> getTasks({
    int page = 1,
    int limit = 10,
    String? status,
    String? search,
  }) async {
    String queryParams = '?page=$page&limit=$limit';
    if (status != null && status.isNotEmpty) {
      queryParams += '&status=$status';
    }
    if (search != null && search.isNotEmpty) {
      queryParams += '&search=$search';
    }

    final response = await ApiService.get('${ApiConfig.tasks}$queryParams');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final tasksData = data['data']['tasks'] as List;
        final tasks = tasksData
            .map((task) => TaskModel.fromJson(task as Map<String, dynamic>))
            .toList();

        return {
          'tasks': tasks,
          'pagination': data['data']['pagination'],
        };
      }
    }

    throw Exception(_getErrorMessage(response));
  }

  static Future<TaskModel> getTaskById(String id) async {
    final response = await ApiService.get(ApiConfig.taskById(id));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return TaskModel.fromJson(data['data']);
      }
    }

    throw Exception(_getErrorMessage(response));
  }

  static Future<TaskModel> createTask({
    required String title,
    String? description,
  }) async {
    final response = await ApiService.post(
      ApiConfig.tasks,
      body: {
        'title': title,
        if (description != null) 'description': description,
      },
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return TaskModel.fromJson(data['data']);
      }
    }

    throw Exception(_getErrorMessage(response));
  }

  static Future<TaskModel> updateTask({
    required String id,
    String? title,
    String? description,
    String? status,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (status != null) body['status'] = status;

    final response = await ApiService.patch(
      ApiConfig.taskById(id),
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return TaskModel.fromJson(data['data']);
      }
    }

    throw Exception(_getErrorMessage(response));
  }

  static Future<void> deleteTask(String id) async {
    final response = await ApiService.delete(ApiConfig.taskById(id));

    if (response.statusCode != 200) {
      throw Exception(_getErrorMessage(response));
    }
  }

  static Future<TaskModel> toggleTask(String id) async {
    final response = await ApiService.patch(ApiConfig.toggleTask(id));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return TaskModel.fromJson(data['data']);
      }
    }

    throw Exception(_getErrorMessage(response));
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

