import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../models/task_model.dart';
import '../../widgets/error_chip.dart';
import '../../widgets/success_snackbar.dart';
import '../../theme/app_theme.dart';
import 'add_edit_task_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen>
    with TickerProviderStateMixin {
  final _scrollController = ScrollController();
  String? _selectedStatus;
  final _searchController = TextEditingController();
  bool _isSearchVisible = false;
  late AnimationController _fabController;
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabController.forward();
    _searchController.addListener(() {
      setState(() {}); // Rebuild to show/hide clear button
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(
        context,
        listen: false,
      ).fetchTasks(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      Provider.of<TaskProvider>(context, listen: false).loadMoreTasks();
    }
  }

  Future<void> _handleRefresh() async {
    await Provider.of<TaskProvider>(context, listen: false).fetchTasks(
      refresh: true,
      status: _selectedStatus,
      search: _searchController.text.isEmpty ? null : _searchController.text,
    );
  }

  void _filterByStatus(String? status) {
    setState(() {
      _selectedStatus = status;
    });
    Provider.of<TaskProvider>(context, listen: false).fetchTasks(
      refresh: true,
      status: status,
      search: _searchController.text.isEmpty ? null : _searchController.text,
    );
  }

  void _searchTasks(String query) {
    // Cancel previous timer
    _searchDebounceTimer?.cancel();

    // Debounce search to avoid too many API calls
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        Provider.of<TaskProvider>(context, listen: false).fetchTasks(
          refresh: true,
          status: _selectedStatus,
          search: query.isEmpty ? null : query,
        );
      }
    });
  }

  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  List<TaskModel> get filteredTasks {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final tasks = taskProvider.tasks;

    if (_selectedStatus == null) return tasks;

    switch (_selectedStatus) {
      case 'pending':
        return tasks.where((t) => t.status == 'pending').toList();
      case 'in_progress':
        return tasks.where((t) => t.status == 'in_progress').toList();
      case 'completed':
        return tasks.where((t) => t.status == 'completed').toList();
      default:
        return tasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,

          endDrawer: _buildDrawer(theme),
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildHeader(theme),
                const SizedBox(height: 24),
                _buildMotivationalText(theme),
                if (_isSearchVisible) ...[
                  const SizedBox(height: 16),
                  _buildSearchBar(theme),
                ],
                const SizedBox(height: 40),
                _buildFilterChips(theme, taskProvider),
                const SizedBox(height: 16),
                Expanded(child: _buildTaskList(theme, taskProvider)),
              ],
            ),
          ),
          floatingActionButton: ScaleTransition(
            scale: _fabController,
            child: FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddEditTaskScreen()),
                );
                if (result == true) {
                  _handleRefresh();
                }
              },
              icon: const Icon(Icons.add_task_rounded),
              label: const Text('New Task'),
              elevation: 4,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawer(ThemeData theme) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final userEmail = authProvider.userEmail ?? 'Loading...';
        final displayName = userEmail.split('@').first;
        final capitalizedName =
            displayName.isNotEmpty
                ? displayName[0].toUpperCase() + displayName.substring(1)
                : 'User';
        final isDark = theme.brightness == Brightness.dark;

        return Drawer(
          backgroundColor: theme.scaffoldBackgroundColor,
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? const Color(0xFF1E1E1E)
                            : const Color(0xFF2A2A2A),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor:
                            isDark
                                ? const Color(0xFF4A148C)
                                : const Color(0xFF6A1B9A),
                        child: Icon(
                          Icons.person_rounded,
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              capitalizedName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userEmail,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.dividerColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            themeProvider.isDarkMode
                                ? Icons.light_mode_rounded
                                : Icons.dark_mode_rounded,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: theme.textTheme.bodySmall?.color?.withOpacity(
                            0.4,
                          ),
                          size: 20,
                        ),
                        onTap: () {
                          themeProvider.toggleTheme();
                          Navigator.pop(context);
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    );
                  },
                ),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.red.withOpacity(0.6),
                      size: 20,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _handleLogout();
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final userEmail = authProvider.userEmail ?? '';
        final displayName = userEmail.split('@').first;
        final capitalizedName =
            displayName.isNotEmpty
                ? displayName[0].toUpperCase() + displayName.substring(1)
                : 'Alex';

        final now = DateTime.now();
        final dateFormat =
            '${_getMonthName(now.month)} ${now.day}, ${now.year}';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello $capitalizedName',
                          style: theme.textTheme.displayMedium?.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '🗓️ $dateFormat',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          theme.brightness == Brightness.dark
                              ? const Color(0xFF1E1E1E)
                              : const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color:
                            theme.brightness == Brightness.dark
                                ? Colors.grey.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isSearchVisible = !_isSearchVisible;
                              if (!_isSearchVisible) {
                                _searchController.clear();
                                _searchTasks('');
                              }
                            });
                          },
                          child: Icon(
                            _isSearchVisible
                                ? Icons.close_rounded
                                : Icons.search_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Builder(
                          builder:
                              (context) => GestureDetector(
                                onTap:
                                    () => Scaffold.of(context).openEndDrawer(),
                                child: Icon(
                                  Icons.menu_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 14,
                          backgroundColor:
                              theme.brightness == Brightness.dark
                                  ? const Color(0xFF4A148C) // Dark purple
                                  : const Color(0xFF6A1B9A), // Purple
                          child: Icon(
                            Icons.person_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  Widget _buildMotivationalText(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          FittedBox(
            fit: BoxFit.fitWidth,
            child: Text(
              'Take control of\nyour day',
              textAlign: TextAlign.start,
              style: theme.textTheme.displayMedium?.copyWith(
                fontSize: 40,
                fontWeight: FontWeight.w400,
                letterSpacing: 1.2,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Search tasks by title...',
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withOpacity(0.5),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.white.withOpacity(0.7),
            size: 20,
          ),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      color: Colors.white.withOpacity(0.7),
                      size: 20,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _searchTasks('');
                    },
                    tooltip: 'Clear search',
                  )
                  : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white),
        onChanged: (value) {
          setState(() {});
          _searchTasks(value);
        },
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme, TaskProvider taskProvider) {
    final pendingCount =
        taskProvider.tasks.where((t) => t.status == 'pending').length;
    final inProgressCount =
        taskProvider.tasks.where((t) => t.status == 'in_progress').length;
    final completedCount =
        taskProvider.tasks.where((t) => t.status == 'completed').length;

    final filters = [
      {'label': 'To do', 'status': 'pending', 'count': pendingCount},
      {
        'label': 'In progress',
        'status': 'in_progress',
        'count': inProgressCount,
      },
      {'label': 'Completed', 'status': 'completed', 'count': completedCount},
    ];

    final isDark = theme.brightness == Brightness.dark;
    final baseBackgroundColor =
        isDark ? const Color(0xFF1E1E1E) : const Color(0xFF2A2A2A);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: baseBackgroundColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
        ),
        child: Row(
          children:
              filters.asMap().entries.map((entry) {
                final filter = entry.value;
                final isSelected = _selectedStatus == filter['status'];
                final count = filter['count'] as int;
                final label = filter['label'] as String;

                return Expanded(
                  child: GestureDetector(
                    onTap:
                        () => _filterByStatus(
                          isSelected ? null : filter['status'] as String?,
                        ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? theme.primaryColor
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : Colors.grey.shade400,
                                  letterSpacing: 0.1,
                                  height: 1.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? theme.cardColor
                                        : AppTheme.appBlack,
                                shape: BoxShape.circle,
                              ),
                              child:
                                  taskProvider.isLoading &&
                                          _selectedStatus == filter['status']
                                      ? Center(
                                        child: SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        ),
                                      )
                                      : Center(
                                        child: Text(
                                          count.toString().padLeft(2, '0'),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.grey,
                                            letterSpacing: 0.1,
                                            height: 1.0,
                                          ),
                                        ),
                                      ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildTaskList(ThemeData theme, TaskProvider taskProvider) {
    if (taskProvider.isLoading && taskProvider.tasks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (taskProvider.error != null) {
      final isSessionExpired = taskProvider.error!.toLowerCase().contains(
        'session expired',
      );

      if (isSessionExpired &&
          taskProvider.tasks.isEmpty &&
          !_isSearchVisible &&
          _searchController.text.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _handleLogout();
          }
        });
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Session expired. Redirecting to login...'),
            ],
          ),
        );
      }

      if (taskProvider.tasks.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !isSessionExpired) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(taskProvider.error!),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 3),
              ),
            );
            taskProvider.clearError();
          }
        });
      }

      if (taskProvider.tasks.isEmpty && !isSessionExpired) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 24),
                ErrorChip(
                  message: taskProvider.error!,
                  onRetry: () {
                    taskProvider.clearError();
                    _handleRefresh();
                  },
                  icon: Icons.refresh_rounded,
                ),
              ],
            ),
          ),
        );
      }
    }

    final tasks = filteredTasks;

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt_rounded,
              size: 80,
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text('No tasks found', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Create your first task to get started',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: tasks.length + (taskProvider.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= tasks.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                  strokeWidth: 3,
                ),
              ),
            );
          }

          final task = tasks[index];
          return _TaskCard(
            task: task,
            onToggle: () async {
              final success = await taskProvider.toggleTask(task.id);
              if (!success && mounted && taskProvider.error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(taskProvider.error!),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            onDelete: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Delete Task'),
                      content: const Text(
                        'Are you sure you want to delete this task?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
              );

              if (confirm == true) {
                final success = await taskProvider.deleteTask(task.id);
                if (success && mounted) {
                  SuccessSnackbar.show(
                    context,
                    message: 'Task deleted successfully',
                  );
                } else if (mounted && taskProvider.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(taskProvider.error!),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              }
            },
            onTap: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddEditTaskScreen(task: task),
                ),
              );
              if (result == true) {
                _handleRefresh();
              }
            },
          );
        },
      ),
    );
  }
}

class _TaskCard extends StatefulWidget {
  final TaskModel task;
  final Future<void> Function() onToggle;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _TaskCard({
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onTap,
  });

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCompleted = widget.task.status == 'completed';
    final statusColor = _getStatusColor(widget.task.status);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dismissible(
        key: Key(widget.task.id),
        background: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade400, Colors.red.shade600],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.delete_forever_rounded, color: Colors.white, size: 24),
            ],
          ),
        ),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => widget.onDelete(),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isCompleted
                      ? statusColor.withOpacity(0.2)
                      : theme.dividerColor.withOpacity(0.3),
              width: isCompleted ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    isDark
                        ? Colors.black.withOpacity(0.2)
                        : Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onLongPress: () => _handleLongPress(context),
              onTapDown: (_) => _controller.forward(),
              onTapUp: (_) => _controller.reverse(),
              onTapCancel: () => _controller.reverse(),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: widget.onToggle,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubic,
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient:
                              isCompleted
                                  ? LinearGradient(
                                    colors: [
                                      theme.colorScheme.primary,
                                      theme.colorScheme.secondary,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                  : null,
                          color: isCompleted ? null : Colors.transparent,
                          border: Border.all(
                            color:
                                isCompleted
                                    ? Colors.transparent
                                    : statusColor.withOpacity(0.4),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow:
                              isCompleted
                                  ? [
                                    BoxShadow(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                  : null,
                        ),
                        child:
                            isCompleted
                                ? const Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: Colors.white,
                                )
                                : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.task.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              decoration:
                                  isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                              color:
                                  isCompleted
                                      ? theme.textTheme.bodyMedium?.color
                                          ?.withOpacity(0.5)
                                      : theme.textTheme.titleMedium?.color,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              height: 1.4,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.task.description != null &&
                              widget.task.description!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              widget.task.description!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                decoration:
                                    isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                color:
                                    isCompleted
                                        ? theme.textTheme.bodySmall?.color
                                            ?.withOpacity(0.4)
                                        : theme.textTheme.bodySmall?.color
                                            ?.withOpacity(0.6),
                                fontSize: 13,
                                height: 1.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: statusColor.withOpacity(0.2),
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _getStatusLabel(widget.task.status),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: statusColor,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 12,
                                    color: theme.textTheme.bodySmall?.color
                                        ?.withOpacity(0.5),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDate(widget.task.createdAt),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: theme.textTheme.bodySmall?.color
                                          ?.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.3),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLongPress(BuildContext context) async {
    final theme = Theme.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.edit_rounded,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Text('Edit Task')),
              ],
            ),
            content: Text(
              'Do you want to edit "${widget.task.title}"?',
              style: theme.textTheme.bodyLarge,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Edit'),
              ),
            ],
          ),
    );

    if (confirm == true && context.mounted) {
      widget.onTap();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFF9800);
      case 'in_progress':
        return const Color(0xFF2196F3);
      case 'completed':
        return const Color(0xFF4CAF50);
      default:
        return Colors.grey.shade600;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes} min ago';
      }
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${diff.inDays} days ago';
    }
  }
}
