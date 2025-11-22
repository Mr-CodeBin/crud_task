import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../repositories/task_repository.dart';

class TaskProvider with ChangeNotifier {
  final TaskRepository _taskRepository = TaskRepository();

  List<TaskModel> _tasks = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;
  String? _currentStatus;
  String? _currentSearch;
  bool _hasLoadedTasks = false;

  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMore => _hasMore;

  Future<void> fetchTasks({
    bool refresh = false,
    String? status,
    String? search,
  }) async {
    final hadTasksBefore = _tasks.isNotEmpty;

    if (refresh) {
      _currentPage = 1;
      if (!_hasLoadedTasks) {
        _tasks = [];
      }
      _hasMore = true;
    }

    _isLoading = true;
    _error = null;
    _currentStatus = status;
    _currentSearch = search;
    notifyListeners();

    try {
      final result = await _taskRepository.getTasks(
        page: _currentPage,
        limit: 10,
        status: status,
        search: search,
      );

      final newTasks = result['tasks'] as List<TaskModel>;
      final pagination = result['pagination'] as Map<String, dynamic>;

      if (refresh) {
        _tasks = newTasks;
      } else {
        _tasks.addAll(newTasks);
      }

      _currentPage = pagination['page'] as int;
      _totalPages = pagination['totalPages'] as int;
      _hasMore = _currentPage < _totalPages;

      if (newTasks.isNotEmpty) {
        _hasLoadedTasks = true;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      _error = errorMessage;
      _isLoading = false;

      if (hadTasksBefore && (search != null || status != null)) {
      } else if (refresh && !_hasLoadedTasks) {
        _tasks = [];
      }

      notifyListeners();
    }
  }

  Future<void> loadMoreTasks() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    _currentPage++;
    notifyListeners();

    try {
      final result = await _taskRepository.getTasks(
        page: _currentPage,
        limit: 10,
        status: _currentStatus,
        search: _currentSearch,
      );

      final newTasks = result['tasks'] as List<TaskModel>;
      final pagination = result['pagination'] as Map<String, dynamic>;

      _tasks.addAll(newTasks);
      _currentPage = pagination['page'] as int;
      _totalPages = pagination['totalPages'] as int;
      _hasMore = _currentPage < _totalPages;

      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _currentPage--; // Revert page increment on error
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<bool> createTask({required String title, String? description}) async {
    try {
      final newTask = await _taskRepository.createTask(
        title: title,
        description: description,
      );
      _tasks.insert(0, newTask);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTask({
    required String id,
    String? title,
    String? description,
    String? status,
  }) async {
    try {
      final updatedTask = await _taskRepository.updateTask(
        id: id,
        title: title,
        description: description,
        status: status,
      );
      final index = _tasks.indexWhere((task) => task.id == id);
      if (index != -1) {
        _tasks[index] = updatedTask;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTask(String id) async {
    try {
      await _taskRepository.deleteTask(id);
      _tasks.removeWhere((task) => task.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleTask(String id) async {
    try {
      final updatedTask = await _taskRepository.toggleTask(id);
      final index = _tasks.indexWhere((task) => task.id == id);
      if (index != -1) {
        _tasks[index] = updatedTask;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
