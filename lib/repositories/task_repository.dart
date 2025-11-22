import '../models/task_model.dart';
import '../services/task_service.dart';

class TaskRepository {
  Future<Map<String, dynamic>> getTasks({
    int page = 1,
    int limit = 10,
    String? status,
    String? search,
  }) async {
    try {
      return await TaskService.getTasks(
        page: page,
        limit: limit,
        status: status,
        search: search,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<TaskModel> getTaskById(String id) async {
    try {
      return await TaskService.getTaskById(id);
    } catch (e) {
      rethrow;
    }
  }

  Future<TaskModel> createTask({
    required String title,
    String? description,
  }) async {
    try {
      return await TaskService.createTask(
        title: title,
        description: description,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<TaskModel> updateTask({
    required String id,
    String? title,
    String? description,
    String? status,
  }) async {
    try {
      return await TaskService.updateTask(
        id: id,
        title: title,
        description: description,
        status: status,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await TaskService.deleteTask(id);
    } catch (e) {
      rethrow;
    }
  }

  Future<TaskModel> toggleTask(String id) async {
    try {
      return await TaskService.toggleTask(id);
    } catch (e) {
      rethrow;
    }
  }
}

