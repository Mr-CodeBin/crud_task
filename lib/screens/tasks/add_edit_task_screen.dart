import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../models/task_model.dart';
import '../../widgets/error_chip.dart';
import '../../widgets/success_snackbar.dart';
import '../../widgets/error_dialog.dart';

class AddEditTaskScreen extends StatefulWidget {
  final TaskModel? task;

  const AddEditTaskScreen({super.key, this.task});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _selectedCategory;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _selectedPriority = 'Medium';
  bool _isLoading = false;
  String? _errorMessage;
  final List<String> _categories = ['Work', 'Personal', 'Shopping', 'Meeting', 'Other'];
  final List<String> _priorities = ['Low', 'Medium', 'High'];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _fadeController.forward();

    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description ?? '';
      // Map status to priority (simplified)
      if (widget.task!.status == 'completed') {
        _selectedPriority = 'High';
      } else if (widget.task!.status == 'in_progress') {
        _selectedPriority = 'Medium';
      } else {
        _selectedPriority = 'Low';
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogBackgroundColor: Theme.of(context).cardColor,
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogBackgroundColor: Theme.of(context).cardColor,
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    bool success;

    if (widget.task == null) {
      // Create new task
      success = await taskProvider.createTask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );
    } else {
      // Update existing task
      // Map priority back to status (simplified)
      String status = 'pending';
      if (_selectedPriority == 'High') {
        status = 'completed';
      } else if (_selectedPriority == 'Medium') {
        status = 'in_progress';
      }
      
      success = await taskProvider.updateTask(
        id: widget.task!.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        status: status,
      );
    }

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      SuccessSnackbar.show(
        context,
        message: widget.task == null
            ? 'Task created successfully'
            : 'Task updated successfully',
      );
      Navigator.pop(context, true);
    } else {
      String errorMsg = taskProvider.error ?? 'Failed to save task';
      if (errorMsg.contains('Connection refused') || 
          errorMsg.contains('Failed host lookup')) {
        errorMsg = 'Cannot connect to server. Please check your connection.';
      } else if (errorMsg.contains('401') || errorMsg.contains('Unauthorized')) {
        errorMsg = 'Session expired. Please login again.';
      } else if (errorMsg.contains('400') || errorMsg.contains('Bad Request')) {
        errorMsg = 'Invalid input. Please check your task details.';
      }
      setState(() => _errorMessage = errorMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'New Task' : 'Edit Task'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTaskTitle(theme),
                const SizedBox(height: 24),
                _buildTaskDescription(theme),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  ErrorChip(
                    message: _errorMessage!,
                    onRetry: () {
                      setState(() => _errorMessage = null);
                      _saveTask();
                    },
                  ),
                ],
                const SizedBox(height: 24),
                _buildCategorySection(theme),
                const SizedBox(height: 24),
                _buildDateTimeSection(theme),
                const SizedBox(height: 24),
                _buildPrioritySection(theme),
                const SizedBox(height: 32),
                _buildActionButtons(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskTitle(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Task Title', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: 'Enter task title',
            prefixIcon: Icon(Icons.title),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a task title';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTaskDescription(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Description', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Enter task description',
            prefixIcon: Padding(
              padding: EdgeInsets.only(bottom: 60),
              child: Icon(Icons.description),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((category) {
            final isSelected = _selectedCategory == category;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedCategory = selected ? category : null);
                },
                backgroundColor: theme.cardColor,
                selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                checkmarkColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateTimeSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Due Date & Time', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DateTimeCard(
                icon: Icons.calendar_today,
                label: _selectedDate != null
                    ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                    : 'Select Date',
                onTap: _selectDate,
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DateTimeCard(
                icon: Icons.access_time,
                label: _selectedTime != null
                    ? _selectedTime!.format(context)
                    : 'Select Time',
                onTap: _selectTime,
                theme: theme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrioritySection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Priority', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: _priorities.map((priority) {
            final isSelected = _selectedPriority == priority;
            final color = priority == 'High'
                ? Colors.red
                : priority == 'Medium'
                    ? Colors.orange
                    : Colors.green;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: priority != _priorities.last ? 8 : 0,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Material(
                    color: isSelected ? color.withOpacity(0.2) : theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => setState(() => _selectedPriority = priority),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? color : theme.colorScheme.onSurface.withOpacity(0.1),
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.flag,
                              color: isSelected ? color : theme.textTheme.bodyMedium?.color,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              priority,
                              style: TextStyle(
                                color: isSelected ? color : theme.textTheme.bodyMedium?.color,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        if (widget.task != null)
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                // Show delete confirmation dialog
                final deleteConfirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('Delete Task'),
                        ),
                      ],
                    ),
                    content: const Text('Are you sure you want to delete this task? This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (deleteConfirm == true) {
                  final taskProvider = Provider.of<TaskProvider>(context, listen: false);
                  final success = await taskProvider.deleteTask(widget.task!.id);
                  if (success && mounted) {
                    SuccessSnackbar.show(context, message: 'Task deleted successfully');
                    Navigator.pop(context, true);
                  } else if (mounted && taskProvider.error != null) {
                    ErrorDialog.show(
                      context,
                      title: 'Delete Failed',
                      message: taskProvider.error!,
                    );
                  }
                }
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: theme.colorScheme.error),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
            ),
          ),
        if (widget.task != null) const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveTask,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(widget.task == null ? 'Create Task' : 'Update Task'),
          ),
        ),
      ],
    );
  }
}

class _DateTimeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ThemeData theme;

  const _DateTimeCard({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
